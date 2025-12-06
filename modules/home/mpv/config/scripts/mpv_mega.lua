-- mpv_mega.lua — Kenan için tek dosya çoklu özellik
-- 1) Absolute Screenshot (EXIF tarih + time-pos) [Ctrl+S]
-- 2) Audio’da OSC her zaman açık
-- 3) delay-command (script-message ile gecikmeli komut)
-- 4) profile_command (profil içinden komut tetikleme)
-- 5) Rename file (F2; user-input-module varsa etkileşimli)
-- 6) input-command (parametre isteyen komutlar)
-- 7) EXIT FULLSCREEN ON EOF
-- 8) ACOMPRESSOR KONTROLÜ (dinamik aralık sıkıştırma)
-- 9) AFTER-PLAYBACK (Windows için nircmd ile sistem eylemi)
-- 10) DELETE FILE (işaretle → çıkarken taşı/sil)
-- 11) EDITIONS NOTIFICATION (çoklu edition varsa uyar & osd-playing-msg'i edition-list yap)
-- 12) QUICK-SCALE (pencereyi hedef boyuta ölçekle)
-- 13) SEEK-TO (sayı tuşlarıyla timestamp girerek git + panodan yapıştır)

local mp = require("mp")
local msg = require("mp.msg")
local utils = require("mp.utils")
local assdraw = require("mp.assdraw")

----------------------------------------------------------------
-- 1) ABSOLUTE SCREENSHOT (EXIF + time-pos)
----------------------------------------------------------------
local function _parse_exif_datetime(s)
	-- Beklenen biçimler:
	--  "YYYY:MM:DD HH:MM:SS"
	--  Bazı cihazlarda CreateDate/MediaCreateDate kullanılabilir.
	if not s or s == "" then
		return nil
	end
	local y, M, d, h, m, sec = s:match("(%d+):(%d+):(%d+)%s+(%d+):(%d+):(%d+)")
	if not (y and M and d and h and m and sec) then
		return nil
	end
	return os.time({
		year = tonumber(y),
		month = tonumber(M),
		day = tonumber(d),
		hour = tonumber(h),
		min = tonumber(m),
		sec = tonumber(sec),
	})
end

local function _exif_first_datetime(path)
	-- Sırayla dene: DateTimeOriginal, CreateDate, MediaCreateDate
	-- -T ile sadece değer (tab-ayrımlı) gelir, ilk dolu olanı al.
	local fields = { "-DateTimeOriginal", "-CreateDate", "-MediaCreateDate" }
	for _, f in ipairs(fields) do
		local t = {
			args = { "exiftool", "-s3", "-T", f, path },
			capture_stdout = true,
			capture_stderr = true,
		}
		local r = utils.subprocess(t)
		if r and r.error == nil and r.status == 0 then
			local v = (r.stdout or ""):gsub("%s+$", "")
			local ts = _parse_exif_datetime(v)
			if ts then
				return ts, f
			end
		end
	end
	return nil, nil
end

local function _sanitize_filename_piece(s)
	-- Dosya adı parçası için kaba temizlik
	s = s:gsub("[\r\n]", " "):gsub('[/:*?"<>|]', "_")
	s = s:gsub("%s+", " ")
	return s
end

local function _ensure_dir_prefix(dir)
	if not dir or dir == "" then
		return ""
	end
	if dir:sub(-1) == "/" then
		return dir
	end
	return dir .. "/"
end

local function screenshot_timestamp()
	local pos = mp.get_property_native("time-pos") or 0
	local path = mp.get_property("path")
	if not path then
		msg.warn("[abs-shot] path yok, iptal")
		return
	end

	local exif_ts, used_field = _exif_first_datetime(path)
	if not exif_ts then
		msg.warn(
			"[abs-shot] EXIF tarih bulunamadı (DateTimeOriginal/CreateDate/MediaCreateDate); sistem saatini kullanacağım."
		)
		exif_ts = os.time()
	end

	local dir = _ensure_dir_prefix(mp.get_property_native("screenshot-directory") or "")
	local fname = mp.get_property_native("filename/no-ext") or "screenshot"
	local fmat = mp.get_property_native("screenshot-format") or "png"

	local whole = math.floor(pos)
	local frac = pos - whole
	local millis = string.format("%03d", math.floor((frac >= 0 and frac or 0) * 1000 + 0.5))
	local stamp = os.date("-%Y-%m-%d-%H-%M-%S", exif_ts + whole)
	local final = _sanitize_filename_piece(fname .. stamp .. "-" .. millis) .. "." .. fmat
	local outpath = dir .. final

	msg.info(string.format("[abs-shot] %s (kaynak: %s)", outpath, used_field or "system-time"))
	mp.commandv("screenshot-to-file", outpath, "subtitles")
	mp.osd_message("Saved: " .. final, 2)
