-- yt_power.lua
-- Tek dosyada birleşik mpv eklentisi:
--  1) Kalite menüsü (yt-dlp ile canlı format listesi)  [Ctrl+k]
--  2) YouTube "Up Next / Öneriler" menüsü               [Ctrl+u]
--  3) Akıllı otomatik format/altyazı/profil ayarı       (otomatik)
--
--  Notlar:
--   - Dış bağımlılıklar: yt-dlp (kalite menüsü için), wget (upnext için)
--   - mpv 0.34+ önerilir
--   - Güvenli hata yakalama, OSD menü zaman aşımı, URL cache, cookie desteği

local mp = require("mp")
local msg = require("mp.msg")
local utils = require("mp.utils")
local assdraw = require("mp.assdraw")

----------------------------------------------------------------
-- KULLANICI AYARLARI
----------------------------------------------------------------
local OPTS = {
	-- GENEL
	menu_timeout = 10, -- OSD menü zaman aşımı (saniye)
	style_ass_tags = "{\\fnmonospace}", -- Menü fontu/ass stil tagları
	scale_playlist_by_window = false, -- true => mp.set_osd_ass(0,0,...) ile ölçekle

	-- KALİTE MENÜSÜ
	quality_toggle_key = "Ctrl+k",
	quality_up_key = "UP",
	quality_down_key = "DOWN",
	quality_select_key = "ENTER",
	fetch_formats_with_ytdlp = true, -- true => yt-dlp ile gerçek formatlar
		avoid_av1 = true, -- AV1 dışla (av1/av01)
		prefer_vp9 = true, -- VP9'u avc1 öncesi dene
		fps_limit = 60, -- üst FPS sınırı
		quality_limit = 1440, -- üst çözünürlük sınırı (1080/1440/2160 vs.)
		quality_presets_json = [[
	  [
    {"4320p" : "bestvideo[height<=?4320]+bestaudio/best"},
    {"2160p" : "bestvideo[height<=?2160]+bestaudio/best"},
    {"1440p" : "bestvideo[height<=?1440]+bestaudio/best"},
    {"1080p" : "bestvideo[height<=?1080]+bestaudio/best"},
    {"720p"  : "bestvideo[height<=?720]+bestaudio/best"},
    {"480p"  : "bestvideo[height<=?480]+bestaudio/best"},
    {"360p"  : "bestvideo[height<=?360]+bestaudio/best"},
    {"240p"  : "bestvideo[height<=?240]+bestaudio/best"},
    {"144p"  : "bestvideo[height<=?144]+bestaudio/best"}
  ]
  ]],
	-- Menü imleçleri
	cur_sel_act = "▶ - ",
	cur_sel_inact = "● - ",
	cur_unsel_act = "▷ - ",
	cur_unsel_inact = "○ - ",

	-- UP NEXT MENÜSÜ
	upnext_toggle_key = "Ctrl+u",
	upnext_up_key = "UP",
	upnext_down_key = "DOWN",
	upnext_select_key = "ENTER",
	upnext_auto_add = true, -- dosya yüklenince "up next" otomatik append
	youtube_url_fmt = "https://www.youtube.com/watch?v=%s",
	invidious_instance = "https://invidious.xyz",
	restore_window_width = false, -- sonraki videoda pencere genişliğini koru
	check_certificate = true, -- wget için HTTPS sertifika kontrolü
	cookies_file = "", -- boşsa ytdl-raw-options.cookiess'ten dene

	-- AKILLI OTOMATİK
	target_domains = { -- Format/profil hedef domainleri
		["youtu.be"] = true,
		["youtube.com"] = true,
		["www.youtube.com"] = true,
		["m.youtube.com"] = true,
		["twitch.tv"] = true,
		["www.twitch.tv"] = true,
	},
	set_sub_langs = "tr,en", -- yt-dlp sub-langs
	apply_profiles = true, -- içerik tabanlı profil uygula
	profile_youtube = "youtube-content",
	profile_4k = "4k-video",
	profile_live = "live-hls",
}

(require("mp.options")).read_options(OPTS, "yt_power")
local QUALITY_PRESETS = utils.parse_json(OPTS.quality_presets_json) or {}

-- Track the last auto-applied ytdl-format.
-- If the user changes ytdl-format manually (keybind/menu), we stop overriding it.
local last_auto_ytdl_format = nil

