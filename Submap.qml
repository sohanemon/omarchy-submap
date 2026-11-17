import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.sohanemon.submap"

  // NOTE: Empty value signals the root keymap, so it also encodes the hidden state.
  property string submap: ""

  // INFO: Submap names arrive as user config tokens over IPC. Keep markup
  // delimiters out of the displayed label even though it uses plain text.
  function plainName(name) {
    return String(name || "").replace(/</g, "")
  }

  function relativeLuminance(color) {
    function linear(channel) {
      return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4)
    }

    return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b)
  }

  function contrastRatio(first, second) {
    var firstLuminance = relativeLuminance(first)
    var secondLuminance = relativeLuminance(second)
    var lighter = Math.max(firstLuminance, secondLuminance)
    var darker = Math.min(firstLuminance, secondLuminance)
    return (lighter + 0.05) / (darker + 0.05)
  }

  function bestTextColor(surface) {
    var candidates = [Commons.Color.bar.text, Commons.Color.foreground, Commons.Color.background]
    var best = candidates[0]
    var bestContrast = contrastRatio(best, surface)
    for (var i = 1; i < candidates.length; i++) {
      var candidateContrast = contrastRatio(candidates[i], surface)
      if (candidateContrast > bestContrast) {
        best = candidates[i]
        bestContrast = candidateContrast
      }
    }
    return best
  }

  function bestTextContrast(surface) {
    return contrastRatio(bestTextColor(surface), surface)
  }

  function badgeSurface() {
    var base = Commons.Color.accent
    if (bestTextContrast(base) >= 4.5) return base

    for (var factor = 1.15; factor <= 3.0; factor += 0.15) {
      var darker = Qt.darker(base, factor)
      if (bestTextContrast(darker) >= 4.5) return darker

      var lighter = Qt.lighter(base, factor)
      if (bestTextContrast(lighter) >= 4.5) return lighter
    }

    return base
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
  implicitWidth: visible ? label.implicitWidth + dot.width + Style.space(16) : 0
  implicitHeight: root.bar && !root.bar.vertical ? root.bar.barSize : badgeHeight

  readonly property real badgeHeight: Math.min(Style.bar.statusSlot, Style.bar.iconCanvas)

  readonly property color badgeBackground: badgeSurface()
  readonly property color badgeForeground: bestTextColor(badgeBackground)

  Rectangle {
    id: badge
    width: parent.width
    height: root.badgeHeight
    anchors.verticalCenter: parent.verticalCenter
    radius: Math.max(Style.space(2), Math.min(Style.cornerRadius, Style.space(6)))
    color: root.badgeBackground

    Row {
      anchors.centerIn: parent
      spacing: Style.space(4)

      Rectangle {
        id: dot
        width: Style.space(4)
        height: width
        radius: width / 2
        color: root.badgeForeground
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: label
        textFormat: Text.PlainText
        text: root.plainName(root.submap).toUpperCase()
        color: root.badgeForeground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.weight: Font.DemiBold
        font.letterSpacing: Style.space(0.25)
        renderType: Text.NativeRendering
        verticalAlignment: Text.AlignVCenter
      }
    }
  }
}