end

mp.add_key_binding("Ctrl+s", "screenshot-timestamp", screenshot_timestamp)

----------------------------------------------------------------
-- 2) AUDIO’DA OSC’Yİ HER ZAMAN GÖSTER
----------------------------------------------------------------
mp.register_event("file-loaded", function()
	local hasvid = (mp.get_property_osd("video") or "") ~= "no"
	mp.commandv("script-message", "osc-visibility", (hasvid and "auto" or "always"), "no-osd")
	-- İstemezsen aşağıdaki satırı kaldır:
	mp.commandv("set", "options/osd-bar", (hasvid and "yes" or "no"))
end)

----------------------------------------------------------------
-- 3) DELAY-COMMAND (script-message ile)
----------------------------------------------------------------
local function delay_command_main(delay, ...)
	local ok, err = pcall(function()
		delay = tonumber(delay)
	end)
	if not ok then
		return msg.error(err)
	end
	if delay == nil then
		return msg.error("delay geçerli bir sayı değil")
	end
	if delay < 0 then
		delay = 0
	end
	local command = { ... }

	msg.verbose("delay-command: " .. tostring(delay) .. " sn sonra çalışacak")

	mp.add_timeout(delay, function()
		if #command == 1 then
			msg.debug("mp.command: " .. command[1])
			mp.command(command[1])
		else
			msg.debug('mp.commandv: "' .. table.concat(command, '" "') .. '"')
			-- Lua 5.2+ 'unpack' table.unpack
			local tu = table.unpack or unpack
			mp.commandv(tu(command))
		end
	end)
end
mp.register_script_message("delay-command", delay_command_main)

----------------------------------------------------------------
-- 4) PROFILE_COMMAND (profil içinden komut)
----------------------------------------------------------------
local o = { cmd = "" }
local opt = require("mp.options")
opt.read_options(o, "profile_command", function()
	if o.cmd == "" then
		return
	end
	msg.info("[profile_command] " .. o.cmd)
	mp.command(o.cmd)
	-- Tekrar aynı komutu tetikleyebilmek için sıfırla
	mp.commandv("change-list", "script-opts", "append", "profile_command-cmd=")
end)

----------------------------------------------------------------
-- 5) RENAME FILE (F2) — user-input-module ile
----------------------------------------------------------------
-- Kullanıcı modül yolunu ekle (varsayılan yerleşim)
package.path = mp.command_native({ "expand-path", "~~/script-modules/?.lua;" }) .. package.path

local input_ok, input = pcall(function()
	return require("user-input-module")
end)
if not input_ok then
	msg.warn("[rename-file] user-input-module.lua bulunamadı. (~~/script-modules/ altında olmalı)")
end

local function _rename_commit(newname)
	if not newname or newname == "" then
		msg.warn("[rename-file] Boş ad.")
		return
	end

	local filepath = mp.get_property("path")
	if not filepath then
		return
	end

	local directory, filename = utils.split_path(filepath)
	local name, extension = filename:match("(.*)%.([^%./]+)$")
	if not name then
		-- uzantısız dosya
		name = filename
		extension = nil
	end

	local newfilepath = directory .. newname
	msg.info(string.format("renaming '%s'%s to '%s'", name, extension and ("." .. extension) or "", newname))

	local ok, err = os.rename(filepath, newfilepath)
	if not ok then
		msg.error("[rename-file] " .. tostring(err))
		mp.osd_message("Rename failed: " .. tostring(err), 3)
		return
	end

	-- Yeni yolu oynatma listesine ekle ve geçerli öğeyi onunla değiştir
	mp.commandv("loadfile", newfilepath, "append")
	local count = mp.get_property_number("playlist-count", 2)
	local pos = mp.get_property_number("playlist-pos", 1)
	mp.commandv("playlist-move", count - 1, pos + 1)
	mp.commandv("playlist-remove", "current")
	mp.osd_message("Renamed to: " .. newname, 2)
end

