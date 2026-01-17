import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

const BUS_NAME = 'org.kenan.GnomeNiriParity';
const OBJECT_PATH = '/org/kenan/GnomeNiriParity';
const IFACE_NAME = 'org.kenan.GnomeNiriParity';

const DBUS_IFACE_XML = `
<node>
  <interface name="${IFACE_NAME}">
    <method name="Ping">
      <arg name="reply" type="s" direction="out"/>
    </method>

    <method name="ColumnWidthCycle">
      <arg name="reply" type="s" direction="out"/>
    </method>
    <method name="ColumnWidthSet">
      <arg name="ratio" type="d" direction="in"/>
      <arg name="reply" type="s" direction="out"/>
    </method>
    <method name="ColumnWidthToggle">
      <arg name="a" type="d" direction="in"/>
      <arg name="b" type="d" direction="in"/>
      <arg name="reply" type="s" direction="out"/>
    </method>

    <method name="MoveHere">
      <arg name="target" type="s" direction="in"/>
      <arg name="reply" type="s" direction="out"/>
    </method>
    <method name="MoveHerePid">
      <arg name="pid" type="u" direction="in"/>
      <arg name="reply" type="s" direction="out"/>
    </method>

    <method name="Go">
      <arg name="reply" type="s" direction="out"/>
    </method>
  </interface>
</node>
`;

const GO_RULES = [
  ['Kenp', 1],
  ['TmuxKenp', 2],
  ['Ai', 3],
  ['CompecTA', 4],
  ['WebCord', 5],
  ['discord', 5],
  ['audacious', 5],
  ['org.telegram.desktop', 6],
  ['vlc', 6],
  ['remote-viewer', 6],
  ['transmission', 7],
  ['org.keepassxc.KeePassXC', 7],
  ['brave-youtube.com__-Default', 7],
  ['spotify', 8],
  ['ferdium', 9],
  ['com.rtosta.zapzap', 9],
  ['whatsie', 9],
];

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

function bytesToString(bytes) {
  if (!bytes)
    return '';

  try {
    if (typeof TextDecoder !== 'undefined')
      return (new TextDecoder('utf-8')).decode(bytes);
  } catch {}

  try {
    // gjs 1.7x: ByteArray helper
    const ByteArray = imports.byteArray;
    if (ByteArray && typeof ByteArray.toString === 'function')
      return ByteArray.toString(bytes);
  } catch {}

  try {
    let s = '';
    for (let i = 0; i < bytes.length; i++)
      s += String.fromCharCode(bytes[i]);
    return s;
  } catch {}

  return '';
}

export default class GnomeNiriParity extends Extension {
  enable() {
    this._cmdCache = new Map();

    this._dbusImpl = Gio.DBusExportedObject.wrapJSObject(DBUS_IFACE_XML, this);
    this._dbusImpl.export(Gio.DBus.session, OBJECT_PATH);

    this._busOwnerId = Gio.bus_own_name(
      Gio.BusType.SESSION,
      BUS_NAME,
      Gio.BusNameOwnerFlags.NONE,
      () => {},
      () => {},
      () => {},
    );
  }

  disable() {
    if (this._busOwnerId) {
      Gio.bus_unown_name(this._busOwnerId);
      this._busOwnerId = 0;
    }
    if (this._dbusImpl) {
      this._dbusImpl.unexport();
      this._dbusImpl = null;
    }
    this._cmdCache = null;
  }

  Ping() {
    return 'pong';
  }

  ColumnWidthCycle() {
    return this._columnWidth('cycle', null, 0.8, 1.0);
  }

  ColumnWidthSet(ratio) {
    return this._columnWidth('set', ratio, 0.8, 1.0);
  }

  ColumnWidthToggle(a, b) {
    return this._columnWidth('toggle', null, a, b);
  }

  MoveHere(target) {
    return this._moveHere(target);
  }

  MoveHerePid(pid) {
    return this._moveHerePid(pid);
  }

  Go() {
    return this._go();
  }

  _windows() {
    try {
      return global.get_window_actors().map(a => a.meta_window).filter(w => w);
    } catch {
      return [];
    }
  }

  _norm(s) {
    return (s ?? '').toString();
  }

  _eqi(a, b) {
    return this._norm(a).toLowerCase() === this._norm(b).toLowerCase();
  }

  _pidOf(w) {
    try {
      return w.get_pid ? (w.get_pid() || 0) : 0;
    } catch {
      return 0;
    }
  }

  _cmdlineForPid(pid) {
    const key = pid.toString();
    if (this._cmdCache?.has(key))
      return this._cmdCache.get(key);

    let cmd = '';
    try {
      const [ok, bytes] = GLib.file_get_contents(`/proc/${key}/cmdline`);
      if (ok && bytes)
        cmd = bytesToString(bytes).replace(/\0/g, ' ');
    } catch {}

    this._cmdCache?.set(key, cmd);
    return cmd;
  }

  _cmdlineMatchesTarget(w, target) {
    const pid = this._pidOf(w);
    if (!pid)
      return false;

    const cmd = this._cmdlineForPid(pid).toLowerCase();
    if (!cmd)
      return false;

    const t = target.toLowerCase();
    const home = GLib.get_home_dir().toLowerCase();
    const isolated = `${home}/.brave/isolated/${t}`;

    if (t.length >= 4) {
      const tokens = cmd.split(/\s+/).filter(s => s && s.length);
      for (const tok of tokens) {
        if (tok === t)
          return true;
        if (tok.endsWith(`/${t}`))
          return true;
      }
    }

    return (
      cmd.includes(`--class=${t}`) ||
      cmd.includes(`--class ${t}`) ||
      cmd.includes(`--name=${t}`) ||
      cmd.includes(`--name ${t}`) ||
      cmd.includes(`--user-data-dir=${isolated}`) ||
      cmd.includes(`--user-data-dir ${isolated}`)
    );
  }

