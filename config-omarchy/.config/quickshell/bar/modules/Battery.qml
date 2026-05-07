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
    readonly property bool hovered: batteryPill.hovered
    property string notice: ""
    property var processes: []
    property bool showPids: false
    signal opened()

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
    implicitWidth: hasLaptopBattery ? batteryPill.implicitWidth : 0
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

    function copyPid(proc) {
        if (!proc || !/^\d+$/.test(String(proc.pid || ""))) return
        Quickshell.execDetached(["bash", "-lc", "printf '%s' \"" + proc.pid + "\" | wl-copy"])
        notice = "Copied PID " + proc.pid
        noticeTimer.restart()
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

    StatPill {
        id: batteryPill
        anchors.centerIn: parent
        label: "BATT"
        value: root.percentage
        accent: root.cAccent
        trackColor: root.cDim
        textColor: root.cFg
        interactive: true
        onClicked: {
            if (root.showing) {
                root.showing = false
                return
            }
            root.showing = true
            root.opened()
        }
    }

    ProcessOverlay {
        showing: root.showing && root.hasLaptopBattery
        barOnBottom: root.barOnBottom
        overlayBarOffset: root.overlayBarOffset
        overlayScale: root.overlayScale
        namespaceName: "battery-impact"
        icon: root.iconForLevel()
        title: "Battery"
        subtitle: root.ready
            ? root.percentage + "% · " + root.stateLabel()
            : "Unavailable"
        notice: root.notice
        listTitle: "Processes"
        valueKey: "cpu"
        accent: root.cAccent
        processes: root.processes
        emptyText: impactProc.running ? "loading" : "no process data"
        theme: root.theme
        onCloseRequested: root.showing = false
        onRefreshRequested: root.refreshImpact()
        onPidCopied: proc => root.copyPid(proc)
        onKillRequested: proc => root.requestKill(proc)
    }
}