----------------------------------------------------------------
-- YARDIMCI FONKSİYONLAR
----------------------------------------------------------------
local function exec(args)
	local ret = utils.subprocess({ args = args })
	return ret.status or -1, ret.stdout or "", ret
end

local function get_opt(prop, native)
	if native then
		return mp.get_property_native(prop)
	end
	return mp.get_property(prop)
end

local function osd_ass_write(lines)
	local ass = assdraw.ass_new()
	ass:pos(5, 5)
	ass:append(OPTS.style_ass_tags)
	for _, ln in ipairs(lines) do
		ass:append(ln .. "\\N")
	end
	local w, h = mp.get_osd_size()
	if OPTS.scale_playlist_by_window then
		w, h = 0, 0
	end
	mp.set_osd_ass(w, h, ass.text)
end

local function hostname_from_url(url)
	if not url then
		return ""
	end
	local host = url:match("^%a+://([^/]+)/") or ""
	return host:match("([%w%.%-]+%w+)$") or host
end

local function is_target_domain(url)
	local h = hostname_from_url((url or ""):lower())
	return OPTS.target_domains[h] == true
end

local function av1_exclusion_tag()
	return OPTS.avoid_av1 and "[vcodec!=av01][vcodec!=av1]" or ""
end

local function build_default_format()
	return ("bestvideo[fps<=?%d]%s+bestaudio/best"):format(OPTS.fps_limit, av1_exclusion_tag())
end

local function build_domain_format()
	local base = ("bestvideo*[height<=?%d][fps<=?%d]"):format(OPTS.quality_limit, OPTS.fps_limit)
	local excl = av1_exclusion_tag()
	if OPTS.prefer_vp9 then
		-- Not:
		-- Eskiden en sonda "best" fallback vardı. Bazı videolarda filtreler (özellikle AV1 dışlama)
		-- eşleşmeyince "best" 4K AV1 seçip yazılımsal decode + A/V desync'e yol açabiliyordu.
		-- Bu yüzden fallback'i çözünürlük/FPS limitleri içinde tutuyoruz.
		return table.concat({
			(base .. "[vcodec*=vp9]" .. excl .. "+bestaudio"),
			(base .. "[vcodec*=avc1]" .. excl .. "+bestaudio"),
			(base .. excl .. "+bestaudio"),
			-- Son çare: codec fark etmeksizin limitler içinde kal.
			(base .. excl .. "+bestaudio/best"),
		}, "/")
	else
		return table.concat({
			(base .. "[vcodec*=avc1]" .. excl .. "+bestaudio"),
			(base .. "[vcodec*=vp9]" .. excl .. "+bestaudio"),
			(base .. excl .. "+bestaudio"),
			(base .. excl .. "+bestaudio/best"),
		}, "/")
	end
end

----------------------------------------------------------------
-- (1) KALİTE MENÜSÜ
----------------------------------------------------------------
local fmt_cache = {}
local function fetch_formats_with_ytdlp(url)
	url = url:gsub("^ytdl://", "")
	if fmt_cache[url] then
		return fmt_cache[url]
	end

	mp.osd_message("yt-dlp ile formatlar alınıyor...", 60)
	-- yt-dlp konumu: mp.find_config_file("yt-dlp") ile PATH dışı kontrol
	local ytdlp_path = "yt-dlp"
	local found = mp.find_config_file("yt-dlp")
	if found ~= nil then
		ytdlp_path = found
	end

	local status, out = exec({ ytdlp_path, "--no-warnings", "--no-playlist", "-J", url })
	if status ~= 0 or out == "" then
		mp.osd_message("yt-dlp başarısız", 2)
		msg.error("yt-dlp JSON alınamadı; status=" .. tostring(status))
		return {}
	end

	local data, err = utils.parse_json(out)
	if not data then
		mp.osd_message("yt-dlp JSON parse hatası", 2)
		msg.error("parse_json: " .. tostring(err))
		return {}
	end

	local res = {}
	for _, f in ipairs(data.formats or {}) do
		if f.vcodec and f.vcodec ~= "none" and f.width and f.height then
			local fps = f.fps and (tostring(f.fps) .. "fps") or ""
			local label =
				string.format("%-9sx%-5s %-5s (%s)", tostring(f.width), tostring(f.height), fps, f.vcodec or "?")
			local sel = string.format("%s+bestaudio/best", f.format_id)
			table.insert(res, { label = label, format = sel, width = f.width })
		end
	end
	table.sort(res, function(a, b)
		return (a.width or 0) > (b.width or 0)
	end)
	mp.osd_message("", 0)
	fmt_cache[url] = res
	return res
