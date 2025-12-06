-- reload.lua (compact + instant-reload)
-- Ctrl+r: anında yeniden yükle (konumu korur)
-- Otomatik: cache ilerlemiyorsa ve paused-for-cache olduysa yeniden yükle
-- "Stuck" ise paused-for-cache anında BEKLEMEDEN reload

local mp = require("mp")
local msg = require("mp.msg")
local utils = require("mp.utils")
local options = require("mp.options")

local OPT = {
	-- paused-for-cache için bekleme sayacı
	paused_watch_enabled = true,
	paused_watch_interval = 1, -- sn
	paused_watch_timeout = 10, -- sn

	-- demuxer-cache-time ilerlemesini izleyip "stuck" tespiti
	cache_watch_enabled = true,
	cache_watch_interval = 2, -- sn
	cache_watch_timeout = 20, -- sn  (bu kadar süredir ilerleme yoksa "stuck")

	-- EOF'a gelince yeniden dene (varsayılan kapalı)
	reload_on_eof = false,

	-- kısayol
	reload_key_binding = "Ctrl+r",
}

options.read_options(OPT, mp.get_script_name())

-- Dahili durum
local cache_last_time = 0
local cache_stale_elapsed = 0
local cache_stuck = false
local paused_timer = nil
local eof_keep_open_backup = nil
local last_reload_timepos = 0

local function round(n)
	return math.floor((n or 0) + 0.5)
end

----------------------------------------------------------------------
-- Yardımcı: Yeniden yükle (VOD'da zaman ofseti, canlıda ofsetsiz)
----------------------------------------------------------------------
local function do_reload()
	local path = mp.get_property("path")
	if not path or path == "" then
		return
	end

	local tpos = mp.get_property_number("time-pos") -- nil olabilir
	local dur = mp.get_property_number("duration") -- nil/0 => canlı
	local pcount = mp.get_property_number("playlist/count", 0)
	local ppos = mp.get_property_number("playlist-pos", 0)

	-- Playlist'i sakla (mpv reload sırasında listeyi sıfırlayabildiği için)
	local pl = {}
	for i = 0, pcount - 1 do
		pl[i] = mp.get_property(("playlist/%d/filename"):format(i))
	end

	if dur and dur >= 0 then
		-- VOD (dur > 0) veya bazı kaynaklarda 0 görünebiliyor → ikisinde de offset güvenli
		msg.info("reloading from", tpos or 0, "sec")
		if tpos then
			mp.commandv("loadfile", path, "replace", "start=+" .. tostring(tpos))
		else
			mp.commandv("loadfile", path, "replace")
		end
	else
		-- Gerçek canlı: konum sabit değil, ofsetsiz
		msg.info("reloading live stream")
		mp.commandv("loadfile", path, "replace")
	end

	-- Playlist'i eski sırayla geri kur
	if pcount > 0 then
		msg.info("playlist", ppos + 1, "of", pcount)
		for i = 0, ppos - 1 do
			if pl[i] then
				mp.commandv("loadfile", pl[i], "append")
			end
		end
		mp.commandv("playlist-move", 0, ppos + 1)
		for i = ppos + 1, pcount - 1 do
			if pl[i] then
				mp.commandv("loadfile", pl[i], "append")
			end
		end
	end
end

----------------------------------------------------------------------
-- Workaround: reload sonrası bazen “oynamıyor” → çift SPACE
----------------------------------------------------------------------
local function on_file_loaded()
	-- Durum bilgisi
	msg.debug(
		"file-loaded",
		utils.to_string({
			t = mp.get_property("time-pos"),
			dur = mp.get_property("duration"),
			pause = mp.get_property("pause"),
			pfc = mp.get_property("paused-for-cache"),
			cache100 = mp.get_property("cache-buffering-state"),
		})
	)
	mp.commandv("keypress", "SPACE")
	mp.commandv("keypress", "SPACE")
end
mp.register_event("file-loaded", on_file_loaded)

----------------------------------------------------------------------
-- Cache izleyici: demuxer-cache-time ilerliyor mu?
----------------------------------------------------------------------
if OPT.cache_watch_enabled then
	mp.add_periodic_timer(OPT.cache_watch_interval, function()
		local ct = mp.get_property_native("demuxer-cache-time") or 0
		if ct == cache_last_time then
			cache_stale_elapsed = cache_stale_elapsed + OPT.cache_watch_interval
		else
			cache_stale_elapsed = 0
			cache_last_time = ct
		end
		local stuck_now = (cache_stale_elapsed >= OPT.cache_watch_timeout)
		if stuck_now ~= cache_stuck then
			cache_stuck = stuck_now
			msg.debug("cache stuck:", cache_stuck, "stale_elapsed:", cache_stale_elapsed)
		end
	end)
end

----------------------------------------------------------------------
-- paused-for-cache yönetimi: bekleme sayacı + INSTANT reload
----------------------------------------------------------------------
local function stop_paused_timer()
	if paused_timer then
		paused_timer:kill()
		paused_timer = nil
	end
end

local function start_paused_timer()
	if paused_timer then
		return
	end
	local elapsed = 0
	paused_timer = mp.add_periodic_timer(OPT.paused_watch_interval, function()
		elapsed = elapsed + OPT.paused_watch_interval
		if elapsed >= OPT.paused_watch_timeout then
			stop_paused_timer()
			cache_stale_elapsed = 0 -- yeni başlangıç
			do_reload()
		end
	end)
end

local function on_paused_for_cache(_, is_paused)
	if is_paused then
		-- Eğer cache zaten "stuck" ise: HEMEN reload (bekleme yok)
		if OPT.cache_watch_enabled and cache_stuck then
			stop_paused_timer()
			cache_stale_elapsed = 0
			msg.info("cache stuck → instant reload")
			do_reload()
			return
		end
		-- Değilse normal timeout ile bekle
		if OPT.paused_watch_enabled then
			start_paused_timer()
		end
	else
		stop_paused_timer()
	end
end

if OPT.paused_watch_enabled then
	mp.observe_property("paused-for-cache", "bool", on_paused_for_cache)
end

----------------------------------------------------------------------
-- EOF'ta yeniden dene (opsiyonel)
----------------------------------------------------------------------
if OPT.reload_on_eof then
	mp.observe_property("vo-configured", "bool", function(_, ok)
		if ok then
			eof_keep_open_backup = mp.get_property("keep-open")
			mp.set_property("keep-open", "yes")
			mp.set_property("keep-open-pause", "no")
		end
	end)

	mp.observe_property("eof-reached", "bool", function(_, eof)
		if not eof then
			return
		end
		local t = mp.get_property_number("time-pos") or 0
		local dur = mp.get_property_number("duration") or 0
		if round(t) == round(dur) then
			if round(last_reload_timepos) == round(t) then
				-- Artış yok → gerçekten bitti
				mp.set_property("keep-open", eof_keep_open_backup)
			else
				-- Belki devam var → bir kez daha dene
				msg.info("EOF → trying reload to see if more content appeared")
				last_reload_timepos = t
				do_reload()
				mp.set_property_bool("pause", false)
			end
		end
	end)
end

----------------------------------------------------------------------
-- Keybinding: Ctrl+r → anında yeniden yükle
----------------------------------------------------------------------
local function reload_key()
	do_reload()
end
if OPT.reload_key_binding and OPT.reload_key_binding ~= "" then
	mp.add_key_binding(OPT.reload_key_binding, "reload_resume", reload_key)
end
