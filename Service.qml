import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "ScreenOffModel.js" as ScreenOffModel

// Blanks the displays after idle. The stock idle service still owns the
// screensaver and the lock. This service does not write shell.json; timeout
// is read from this plugin's entry and falls back to the manifest default.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string shellConfigPath: home + "/.config/omarchy/shell.json"
  readonly property string stayAwakeStateDir: home + "/.local/state/omarchy/indicators"
  readonly property string pluginId: manifest && manifest.id ? manifest.id : "xolghadr.screen-off"

  property int timeoutSeconds: defaultTimeout()
  property bool fileStayAwake: false
  property bool fileStayAwakeLoaded: false
  property bool blanked: false
  property string lastEvent: "starting"
  property string lastEventAt: ""

  readonly property bool idleEnabled: fileStayAwakeLoaded && !fileStayAwake && timeoutSeconds > 0

  function defaultTimeout() {
    var defaults = root.manifest && root.manifest.settings
      ? root.manifest.settings.defaults : null
    return ScreenOffModel.timeoutSeconds(defaults ? defaults.timeout : undefined, 240)
  }

  function logEvent(event) {
    root.lastEventAt = new Date().toISOString()
    root.lastEvent = event
    console.log("omarchy screen-off " + root.lastEventAt + " " + event)
  }

  function applyShellText(text) {
    try {
      var config = JSON.parse(String(text || ""))
      var next = ScreenOffModel.configuredTimeout(config, root.pluginId, root.defaultTimeout())
      if (next === root.timeoutSeconds) return
      root.timeoutSeconds = next
      root.logEvent("timeout " + next)
    } catch (error) {
      root.logEvent("config-parse-failed")
    }
  }

  function blank() {
    if (blankProcess.running) return
    root.blanked = true
    root.logEvent("blank")
    blankProcess.running = true
  }

  function wake(reason) {
    if (!root.blanked) return
    root.blanked = false
    if (wakeProcess.running) return
    root.logEvent("wake " + (reason || "activity"))
    wakeProcess.running = true
  }

  function handleIdleChanged() {
    if (!root.idleEnabled) return
    root.logEvent(idleMonitor.isIdle ? "idle" : "active")
    if (idleMonitor.isIdle) root.blank()
    else root.wake("activity")
  }

  function applyStayAwake(value, reason) {
    var enabled = !!value
    var changed = !root.fileStayAwakeLoaded || root.fileStayAwake !== enabled
    root.fileStayAwake = enabled
    root.fileStayAwakeLoaded = true
    if (!changed) return
    root.logEvent("stay-awake " + (enabled ? "enabled" : "disabled") + (reason ? " " + reason : ""))
    if (enabled) root.wake("stay-awake")
    else Qt.callLater(root.handleIdleChanged)
  }

  onIdleEnabledChanged: if (!idleEnabled) wake("disabled")
  onManifestChanged: shellConfigFile.reload()

  IdleMonitor {
    id: idleMonitor
    enabled: root.idleEnabled
    timeout: Math.max(1, root.timeoutSeconds)
    respectInhibitors: true
    onIsIdleChanged: root.handleIdleChanged()
  }

  Process {
    id: blankProcess
    command: ["bash", "-lc", "omarchy-brightness-keyboard off >/dev/null 2>&1 || true; omarchy-brightness-display off"]
  }

  Process {
    id: wakeProcess
    command: ["bash", "-lc", "omarchy-system-wake"]
  }

  Process {
    id: stayAwakeStateProbe
    command: ["bash", "-c", "if [[ -f $HOME/.local/state/omarchy/indicators/stay-awake ]]; then echo yes; else echo no; fi"]
    stdout: SplitParser {
      onRead: function(line) { root.applyStayAwake(String(line).trim() === "yes", "state-file") }
    }
  }

  FileView {
    id: stayAwakeStateDirWatcher
    path: root.stayAwakeStateDir
    watchChanges: true
    printErrors: false
    onFileChanged: if (!stayAwakeStateProbe.running) stayAwakeStateProbe.running = true
  }

  FileView {
    id: shellConfigFile
    path: root.shellConfigPath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyShellText(text())
    onFileChanged: reload()
  }

  Component.onCompleted: {
    root.logEvent("service-ready")
    stayAwakeStateProbe.running = true
  }

  IpcHandler {
    target: "screen-off"

    function status(): string {
      return JSON.stringify({
        enabled: root.idleEnabled,
        stayAwake: root.fileStayAwake,
        timeout: root.timeoutSeconds,
        blanked: root.blanked,
        idle: idleMonitor.isIdle,
        lastEvent: root.lastEvent,
        lastEventAt: root.lastEventAt
      })
    }
  }
}