end

local function preset_formats(current_fmt)
	-- Presetleri label→format tablosuna çevir
	local opts = {}
	for i, v in ipairs(QUALITY_PRESETS) do
		for label, form in pairs(v) do
			table.insert(opts, { label = label, format = form })
		end
	end
	return opts
end

local function quality_menu_show()
	local current = mp.get_property("ytdl-format") or ""
	local path = mp.get_property("path") or ""
	local options = {}

	if OPTS.fetch_formats_with_ytdlp and path:match("^%a+://") then
		options = fetch_formats_with_ytdlp(path)
	end
	if #options == 0 then
		options = preset_formats(current)
	end
	if #options == 0 then
		mp.osd_message("Format bulunamadı", 2)
		return
	end

	local sel, act = 1, 0
	for i, op in ipairs(options) do
		if op.format == current then
			sel = i
			act = i
			break
		end
	end

	local timeout
	local function prefix(i)
		if i == sel and i == act then
			return OPTS.cur_sel_act
		elseif i == sel then
			return OPTS.cur_sel_inact
		elseif i == act then
			return OPTS.cur_unsel_act
		else
			return OPTS.cur_unsel_inact
		end
	end

	local function draw()
		local lines = {}
		for i, op in ipairs(options) do
			table.insert(lines, prefix(i) .. op.label)
		end
		osd_ass_write(lines)
	end

	local function destroy()
		if timeout then
			timeout:kill()
		end
		mp.set_osd_ass(0, 0, "")
		mp.remove_key_binding("q_up")
		mp.remove_key_binding("q_dn")
		mp.remove_key_binding("q_sel")
		mp.remove_key_binding("q_esc")
	end

	local function move(d)
		sel = sel + d
		if sel < 1 then
			sel = #options
		elseif sel > #options then
			sel = 1
		end
		timeout:kill()
		timeout:resume()
		draw()
	end

	timeout = mp.add_periodic_timer(OPTS.menu_timeout, destroy)
	mp.add_forced_key_binding(OPTS.quality_up_key, "q_up", function()
		move(-1)
	end, { repeatable = true })
	mp.add_forced_key_binding(OPTS.quality_down_key, "q_dn", function()
		move(1)
	end, { repeatable = true })
	mp.add_forced_key_binding(OPTS.quality_select_key, "q_sel", function()
		destroy()
		mp.set_property("ytdl-format", options[sel].format)
		-- Reload with the new ytdl-format (keeping position when possible).
		-- This avoids fighting with start-file hooks and makes the selection immediate.
		local cur_path = mp.get_property("path")
		local dur = mp.get_property_number("duration") -- nil/0 => live
		local tpos = mp.get_property_number("time-pos")
		if cur_path and cur_path ~= "" then
			if dur and dur > 0 and tpos then
				mp.commandv("loadfile", cur_path, "replace", "start=+" .. tostring(tpos))
			else
				mp.commandv("loadfile", cur_path, "replace")
			end
		end
	end)
	mp.add_forced_key_binding(OPTS.quality_toggle_key, "q_esc", destroy)

	draw()
end

mp.add_key_binding(OPTS.quality_toggle_key, "ytp-quality-menu", quality_menu_show)
mp.register_script_message("ytp-toggle-quality-menu", quality_menu_show)

----------------------------------------------------------------
-- (2) UP NEXT / ÖNERİLER MENÜSÜ
----------------------------------------------------------------
local upnext_cache = {}
local prefered_win_width, last_dwidth, last_dheight = nil, nil, nil

-- ytdl-raw-options.cookiess'ten otomatik al
if OPTS.cookies_file == "" then
	local raw = mp.get_property_native("options/ytdl-raw-options") or {}
	for k, v in pairs(raw) do
		if k == "cookies" and v ~= "" then
			OPTS.cookies_file = v
		end
	end