-- Dosya kapanırsa girilen input’u iptal et (belirsizliği önlemek için)
mp.register_event("end-file", function()
	if input_ok then
		input.cancel_user_input()
	end
end)

mp.add_key_binding("F2", "rename-file", function()
	local filepath = mp.get_property("path")
	if not filepath then
		return
	end
	local directory, filename = utils.split_path(filepath)

	if input_ok then
		input.cancel_user_input()
		input.get_user_input(_rename_commit, {
			text = "Enter new filename:",
			default_input = filename,
			replace = false,
			cursor_pos = filename:find("%.%w+$"), -- uzantı öncesine imleç
		})
	else
		-- Modül yoksa basit bir bilgi mesajı göster
		mp.osd_message("Install: script-modules/user-input-module.lua", 3)
		msg.error("user-input-module.lua yok; etkileşimli yeniden adlandırma devre dışı.")
	end
end)

----------------------------------------------------------------
-- 6) INPUT-COMMAND (parametre isteyen komutlar; user-input-module gerekir)
----------------------------------------------------------------
-- Kullanım (input.conf örnekleri):
--   Alt+l script-message input-command "loadfile %1" "encapsulate=yes"
--   Alt+g script-message input-command "seek %1 %2" "default=10" "default=absolute"
--   Alt+o script-message input-command "screenshot-to-file %1" "encapsulate=yes|default=${screenshot-directory:~/Pictures}/${filename/no-ext}.png"

local commands_ic = {}

local function substitute_arg_ic(command, arg, text, opts)
	return command:gsub("%%%%*" .. arg, function(str)
		local hashes = str:match("^%%+"):len()
		local number = str:sub(hashes + 1)
		if number == "" then
			return false
		end
		str = str:sub(1, math.floor(hashes / 2))
		if hashes % 2 == 0 then
			-- çift % => kaçış: %%1 -> %1 olarak bırak
			return str .. number
		end
		if opts and opts.encapsulate then
			text = string.format("%q", text)
		end
		return str .. text
	end)
end

local function input_command_main(command, ...)
	if not input_ok then
		msg.error("[input-command] user-input-module.lua yok; bu özellik devre dışı.")
		mp.osd_message("Install user-input-module.lua (script-modules)", 3)
		return
	end

	local num_args, opts
	if commands_ic[command] then
		num_args = commands_ic[command].num_args
		opts = commands_ic[command].opts
	else
		commands_ic[command] = {}
		local raw_opts = { ... }
		opts = {}
		for i, opt in ipairs(raw_opts) do
			local t = {}
			for str in opt:gmatch("[^|]+") do
				local key = str:match("^[^=]+")
				t[key] = str:sub(#key + 2)
			end
			opts[i] = t
		end
		commands_ic[command].opts = opts

		local args = {}
		for str in command:gmatch("%%%%*[%d]*") do
			local hashes = str:match("^%%+"):len()
			local number = str:sub(hashes + 1)
			if number ~= "" and hashes % 2 == 1 then
				args[tonumber(number)] = true
			end
		end
		num_args = #args
		commands_ic[command].num_args = num_args
	end

	local command_copy = command
	for i = 1, num_args do
		input.get_user_input(function(text)
			if not text then
				return
			end
			command = substitute_arg_ic(command, i, text, opts[i])
			if i == num_args then
				mp.command(command)
			end
		end, {
			id = command .. "/" .. tostring(i),
			queueable = true,
			request_text = "Enter argument " .. i .. " for command: " .. command_copy,
			default_input = (opts[i] and opts[i].default) or "",
		})
	end
end

if input_ok then
	mp.register_script_message("input-command", input_command_main)
else
	msg.warn("[input-command] user-input-module.lua bulunamadı; kayıt yapılmadı.")
end

----------------------------------------------------------------
-- 7) EXIT FULLSCREEN ON EOF (keep-open=yes durumunda)
----------------------------------------------------------------
mp.observe_property("eof-reached", "bool", function(_, value)
	if value then
		local pause = mp.get_property_native("pause")
		if pause then
			local fullscreen = mp.get_property_native("fullscreen")
			if fullscreen then
				mp.set_property_native("fullscreen", false)
				msg.info("[eof-exitfs] playback ended → fullscreen kapatıldı")
			end
		end
	end
end)