  _propsForWindow(tracker, w) {
    let cls = '';
    let inst = '';
    let appId = '';
    try { cls = w.get_wm_class ? (w.get_wm_class() || '') : ''; } catch {}
    try { inst = w.get_wm_class_instance ? (w.get_wm_class_instance() || '') : ''; } catch {}
    try {
      const app = tracker.get_window_app(w);
      appId = app ? (app.get_id() || '') : '';
    } catch {}
    return { cls, inst, appId };
  }

  _matchesTarget(tracker, w, target) {
    const targetDesktop = target.endsWith('.desktop') ? target : `${target}.desktop`;
    const p = this._propsForWindow(tracker, w);
    return (
      this._eqi(p.cls, target) ||
      this._eqi(p.inst, target) ||
      this._eqi(p.appId, target) ||
      this._eqi(p.appId, targetDesktop) ||
      this._cmdlineMatchesTarget(w, target)
    );
  }

  _activateHere(w) {
    const activeWs = global.workspace_manager.get_active_workspace();

    try {
      const ws = w.get_workspace ? w.get_workspace() : null;
      if (ws && ws !== activeWs && w.change_workspace)
        w.change_workspace(activeWs);
    } catch {}

    try {
      if (w.minimized && w.unminimize)
        w.unminimize();
    } catch {}

    try {
      if (w.activate)
        w.activate(global.get_current_time());
    } catch {}
  }

  _moveHerePid(pidRaw) {
    const wantPid = Number(pidRaw);
    if (!wantPid || Number.isNaN(wantPid))
      return '__GNOME_SET_BAD_PID__';

    const wins = this._windows();
    const activeWs = global.workspace_manager.get_active_workspace();

    const win =
      wins.find(w => this._pidOf(w) === wantPid && w.get_workspace && w.get_workspace() === activeWs) ||
      wins.find(w => this._pidOf(w) === wantPid);

    if (!win)
      return '__GNOME_SET_NOT_FOUND__';

    this._activateHere(win);
    return '__GNOME_SET_OK__';
  }

  _moveHere(targetRaw) {
    const target = this._norm(targetRaw);
    if (!target)
      return '__GNOME_SET_NOT_FOUND__';

    const tracker = Shell.WindowTracker.get_default();
    const wins = this._windows();
    const activeWs = global.workspace_manager.get_active_workspace();

    const win =
      wins.find(w => this._matchesTarget(tracker, w, target) && w.get_workspace && w.get_workspace() === activeWs) ||
      wins.find(w => this._matchesTarget(tracker, w, target));

    if (!win)
      return '__GNOME_SET_NOT_FOUND__';

    this._activateHere(win);
    return '__GNOME_SET_OK__';
  }

  _go() {
    const tracker = Shell.WindowTracker.get_default();
    const wins = this._windows();
    const wm = global.workspace_manager;

    for (const [target, wsNum] of GO_RULES) {
      const wsIdx = Math.max(0, Number(wsNum) - 1);
      const ws = wm.get_workspace_by_index(wsIdx);
      if (!ws)
        continue;

      for (const w of wins) {
        if (!this._matchesTarget(tracker, w, target))
          continue;
        try {
          if (w.change_workspace)
            w.change_workspace(ws);
        } catch {}
      }
    }

    try {
      wm.get_workspace_by_index(0).activate(global.get_current_time());
    } catch {}

    try {
      this._moveHere('Kenp');
    } catch {}

    return 'ok';
  }

  _columnWidth(action, setRatio, toggleA, toggleB) {
    const presets = [0.30, 0.45, 0.60, 0.75, 1.0];
    const preferred = 0.8;

    const win = global.display.get_focus_window();
    if (!win)
      return 'no-window';

    const monitor = win.get_monitor();
    const wa = Main.layoutManager.getWorkAreaForMonitor(monitor);
    const rect = win.get_frame_rect();

    let ratio = preferred;
    if (action === 'set' && typeof setRatio === 'number' && setRatio > 0 && setRatio <= 1.0) {
      ratio = setRatio;
    } else if (action === 'toggle' && typeof toggleA === 'number' && typeof toggleB === 'number') {
      const current = rect.width / wa.width;
      const eps = 0.05;
      ratio = (Math.abs(current - toggleA) <= eps) ? toggleB : toggleA;
    } else {
      const current = rect.width / wa.width;
      let closest = 0;
      let best = 1e9;
      for (let i = 0; i < presets.length; i++) {
        const d = Math.abs(current - presets[i]);
        if (d < best) {
          best = d;
          closest = i;
        }
      }
      ratio = presets[(closest + 1) % presets.length];
    }

    const newW = Math.round(wa.width * ratio);
    const newH = rect.height;
    const newX = wa.x + Math.round((wa.width - newW) / 2);
    const newY = clamp(rect.y, wa.y, wa.y + Math.max(0, wa.height - newH));

    try {
      win.unmaximize(Meta.MaximizeFlags.BOTH);
    } catch {}

    try {
      win.move_resize_frame(true, newX, newY, newW, newH);
      if (win.activate)
        win.activate(global.get_current_time());
      return `ok:${ratio.toString()}`;
    } catch (e) {
      return `error:${e.toString()}`;
    }
  }
}

