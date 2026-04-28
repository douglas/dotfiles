import QtQuick
import Quickshell.Io

Item {
    id: root

    property var theme: ({})
    property string icon: "󰓄"
    property string statusClass: "off"
    property string tooltip: "KEF"
    property bool hovered: false

    implicitWidth: iconText.implicitWidth
    implicitHeight: 28

    function refresh() {
        statusProc.running = false
        statusProc.running = true
    }

    function runCmd(cmd, refreshAfter) {
        actionProc.command = ["bash", "-c", cmd]
        actionProc.refreshAfter = refreshAfter
        actionProc.running = true
    }

    Process {
        id: statusProc
        command: ["bash", "-c", "kefctl waybar 2>/dev/null || printf '%s\\n' '{\"alt\":\"off\",\"class\":\"off\",\"text\":\"󰓄\",\"tooltip\":\"KEF · Offline\"}'"]
        running: true
        stdout: SplitParser {
            property string buf: ""
            onRead: data => buf += data
        }
        onExited: {
            const raw = statusProc.stdout.buf.trim()
            statusProc.stdout.buf = ""

            try {
                const parsed = JSON.parse(raw)
                root.icon = parsed.text || (parsed.alt === "on" ? "󰓃" : "󰓄")
                root.statusClass = parsed.class || parsed.alt || "off"
                root.tooltip = parsed.tooltip || "KEF"
            } catch (e) {
                root.icon = "󰓄"
                root.statusClass = "off"
                root.tooltip = "KEF · Offline"
            }
        }
    }

    Process {
        id: actionProc
        property bool refreshAfter: false
        command: ["bash", "-c", ""]
        running: false
        onExited: if (refreshAfter) root.refresh()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        text: root.icon
        color: root.statusClass.indexOf("on") !== -1
            ? (root.theme.accent || "#89b4fa")
            : (root.theme.fg || "#cdd6f4")
        opacity: root.statusClass.indexOf("on") !== -1
            ? (root.hovered ? 1.0 : 0.95)
            : (root.hovered ? 0.75 : 0.4)
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: root.hovered
        opacity: root.hovered ? 1 : 0
        z: 99

        width: tooltipText.implicitWidth + 16
        height: 22
        radius: 6

        anchors.bottom: parent.top
        anchors.bottomMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter

        color: root.theme.bg || "#1e1e2e"
        border.color: root.theme.dim || "#45475a"
        border.width: 1

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.tooltip
            color: root.theme.fg || "#cdd6f4"
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.runCmd("setsid uwsm-app -- ghostty --class=org.omarchy.Kefctl --title=kefctl -e kefctl", false)
            } else {
                root.runCmd("kefctl toggle", true)
            }
        }
    }
}