end

local function wget_page(url, post_data)
	local cmd = { "wget", "-q", "-O", "-" }
	if not OPTS.check_certificate then
		table.insert(cmd, "--no-check-certificate")
	end
	if post_data then
		table.insert(cmd, "--post-data")
		table.insert(cmd, post_data)
	end
	if OPTS.cookies_file and OPTS.cookies_file ~= "" then
		table.insert(cmd, "--load-cookies")
		table.insert(cmd, OPTS.cookies_file)
		table.insert(cmd, "--save-cookies")
		table.insert(cmd, OPTS.cookies_file)
		table.insert(cmd, "--keep-session-cookies")
	end
	table.insert(cmd, url)
	local st, out = exec(cmd)
	return st, out
end

local function url_encode(s)
	return (s:gsub("([^0-9a-zA-Z!'()*._~-])", function(x)
		return string.format("%%%02X", string.byte(x))
	end))
end

local function parse_upnext_html(html)
	-- Çerez onayı
	local consent_pos = html:find('action="https://consent.youtube.com/s"', 1, true)
	if consent_pos then
		local form = html:sub(html:find(">", consent_pos + 1, true), html:find("</form", consent_pos + 1, true))
		local post_str = ""
		for k, v in form:gmatch('name="([^"]+)" value="([^"]*)"') do
			post_str = post_str .. url_encode(k) .. "=" .. url_encode(v) .. "&"
		end
		if OPTS.cookies_file == "" or OPTS.cookies_file == nil then
			local temp = os.getenv("TEMP") or os.getenv("XDG_RUNTIME_DIR")
			OPTS.cookies_file = (temp and (temp .. "/ytp-upnext.cookies")) or os.tmpname()
			msg.warn('Cookies jar oluşturuldu: "' .. tostring(OPTS.cookies_file) .. '"')
		end
		local st, out = wget_page("https://consent.youtube.com/s", post_str)
		if st ~= 0 then
			return "{}"
		end
		return out
	end

	-- ytInitialData JSON'ı çek
	local pos1 = html:find("ytInitialData =", 1, true)
	if not pos1 then
		return "{}"
	end
	local pos2 = html:find(";%s*</script>", pos1 + 1)
	if pos2 then
		local json = html:sub(pos1 + 15, pos2 - 1)
		return json
	end
	return "{}"
end

local function get_invidious_list(url)
	local api = url:gsub("https://youtube%.com/watch%?v=", OPTS.invidious_instance .. "/api/v1/videos/")
		:gsub("https://www%.youtube%.com/watch%?v=", OPTS.invidious_instance .. "/api/v1/videos/")
		:gsub("https://youtu%.be/", OPTS.invidious_instance .. "/api/v1/videos/")
	local st, out = exec({ "wget", "-q", "-O", "-", api })
	if st ~= 0 or out == "" then
		return {}
	end
	local data, err = utils.parse_json(out)
	if not data then
		return {}
	end
	local res = {}
	for i, v in ipairs(data.recommendedVideos or {}) do
		table.insert(res, {
			index = i,
			label = string.format("%s - %s", v.title or "?", v.author or "?"),
			file = string.format(OPTS.youtube_url_fmt, v.videoId or ""),
		})
	end
	return res
end

