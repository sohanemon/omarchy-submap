import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.sohanemon.submap"

  // NOTE: Empty value signals the root keymap, so it also encodes the hidden state.
  property string submap: ""

  // INFO: Submap names are user config tokens arriving verbatim over IPC, and
  // the shared WidgetButton label runs Qt's default Text.AutoText. Any "<tag"
  // sequence in the name parses as rich text there, letting a crafted name
  // make the shell process fetch file:// resources. Stripping "<" makes Qt's
  // rich-text detector unable to fire, so the name renders verbatim.
  function plainName(name) {
    return String(name || "").replace(/</g, "")
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && String(event.name) === "submap") root.submap = String(event.data || "")
    }
  }

  // NOTE: The submap event fires only on changes, so ask once at start to survive a shell restart mid-submap.
  Process {
    id: initProc
    command: ["hyprctl", "submap"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var name = String(text).trim()
        if (name && name !== "default") root.submap = name
      }
    }
  }
  Component.onCompleted: initProc.running = true

  visible: root.submap !== ""
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // INFO: Uppercase flag reads as a mode label, not a raw config token.
    text: "--" + root.plainName(root.submap).toUpperCase() + "--"
    // NOTE: Urgent accent flags the active mode; the widget is not a click target.
    active: true
    interactive: false
    pressable: false
  }
}
