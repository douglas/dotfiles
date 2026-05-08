import QtQuick
import Quickshell.Widgets
import "../../style" as Style

Item {
    id: root

    property var theme: ({})
    property var notification: null
    property bool critical: false
    property int size: 26
    property int imageSize: Math.max(14, size - 8)

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    function t(key, fallback) { return theme[key] || fallback }

    function _isDirectIconSource(icon) {
        const value = icon || ""
        return value.startsWith("/") ||
            value.startsWith("file:") ||
            value.startsWith("image:") ||
            value.startsWith("qrc:") ||
            value.startsWith("data:")
    }

    function _iconProviderSource(icon) {
        const value = icon || ""
        if (value === "")
            return ""
        if (value.startsWith("/"))
            return "file://" + value
        if (_isDirectIconSource(value))
            return value
        return "image://icon/" + encodeURIComponent(value)
    }

    function _appName() {
        return notification
            ? (notification.appName || notification.applicationName || notification.desktopEntry || "")
            : ""
    }

    function _fallbackGlyph() {
        const name = _appName().toLowerCase()
        const map = {
            "firefox": "󰈹", "chromium": "󰊯", "discord": "󰙯",
            "spotify": "󰓇", "telegram": "󰔁", "code": "󰨞",
            "vscode": "󰨞", "alacritty": "󰆍", "kitty": "󰆍",
            "ghostty": "󰆍", "terminal": "󰆍", "steam": "󰓓",
            "vlc": "󰕼", "mpv": "󰎁", "thunar": "󰉋",
            "nautilus": "󰉋", "codex": "󰚩", "calendar": "󰃭",
        }
        for (const [key, value] of Object.entries(map)) {
            if (name.includes(key))
                return value
        }
        return "󰂚"
    }

    readonly property string iconSource: _iconProviderSource(notification ? notification.appIcon : "")

    Rectangle {
        anchors.fill: parent
        radius: Math.round(root.size * 0.30)
        color: Qt.rgba(1, 1, 1, 0.055)
        border.color: root.critical
            ? Qt.alpha(root.t("red", "#f38ba8"), 0.42)
            : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
    }

    IconImage {
        id: iconImage
        anchors.centerIn: parent
        width: root.imageSize
        height: root.imageSize
        implicitSize: root.imageSize
        source: root.iconSource
        asynchronous: true
        mipmap: true
        visible: source !== "" && status !== Image.Error
    }

    Text {
        anchors.centerIn: parent
        text: root._fallbackGlyph()
        color: root.critical ? root.t("red", "#f38ba8") : root.t("accent", "#89b4fa")
        font.pixelSize: Math.max(12, Math.round(root.size * 0.56))
        font.family: Style.Typography.monoPropo
        visible: !iconImage.visible
    }

    Rectangle {
        width: Math.max(5, Math.round(root.size * 0.22))
        height: width
        radius: width / 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: root.critical ? root.t("red", "#f38ba8") : root.t("accent", "#89b4fa")
        border.color: root.t("bg", "#1e1e2e")
        border.width: 1
    }
}
