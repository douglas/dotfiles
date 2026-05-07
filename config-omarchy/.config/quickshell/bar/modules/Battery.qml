import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

Item {
    id: root

    property var theme: ({})
    property bool barOnBottom: false
    property int overlayBarOffset: 44
    property real overlayScale: 1.18
    property bool showing: false
    property bool hovered: false
    property string notice: ""
    property var processes: []

    readonly property var device: UPower.displayDevice
    readonly property bool ready: device && device.ready
    readonly property bool hasLaptopBattery: ready && device.isLaptopBattery && device.isPresent
    readonly property int percentage: ready ? Math.max(0, Math.min(100, Math.round(device.percentage * 100))) : 0
    readonly property bool charging: ready && device.state === UPowerDeviceState.Charging
    readonly property color cBg: theme.bg || "#1e1e2e"
    readonly property color cFg: theme.fg || "#cdd6f4"
    readonly property color cMuted: theme.muted || "#585b70"
    readonly property color cDim: theme.dim || "#45475a"
    readonly property color cAccent: theme.accent || "#89b4fa"
    readonly property color cYellow: "#f9e2af"
    readonly property color cRed: theme.red || "#f38ba8"

    visible: hasLaptopBattery
    enabled: hasLaptopBattery
    implicitWidth: hasLaptopBattery ? batteryIcon.implicitWidth : 0
    implicitHeight: hasLaptopBattery ? 28 : 0

    function overlayPx(value) {
        return Math.round(value * Math.max(1.0, overlayScale))
    }

    onHasLaptopBatteryChanged: if (!hasLaptopBattery) showing = false

    function iconForLevel() {
        if (!ready) return "󰂑"
        if (charging) return "󰂄"
        if (percentage <= 5) return "󰂎"
        if (percentage <= 10) return "󰁺"
        if (percentage <= 20) return "󰁻"
        if (percentage <= 30) return "󰁼"
        if (percentage <= 40) return "󰁽"
        if (percentage <= 50) return "󰁾"
        if (percentage <= 60) return "󰁿"
        if (percentage <= 70) return "󰂀"
        if (percentage <= 80) return "󰂁"
        if (percentage <= 90) return "󰂂"
        return "󰁹"
    }

    function levelColor() {
        if (!ready) return cMuted
        if (percentage <= 15) return cRed
        if (percentage <= 30) return cYellow
        return cFg
    }

    function stateLabel() {
        if (!ready) return "Battery unavailable"
        return UPowerDeviceState.toString(device.state)
    }

    function refreshImpact() {
        impactProc.running = false
        impactProc.running = true
    }

    function isProtectedProcess(proc) {
        if (!proc) return true
        const pid = Number(proc.pid || 0)
        const name = String(proc.name || "").toLowerCase()
        if (!Number.isFinite(pid) || pid <= 2) return true
        const protectedNames = [
            "quickshell", "hyprland", "systemd", "init", "dbus-daemon", "dbus-broker",
            "xwayland", "sddm", "greetd", "pipewire", "wireplumber", "networkmanager",
            "xdg-desktop-portal", "xdg-desktop-portal-hyprland"
        ]
        for (const protectedName of protectedNames) {
            if (name === protectedName || name.startsWith(protectedName)) return true
        }
        return false
    }

    function requestKill(proc) {
        if (!proc || isProtectedProcess(proc)) return
        killProc.kill(proc.pid)
        notice = "Sent SIGTERM to " + (proc.name || proc.pid)
        noticeTimer.restart()
        refreshAfterKill.restart()
    }

    onShowingChanged: if (showing) refreshImpact()

    Timer {
        id: noticeTimer
        interval: 2200
        repeat: false
        onTriggered: root.notice = ""
    }

    Timer {
        id: refreshAfterKill
        interval: 300
        repeat: false
        onTriggered: root.refreshImpact()
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.showing
        onTriggered: root.refreshImpact()
    }

    Process {
        id: impactProc
        command: ["bash", "-lc", "ps -eo pid=,comm=,%cpu=,%mem= --sort=-%cpu | head -n 64"]
        running: false
        stdout: SplitParser {
            property string buf: ""
            onRead: data => {
                const chunk = String(data)
                buf += chunk.indexOf("\n") >= 0 ? chunk : chunk + "\n"
            }
        }
        onExited: {
            const list = []
            const lines = (stdout.buf || "").split(/\r?\n/)
            stdout.buf = ""
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim()
                if (!line) continue
                const parts = line.split(/\s+/)
                if (parts.length < 4) continue
                const proc = {
                    pid: parts[0],
                    name: parts[1],
                    cpu: Number(parts[2]) || 0,
                    mem: Number(parts[3]) || 0
                }
                if (root.isProtectedProcess(proc)) continue
                list.push(proc)
                if (list.length >= 10) break
            }
            root.processes = list
        }
        onRunningChanged: if (running) stdout.buf = ""
    }

    Process {
        id: killProc
        property string targetPid: ""
        command: ["kill", "-TERM", targetPid]
        function kill(pid) {
            targetPid = String(pid || "").trim()
            if (!/^\d+$/.test(targetPid)) return
            running = false
            running = true
        }
    }

    Text {
        id: batteryIcon
        anchors.centerIn: parent
        text: root.iconForLevel()
        color: root.showing ? root.cAccent : root.levelColor()
        opacity: root.hovered || root.showing ? 1.0 : (root.percentage <= 30 ? 0.95 : 0.4)
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: root.hovered && !root.showing
        opacity: visible ? 1 : 0
        z: 99

        width: tooltipText.implicitWidth + 16
        height: 22
        radius: 6
        anchors.bottom: parent.top
        anchors.bottomMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter

        color: root.cBg
        border.color: root.cDim
        border.width: 1

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.ready ? (root.percentage + "% · " + root.stateLabel()) : root.stateLabel()
            color: root.cFg
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.showing = !root.showing
    }

    WlrLayershell {
        id: batteryPanel
        visible: root.showing && root.hasLaptopBattery
        color: "transparent"
        implicitWidth: root.overlayPx(390)
        implicitHeight: card.height + root.overlayBarOffset + 10
        anchors {
            top: !root.barOnBottom
            bottom: root.barOnBottom
            right: true
        }
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        namespace: "battery-impact"

        Rectangle {
            id: card
            width: root.overlayPx(370)
            height: root.overlayPx(356)
            x: parent.width - width - 10
            y: root.barOnBottom ? 10 : root.overlayBarOffset
            radius: 12
            color: root.cBg
            border.color: Qt.alpha(root.cDim, 0.8)
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.overlayPx(14)
                spacing: root.overlayPx(10)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: root.iconForLevel()
                        color: root.levelColor()
                        font.pixelSize: root.overlayPx(24)
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: root.ready ? root.percentage + "% battery" : "Battery unavailable"
                            color: root.cFg
                            font.pixelSize: root.overlayPx(14)
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.ready ? root.stateLabel() : "UPower is not reporting a display battery"
                            color: root.cMuted
                            font.pixelSize: root.overlayPx(10)
                            font.family: "JetBrainsMono Nerd Font Propo"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: ""
                        color: refreshHover.containsMouse ? root.cAccent : root.cMuted
                        font.pixelSize: root.overlayPx(13)
                        font.family: "JetBrainsMono Nerd Font"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: refreshHover
                            anchors.fill: parent
                            anchors.margins: -7
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshImpact()
                        }
                    }

                    Text {
                        text: "󰅖"
                        color: closeHover.containsMouse ? root.cRed : root.cMuted
                        font.pixelSize: root.overlayPx(13)
                        font.family: "JetBrainsMono Nerd Font"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            anchors.margins: -7
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showing = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(root.cDim, 0.55)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Top battery impact"
                        color: root.cFg
                        font.pixelSize: root.overlayPx(11)
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.notice !== ""
                        text: root.notice
                        color: root.cAccent
                        font.pixelSize: root.overlayPx(9)
                        font.family: "JetBrainsMono Nerd Font Propo"
                        elide: Text.ElideRight
                        Layout.maximumWidth: 180
                    }
                }

                ListView {
                    id: impactList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: root.processes

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: root.overlayPx(34)
                        radius: 8
                        color: rowHover.hovered ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(1, 1, 1, 0.022)
                        border.color: Qt.rgba(1, 1, 1, 0.045)
                        border.width: 1

                        HoverHandler { id: rowHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: modelData.name || "process"
                                color: root.cFg
                                font.pixelSize: root.overlayPx(11)
                                font.family: "JetBrainsMono Nerd Font Propo"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Number(modelData.cpu || 0).toFixed(1) + "%"
                                color: modelData.cpu >= 30 ? root.cRed : modelData.cpu >= 10 ? root.cYellow : root.cMuted
                                font.pixelSize: root.overlayPx(10)
                                font.family: "JetBrainsMono Nerd Font Propo"
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 48
                            }

                            Text {
                                text: String(modelData.pid || "")
                                color: root.cMuted
                                font.pixelSize: root.overlayPx(9)
                                font.family: "JetBrainsMono Nerd Font Propo"
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 48
                            }

                            Text {
                                text: "󰆴"
                                color: killHover.containsMouse ? root.cRed : root.cMuted
                                font.pixelSize: root.overlayPx(13)
                                font.family: "JetBrainsMono Nerd Font"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea {
                                    id: killHover
                                    anchors.fill: parent
                                    anchors.margins: -7
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.requestKill(modelData)
                                }
                            }
                        }
                    }
                }

                Item {
                    visible: root.processes.length === 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰂑"
                            color: root.cMuted
                            font.pixelSize: root.overlayPx(28)
                            font.family: "JetBrainsMono Nerd Font"
                            opacity: 0.55
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: impactProc.running ? "loading" : "no process data"
                            color: root.cMuted
                            font.pixelSize: root.overlayPx(11)
                            font.family: "JetBrainsMono Nerd Font Propo"
                            opacity: 0.65
                        }
                    }
                }
            }
        }
    }
}