----------------------------------------------------------------
-- 8) ACOMPRESSOR KONTROLÜ (dinamik aralık sıkıştırma)
--    Orijinal script uyarlanmış, namespaceli, kısayollar çakışmasın diye Alt+*.
----------------------------------------------------------------
do
	local options = require("mp.options")
	local o_ac = {
		default_enable = false,
		show_osd = true,
		osd_timeout = 4000,
		filter_label = "mega-acompressor",

		key_toggle = "Alt+n",
		key_increase_threshold = "Alt+F1",
		key_decrease_threshold = "Alt+Shift+F1",
		key_increase_ratio = "Alt+F2",
		key_decrease_ratio = "Alt+Shift+F2",
		key_increase_knee = "Alt+F3",
		key_decrease_knee = "Alt+Shift+F3",
		key_increase_makeup = "Alt+F4",
		key_decrease_makeup = "Alt+Shift+F4",
		key_increase_attack = "Alt+F5",
		key_decrease_attack = "Alt+Shift+F5",
		key_increase_release = "Alt+F6",
		key_decrease_release = "Alt+Shift+F6",

		default_threshold = -25.0,
		default_ratio = 3.0,
		default_knee = 2.0,
		default_makeup = 8.0,
		default_attack = 20.0,
		default_release = 250.0,

		step_threshold = -2.5,
		step_ratio = 1.0,
		step_knee = 1.0,
		step_makeup = 1.0,
		step_attack = 10.0,
		step_release = 10.0,
	}
	options.read_options(o_ac, "mega_acompressor")

	local params_ac = {
		{ name = "attack", min = 0.01, max = 2000, hide_default = true, dB = "" },
		{ name = "release", min = 0.01, max = 9000, hide_default = true, dB = "" },
		{ name = "threshold", min = -30, max = 0, hide_default = false, dB = "dB" },
		{ name = "ratio", min = 1, max = 20, hide_default = false, dB = "" },
		{ name = "knee", min = 1, max = 10, hide_default = true, dB = "dB" },
		{ name = "makeup", min = 0, max = 24, hide_default = false, dB = "dB" },
	}

	local function parse_value_ac(v)
		return tonumber((v or ""):gsub("dB$", ""), nil)
	end
	local function format_value_ac(v, dB)
		return string.format("%g%s", v, dB or "")
	end

	local function show_osd_ac(filter)
		if not o_ac.show_osd then
			return
		end
		if not filter.enabled then
			mp.commandv("show-text", "Dynamic range compressor: disabled", o_ac.osd_timeout)
			return
		end
		local pretty = {}
		for _, p in ipairs(params_ac) do
			local val = parse_value_ac(filter.params[p.name])
			if not (p.hide_default and val == o_ac["default_" .. p.name]) then
				pretty[#pretty + 1] = string.format("%s: %g%s", p.name:gsub("^%l", string.upper), val, p.dB)
			end
		end
		local suffix = (#pretty > 0) and ("\n(" .. table.concat(pretty, ", ") .. ")") or ""
		mp.commandv("show-text", "Dynamic range compressor: enabled" .. suffix, o_ac.osd_timeout)
	end

	local function get_filter_ac()
		local af = mp.get_property_native("af", {})
		for i = 1, #af do
			if af[i].label == o_ac.filter_label then
				return af, i
			end
		end
		af[#af + 1] = { name = "acompressor", label = o_ac.filter_label, enabled = false, params = {} }
		for _, p in pairs(params_ac) do
			af[#af].params[p.name] = format_value_ac(o_ac["default_" .. p.name], p.dB)
		end
		return af, #af
	end

	local function toggle_ac()
		local af, i = get_filter_ac()
		af[i].enabled = not af[i].enabled
		mp.set_property_native("af", af)
		show_osd_ac(af[i])
	end

	local function update_param_ac(name, inc)
		for _, p in pairs(params_ac) do
			if p.name == string.lower(name) then
				local af, i = get_filter_ac()
				local v = parse_value_ac(af[i].params[p.name])
				v = math.max(p.min, math.min(v + inc, p.max))
				af[i].params[p.name] = format_value_ac(v, p.dB)
				af[i].enabled = true
				mp.set_property_native("af", af)
				show_osd_ac(af[i])
				return
			end
		end
		msg.error('[acompressor] unknown param "' .. tostring(name) .. '"')
	end

	mp.add_key_binding(o_ac.key_toggle, "mega-toggle-acompressor", toggle_ac)
	mp.register_script_message("mega-update-acompressor-param", update_param_ac)

	for _, p in pairs(params_ac) do
		for dir, step in pairs({ increase = 1, decrease = -1 }) do
			local key = o_ac["key_" .. dir .. "_" .. p.name]
			if key and key ~= "" then
				mp.add_key_binding(key, "mega-acompressor-" .. dir .. "-" .. p.name, function()
					update_param_ac(p.name, step * o_ac["step_" .. p.name])
				end, { repeatable = true })
			end
		end
	end

	if o_ac.default_enable then
		local af, i = get_filter_ac()
		af[i].enabled = true
		mp.set_property_native("af", af)
	end
end

----------------------------------------------------------------
-- 9) AFTER-PLAYBACK (Windows için nircmd ile sistem eylemi)
--    Varsayılan "nothing". Windows dışında da ekli olabilir; aktif değilse çalışmaz.
--    Mesaj: script-message after-playback [command] {flag}
--    command: nothing|lock|sleep|logoff|hibernate|displayoff|shutdown|reboot
--    flag: osd|no_osd
----------------------------------------------------------------
do
	local ap_opt = require("mp.options")
	local ap_utils = require("mp.utils")

	local ap_o = {
		default = "nothing", -- script-opts=afterplayback-default=shutdown (örnek)
		always_run_on_shutdown = false,
		osd_output = true,
	}

	local function ap_osd(msgtxt)
		if ap_o.osd_output then
			mp.osd_message(msgtxt, 2)
		end
	end

	local ap_commands = {}
	local ap_current_action = "nothing"
	local ap_active = false
	local ap_reason = ""

	local function ap_set_action(action, flag)
		msg.debug("[afterplayback] flag=" .. tostring(flag))
		local prev = ap_o.osd_output
		if flag == "osd" then
			ap_o.osd_output = true
		elseif flag == "no_osd" then
			ap_o.osd_output = false
		end

		if ap_active or action ~= "nothing" then
			msg.info("after playback: " .. action)
			ap_osd("after playback: " .. action)
		end

		ap_commands = { "nircmd" }
		ap_active = true

		if action == "sleep" then
			ap_commands[2] = "standby"
		elseif action == "logoff" then
			ap_commands[2] = "exitwin"
			ap_commands[3] = "logoff"
		elseif action == "hibernate" then
			ap_commands[2] = "hibernate"
		elseif action == "shutdown" then
			ap_commands[2] = "initshutdown"
			ap_commands[3] = "60 seconds before system shuts down"
			ap_commands[4] = "60"
		elseif action == "reboot" then
			ap_commands[2] = "initshutdown"
			ap_commands[3] = "60 seconds before system reboots"
			ap_commands[4] = "60"
			ap_commands[5] = "reboot"
		elseif action == "lock" then
			ap_commands[2] = "lockws"
		elseif action == "displayoff" then
			ap_commands[2] = "monitor"
			ap_commands[3] = "off"
		elseif action == "nothing" then
			ap_active = false
		else
			msg.warn('unknown action "' .. tostring(action) .. '"')
			ap_osd("after-playback: unknown action")
			action = ap_current_action
		end

		ap_o.osd_output = prev
		ap_current_action = action
	end

	local function ap_run_action()
		if not ap_active then
			return
		end
		msg.info('executing command "' .. ap_current_action .. '"')
		mp.command_native({ name = "subprocess", playback_only = false, args = ap_commands })
	end

	local function ap_record_eof(ev)
		if not ap_active then
			return
		end
		msg.debug('saving reason for end-file: "' .. tostring(ev.reason) .. '"')
		ap_reason = ev.reason or ""
	end

	local function ap_shutdown()
		if not ap_active then
			return
		end
		msg.debug("shutting down mpv, testing for shutdown reason")
		if ap_reason == "eof" or ap_o.always_run_on_shutdown then
			msg.debug("shutdown caused by eof (or forced), running action")
			ap_run_action()
		end
	end

	ap_opt.read_options(ap_o, "afterplayback")
	ap_set_action(ap_o.default)
	msg.verbose('default action after playback is "' .. ap_current_action .. '"')

	mp.register_event("end-file", ap_record_eof)
	mp.register_event("shutdown", ap_shutdown)
	mp.register_script_message("after-playback", ap_set_action)
end

----------------------------------------------------------------
-- 10) DELETE FILE (işaretle → çıkarken taşı/sil)
--     Varsayılan: MoveToFolder=false (doğrudan siler)
--     Ayarlar (mpv.conf / script-opts):
--       script-opts=mega_delete_file-MoveToFolder=yes
--       script-opts=mega_delete_file-DeletedFilesPath=/path/to/delete_file
--     Kısayollar:
--       Ctrl+Del   : mevcut dosyayı işaretle / işareti kaldır
--       Alt+Del    : işaretli dosyaları OSD’de göster (aç/kapa)
--       Ctrl+Shift+Del : tüm işaretleri temizle
--     Not: İşaretli dosyalar mpv kapanınca taşınır/silinir.
----------------------------------------------------------------
do
	local mp = mp
	local utils = require("mp.utils")
	local opt = require("mp.options")

	local options = {
		MoveToFolder = false,
		DeletedFilesPath = "",
	}

	-- Varsayılan hedef klasör
	if package.config:sub(1, 1) == "/" then
		options.DeletedFilesPath = utils.join_path(os.getenv("HOME") or "~", "delete_file")
	else
		options.DeletedFilesPath = utils.join_path(os.getenv("USERPROFILE") or ".", "delete_file")
	end

	-- script-opts prefix: mega_delete_file
	opt.read_options(options, "mega_delete_file")

	local del_list = {}
	local showListTimer

	local function createDirectory()
		if not utils.file_info(options.DeletedFilesPath) then
			-- basit mkdir (OS'a bırakıyoruz)
			local ok = os.execute(string.format('mkdir "%s"', options.DeletedFilesPath))
			if not ok then
				print("[delete_file] failed to create folder: " .. tostring(options.DeletedFilesPath))
			end
		end
	end

	local function contains_item(l, i)
		for k, v in pairs(l) do
			if v == i then
				mp.osd_message("Undeleting current file")
				l[k] = nil
				return true
			end
		end
		mp.osd_message("Deleting current file")
		return false
	end

	local function mark_delete()
		local work_dir = mp.get_property_native("working-directory")
		local file_path = mp.get_property_native("path")
		if not file_path then
			return
		end
		local final_path
		local s = file_path:find(work_dir, 0, true)
		if s and s == 0 then
			final_path = file_path
		else
			final_path = utils.join_path(work_dir, file_path)
		end
		if not contains_item(del_list, final_path) then
			table.insert(del_list, final_path)
		end
	end

	local function delete_marked()
		if options.MoveToFolder then
			createDirectory()
		end
		for _, v in pairs(del_list) do
			if options.MoveToFolder then
				print("[delete_file] moving: " .. v)
				local _, file_name = utils.split_path(v)
				-- isim çakışmalarında _N ekleyerek dene
				for i = 1, 100 do
					local candidate = file_name
					if i > 1 then
						if candidate:find("[.].+$") then
							candidate = candidate:gsub("([.].+)$", string.format("_%d%%1", i))
						else
							candidate = string.format("%s_%d", candidate, i)
						end
					end
					local movedPath = utils.join_path(options.DeletedFilesPath, candidate)
					if not utils.file_info(movedPath) then
						os.rename(v, movedPath)
						break
					end
				end
			else
				print("[delete_file] deleting: " .. v)
				os.remove(v)
			end
		end
	end

	local function showList()
		local delString = "Delete Marks:\n"
		for _, v in pairs(del_list) do
			local dFile = v:gsub("/", "\\")
			delString = delString .. (dFile:match("\\*([^\\]*)$") or v) .. "; "
		end
		if delString:find(";") then
			mp.osd_message(delString)
			return delString
		elseif showListTimer then
			showListTimer:kill()
		end
	end

	local function list_marks()
		if showListTimer and showListTimer:is_enabled() then
			showListTimer:kill()
			mp.osd_message("", 0)
		else
			local s = showList()
			if s and s:find(";") then
				if not showListTimer then
					showListTimer = mp.add_periodic_timer(1, showList)
				end
				showListTimer:resume()
				print(s)
			else
				if showListTimer then
					showListTimer:kill()
				end
			end
		end
	end

	mp.add_key_binding("ctrl+DEL", "mega_delete_file_mark", mark_delete)
	mp.add_key_binding("alt+DEL", "mega_delete_file_list", list_marks)
	mp.add_key_binding("ctrl+shift+DEL", "mega_delete_file_clear", function()
		mp.osd_message("Undelete all")
		del_list = {}
	end)
	mp.register_event("shutdown", delete_marked)
end

----------------------------------------------------------------
-- 11) EDITIONS NOTIFICATION (çoklu edition varsa uyar & osd-playing-msg'i edition-list yap)
----------------------------------------------------------------
do
	local msg = require("mp.msg")

	local playingMessage = mp.get_property("options/osd-playing-msg") or "${media-title}"
	local editionSwitching = false
	local lastFilename = ""

	local function showNotification()
		local editions = mp.get_property_number("editions", 0)
		if editions < 2 then
			return
		end
		local t0 = mp.get_time()
		while mp.get_time() - t0 < 1 do
		end -- küçük gecikme
		mp.osd_message("File has " .. editions .. " editions", 2)
	end

	local function changedFile()
		msg.log("v", "switched file")
		editionSwitching = false
	end

	local function editionChanged()
		msg.log("v", "edition changed")
		editionSwitching = true
	end

	local function main()
		local edition = mp.get_property_number("current-edition")
		if lastFilename ~= (mp.get_property("filename") or "") then
			changedFile()
			lastFilename = mp.get_property("filename") or ""
			showNotification()
		end
		if editionSwitching == false or edition == nil then
			mp.set_property("options/osd-playing-msg", playingMessage)
		else
			mp.set_property("options/osd-playing-msg", "${edition-list}")
		end
	end

	mp.observe_property("current-edition", nil, editionChanged)
	mp.register_event("file-loaded", main)
end

----------------------------------------------------------------
-- 12) QUICK-SCALE (pencereyi hedef boyuta ölçekle)
--     script-message Quick_Scale "W" "H" "scale" "maxvideoscale"
--     Örnek: Alt+9 script-message Quick_Scale "1680" "1050" "0.8" "1.5"
----------------------------------------------------------------
do
	local mp = mp

	function quick_scale(targetwidth, targetheight, targetscale, maxvideoscale)
		-- Tam ekranda ise dokunma
		if mp.get_property_bool("fullscreen", false) then
			return nil
		end

		-- Parametre kontrol
		if targetwidth == nil or targetheight == nil or targetscale == nil or maxvideoscale == nil then
			mp.osd_message("Quick_Scale: Missing parameters")
			return nil
		end

		targetwidth = tonumber(targetwidth)
		targetheight = tonumber(targetheight)
		targetscale = tonumber(targetscale)
		maxvideoscale = tonumber(maxvideoscale)

		if not targetwidth or not targetheight or not targetscale or not maxvideoscale then
			mp.osd_message("Quick_Scale: Non-numeric parameters")
			return nil
		end

		-- Hedefi ölçekle
		if targetscale ~= 1 then
			targetwidth = targetwidth * targetscale
			targetheight = targetheight * targetscale
		end

		-- Videonun doğal boyutlarına göre gerekli pencere ölçeği
		local v_w = tonumber(mp.get_property("width")) or 0
		local v_h = tonumber(mp.get_property("height")) or 0
		if v_w <= 0 or v_h <= 0 then
			mp.osd_message("Quick_Scale: invalid video size")
			return nil
		end

		local widthscale = targetwidth / v_w
		local heightscale = targetheight / v_h
		local scale = (widthscale < heightscale) and widthscale or heightscale

		if maxvideoscale > 0 and scale > maxvideoscale then
			scale = maxvideoscale
		end

		mp.set_property_number("window-scale", scale)
	end

	mp.register_script_message("Quick_Scale", quick_scale)
end

----------------------------------------------------------------
-- 13) SEEK-TO (sayı tuşlarıyla timestamp girerek git + panodan yapıştır)
--     Toggle: script-binding toggle-seeker
--     Paste:  Ctrl+Alt+V (Windows PowerShell Get-Clipboard)
----------------------------------------------------------------
do
	local mp = mp
	local msg = require("mp.msg")
	local assdraw = require("mp.assdraw")
	local utils = require("mp.utils")

	local active = false
	local cursor_position = 1
	local time_scale = { 60 * 60 * 10, 60 * 60, 60 * 10, 60, 10, 1, 0.1, 0.01, 0.001 }

	local ass_begin = mp.get_property("osd-ass-cc/0")
	local ass_end = mp.get_property("osd-ass-cc/1")

	local history = { {} }
	for i = 1, 9 do
		history[1][i] = 0
	end
	local history_position = 1

	local timer = nil
	local timer_duration = 3

	local function show_seeker()
		local prepend_char = { "", "", ":", "", ":", "", ".", "", "" }
		local str = ""
		for i = 1, 9 do
			str = str .. prepend_char[i]
			if i == cursor_position then
				str = str .. "{\\b1}" .. history[history_position][i] .. "{\\r}"
			else
				str = str .. history[history_position][i]
			end
		end
		mp.osd_message("Seek to: " .. ass_begin .. str .. ass_end, timer_duration)
	end

	local function copy_history_to_last()
		if history_position ~= #history then
			for i = 1, 9 do
				history[#history][i] = history[history_position][i]
			end
			history_position = #history
		end
	end

	local function shift_cursor(left)
		if left then
			cursor_position = math.max(1, cursor_position - 1)
		else
			cursor_position = math.min(cursor_position + 1, 9)
		end
	end

	local function change_number(i)
		-- 60 limit
		if (cursor_position == 3 or cursor_position == 5) and i >= 6 then
			return
		end
		if history[history_position][cursor_position] ~= i then
			copy_history_to_last()
			history[#history][cursor_position] = i
		end
		shift_cursor(false)
	end

	local function current_time_as_sec(time)
		local sec = 0
		for i = 1, 9 do
			sec = sec + time_scale[i] * time[i]
		end
		return sec
	end

	local function time_equal(lhs, rhs)
		for i = 1, 9 do
			if lhs[i] ~= rhs[i] then
				return false
			end
		end
		return true
	end

	local function seek_to()
		copy_history_to_last()
		mp.commandv("osd-bar", "seek", current_time_as_sec(history[history_position]), "absolute")
		if #history == 1 or not time_equal(history[history_position], history[#history - 1]) then
			history[#history + 1] = {}
			history_position = #history
		end
		for i = 1, 9 do
			history[#history][i] = 0
		end
	end

	local function backspace()
		if history[history_position][cursor_position] ~= 0 then
			copy_history_to_last()
			history[#history][cursor_position] = 0
		end
		shift_cursor(true)
	end

	local function history_move(up)
		if up then
			history_position = math.max(1, history_position - 1)
		else
			history_position = math.min(history_position + 1, #history)
		end
	end

	local key_mappings = {
		LEFT = function()
			shift_cursor(true)
			show_seeker()
		end,
		RIGHT = function()
			shift_cursor(false)
			show_seeker()
		end,
		UP = function()
			history_move(true)
			show_seeker()
		end,
		DOWN = function()
			history_move(false)
			show_seeker()
		end,
		BS = function()
			backspace()
			show_seeker()
		end,
		ESC = function()
			set_inactive()
		end,
		ENTER = function()
			seek_to()
			set_inactive()
		end,
	}
	for i = 0, 9 do
		local func = function()
			change_number(i)
			show_seeker()
		end
		key_mappings[string.format("KP%d", i)] = func
		key_mappings[string.format("%d", i)] = func
	end

	function set_active()
		if not mp.get_property("seekable") then
			return
		end
		local duration = mp.get_property_number("duration")
		if duration ~= nil then
			for i = 1, 9 do
				if duration > time_scale[i] then
					cursor_position = i
					break
				end
			end
		end
		for key, func in pairs(key_mappings) do
			mp.add_forced_key_binding(key, "seek-to-" .. key, func)
		end
		show_seeker()
		timer = mp.add_periodic_timer(timer_duration, show_seeker)
		active = true
	end

	function set_inactive()
		mp.osd_message("")
		for key, _ in pairs(key_mappings) do
			mp.remove_key_binding("seek-to-" .. key)
		end
		if timer then
			timer:kill()
		end
		active = false
	end

	local function paste_timestamp()
		-- Windows PowerShell
		local clipboard = utils.subprocess({
			args = { "powershell", "-Command", "Get-Clipboard", "-Raw" },
			playback_only = false,
			capture_stdout = true,
			capture_stderr = true,
		})

		if clipboard and not clipboard.error then
			local timestamp = clipboard.stdout or ""
			local match = timestamp:match("%d?%d?:?%d%d:%d%d%.?%d*")
			if match ~= nil then
				mp.osd_message("Timestamp pasted: " .. match)
				mp.commandv("osd-bar", "seek", match, "absolute")
			end
		else
			msg.error("Clipboard read failed")
		end
	end

	mp.add_key_binding(nil, "toggle-seeker", function()
		if active then
			set_inactive()
		else
			set_active()
		end
	end)
	mp.add_key_binding("ctrl+alt+v", "paste-timestamp", paste_timestamp)
end