local function parse_upnext_json(json_str, current_url)
	local data, err = utils.parse_json(json_str)
	if not data then
		msg.error("Upnext JSON parse hatası: " .. tostring(err))
		return {}
	end
	local res, idx = {}, 1

	-- Autoplay
	local ap = (((data.playerOverlays or {}).playerOverlayRenderer or {}).autoplay or {}).playerOverlayAutoplayRenderer
	local autoplay_id = nil
	if ap and ap.videoId and ap.videoTitle and ap.videoTitle.simpleText then
		autoplay_id = ap.videoId
		table.insert(res, {
			index = idx,
			label = ap.videoTitle.simpleText,
			file = string.format(OPTS.youtube_url_fmt, ap.videoId),
		})
		idx = idx + 1
	end

	-- EndScreen
	local es = (((data.playerOverlays or {}).playerOverlayRenderer or {}).endScreen or {}).watchNextEndScreenRenderer
	if es and es.results then
		for i, v in ipairs(es.results) do
			local r = v.endScreenVideoRenderer
			if r and r.videoId and r.title and r.title.simpleText and r.videoId ~= autoplay_id then
				table.insert(res, {
					index = idx + i,
					label = r.title.simpleText,
					file = string.format(OPTS.youtube_url_fmt, r.videoId),
				})
			end
		end
		idx = idx + #es.results
	end

	-- Secondary / WatchNext
	local sec = ((data.contents or {}).twoColumnWatchNextResults or {}).secondaryResults
	if sec and sec.secondaryResults then
		sec = sec.secondaryResults
	end
	if sec and sec.results then
		for i, v in ipairs(sec.results) do
			local cvr = (
				v.compactAutoplayRenderer
				and v.compactAutoplayRenderer.contents
				and v.compactAutoplayRenderer.contents.compactVideoRenderer
			) or v.compactVideoRenderer
			if cvr and cvr.videoId and cvr.title and cvr.title.simpleText then
				local url = string.format(OPTS.youtube_url_fmt, cvr.videoId)
				local dup = false
				for _, e in ipairs(res) do
					if e.file == url then
						dup = true
						break
					end
				end
				if not dup then
					table.insert(res, { index = idx + i, label = cvr.title.simpleText, file = url })
				end
			end
		end
	end

	table.sort(res, function(a, b)
		return a.index < b.index
	end)
	upnext_cache[current_url] = res
	return res
end

local function load_upnext_list()
	local url = mp.get_property("path") or ""
	url = url:gsub("^ytdl://", "")
	if not url:find("youtu") then
		return {}
	end
	if upnext_cache[url] then
		return upnext_cache[url]
	end

	mp.osd_message("Öneriler yükleniyor...", 60)
	local st, html = wget_page(url, nil)
	mp.osd_message("", 0)
	if st ~= 0 or html == "" then
		-- Invidious fallback
		local alt = get_invidious_list(url)
		return alt
	end
	local json_str = parse_upnext_html(html)
	local res = {}
	if json_str ~= "{}" then
		res = parse_upnext_json(json_str, url)
	end
	if #res == 0 then
		res = get_invidious_list(url)
	end
	return res
end

local function upnext_menu_show()
	local list = load_upnext_list()
	if #list == 0 then
		mp.osd_message("Öneri bulunamadı", 2)
		return
	end

	local sel, timeout = 1, nil
	local function draw()
		local lines = {}
		for i, it in ipairs(list) do
			local cur = (i == sel) and "● " or "○ "
			table.insert(lines, cur .. it.label)
		end
		osd_ass_write(lines)
	end

	local function destroy()
		if timeout then
			timeout:kill()
		end
		mp.set_osd_ass(0, 0, "")
		mp.remove_key_binding("u_up")
		mp.remove_key_binding("u_dn")
		mp.remove_key_binding("u_sel")
		mp.remove_key_binding("u_esc")
	end

	local function move(d)
		sel = sel + d
		if sel < 1 then
			sel = #list
		elseif sel > #list then
			sel = 1
		end
		timeout:kill()
		timeout:resume()
		draw()
	end

	timeout = mp.add_periodic_timer(OPTS.menu_timeout, destroy)
	mp.add_forced_key_binding(OPTS.upnext_up_key, "u_up", function()
		move(-1)
	end, { repeatable = true })
	mp.add_forced_key_binding(OPTS.upnext_down_key, "u_dn", function()
		move(1)
	end, { repeatable = true })
	mp.add_forced_key_binding(OPTS.upnext_select_key, "u_sel", function()
		destroy()
		mp.commandv("loadfile", list[sel].file, "replace")
	end)
	mp.add_forced_key_binding(OPTS.upnext_toggle_key, "u_esc", destroy)

	draw()
end

mp.add_key_binding(OPTS.upnext_toggle_key, "ytp-upnext-menu", upnext_menu_show)
mp.register_script_message("ytp-toggle-upnext-menu", upnext_menu_show)

-- Dosya yüklenince "up next" otomatik ekle
local function on_file_loaded_append_upnext()
	if not OPTS.upnext_auto_add then
		return
	end
	local path = mp.get_property("path") or ""
	path = path:gsub("^ytdl://", "")
	if not path:find("youtu") then
		return
	end
	local list = load_upnext_list()
	if #list > 0 then
		mp.commandv("loadfile", list[1].file, "append")
	end
end
if OPTS.upnext_auto_add then
	mp.register_event("file-loaded", on_file_loaded_append_upnext)
end

-- Pencere genişliği koruma
local function on_window_scale_changed(_, val)
	if not OPTS.restore_window_width or val == nil then
		return
	end
	local dw = mp.get_property("dwidth")
	local dh = mp.get_property("dheight")
	if dw and dh and dw == last_dwidth and dh == last_dheight then
		local cur = mp.get_property("current-window-scale")
		prefered_win_width = dw * cur
	end
end
local function on_dwidth_change(_, val)
	if not OPTS.restore_window_width or val == nil then
		return
	end
	local dw = mp.get_property("dwidth")
	local dh = mp.get_property("dheight")
	if not (dw and dh) then
		return
	end
	last_dwidth, last_dheight = dw, dh
	if not prefered_win_width then
		return
	end
	local cur = mp.get_property("current-window-scale")
	local ww = dw * cur
	local new = cur
	if math.abs(prefered_win_width - ww) > 2 then
		new = prefered_win_width / dw
	end
	if new ~= cur then
		mp.set_property("window-scale", new)
	end
end
if OPTS.restore_window_width then
	mp.observe_property("current-window-scale", "number", on_window_scale_changed)
	mp.observe_property("dwidth", "number", on_dwidth_change)
end

----------------------------------------------------------------
-- (3) AKILLI OTOMATİK (format/subtitles/profiller)
----------------------------------------------------------------
local function set_formats_smart()
	local path = get_opt("path")
	if not path or not path:match("^(%a+://)") then
		msg.info("[yt_power] Yerel dosya/stream değil; ytdl-format dokunulmadı.")
		return
	end

	-- If the user manually set ytdl-format (different from what we last applied),
	-- do not override it on reloads.
	local current_fmt = mp.get_property("ytdl-format") or ""
	if current_fmt ~= "" and last_auto_ytdl_format ~= nil and current_fmt ~= last_auto_ytdl_format then
		msg.info("[yt_power] manual ytdl-format detected; skipping auto override: " .. current_fmt)
		return
	end

	-- Güvenli baseline
	local def_fmt = build_default_format()
	mp.set_property("ytdl-format", def_fmt)
	last_auto_ytdl_format = def_fmt
	msg.info("[yt_power] baseline ytdl-format: " .. def_fmt)

	if is_target_domain(path) then
		local dom_fmt = build_domain_format()
		mp.set_property("ytdl-format", dom_fmt)
		last_auto_ytdl_format = dom_fmt
		msg.info("[yt_power] hedef domain → ytdl-format: " .. dom_fmt)

		if OPTS.set_sub_langs and #OPTS.set_sub_langs > 0 then
			mp.set_property("ytdl-raw-options-append", "sub-langs=" .. OPTS.set_sub_langs)
			msg.info("[yt_power] sub-langs=" .. OPTS.set_sub_langs)
		end
	end
end

local function apply_profiles_smart()
	if not OPTS.apply_profiles then
		return
	end
	local path = get_opt("path")
	local demuxer = get_opt("demuxer")
	local width = mp.get_property_number("width")
	local height = mp.get_property_number("height")
	local duration = mp.get_property_number("duration")
	local seekable = mp.get_property_native("seekable") -- bool

	-- YouTube içeriği
	if path and is_target_domain(path) and path:match("youtu%.?be") then
		mp.commandv("apply-profile", OPTS.profile_youtube)
	end
	-- 4K profili
	if (width and width >= 3840) or (height and height >= 2160) then
		mp.commandv("apply-profile", OPTS.profile_4k)
	end

	-- canlı algısı
	local is_live = false
	local path = get_opt("path")
	local demuxer = get_opt("demuxer")

	if path and path:match("%.m3u8") then
		is_live = true
	elseif demuxer == "hls" then
		is_live = true
	elseif (duration == nil or duration == 0) or (seekable == false) then
		is_live = true
	end
	if is_live then
		mp.commandv("apply-profile", OPTS.profile_live)
	end
end

mp.register_event("start-file", function()
	set_formats_smart()
end)
mp.register_event("file-loaded", function()
	apply_profiles_smart()
end)

-- Son.
