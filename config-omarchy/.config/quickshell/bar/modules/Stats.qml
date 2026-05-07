import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property var theme: ({})
    property bool barOnBottom: false
    property int overlayBarOffset: 44
    property real overlayScale: 1.18
    property bool quietMode: false
    property bool showing: false
    property string activeView: "cpu"
    property string notice: ""
    property var cpuProcesses: []
    property var memProcesses: []

    property real cpuVal: 0
    property real ramVal: 0
    signal opened()

    readonly property color cBg: theme.bg || "#1e1e2e"
    readonly property color cFg: theme.fg || "#cdd6f4"
    readonly property color cMuted: theme.muted || "#585b70"
    readonly property color cDim: theme.dim || "#45475a"
    readonly property color cAccent: theme.accent || "#89b4fa"
    readonly property color cRed: theme.red || "#f38ba8"
    readonly property color cYellow: theme.yellow || "#f9e2af"
    readonly property bool showingCpu: showing && activeView === "cpu"
    readonly property bool showingMem: showing && activeView === "mem"
    readonly property string panelTitle: activeView === "cpu" ? "Top CPU" : "Top Memory"
    readonly property string panelSubtitle: activeView === "cpu"
        ? "CPU " + Math.round(cpuVal) + "%"
        : "RAM " + Math.round(ramVal) + "%"
    readonly property string panelValueKey: activeView === "cpu" ? "cpu" : "mem"
    readonly property color panelAccent: cAccent
    readonly property var panelProcesses: activeView === "cpu" ? cpuProcesses : memProcesses
    readonly property string panelEmptyText: activeView === "cpu"
        ? (cpuProc.running ? "loading" : "no CPU data")
        : (memProc.running ? "loading" : "no memory data")

    implicitWidth: statsRow.implicitWidth
    implicitHeight: 28
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    function overlayPx(value) {
        return Math.round(value * Math.max(1.0, overlayScale))
    }

    function refreshStats() {
        statsProc.running = false
        statsProc.running = true
    }

    function refreshProcesses() {
        cpuProc.running = false
        memProc.running = false
        cpuProc.running = true
        memProc.running = true
    }

    function toggleView(view) {
        if (showing && activeView === view) {
            showing = false
            return
        }

        activeView = view
        showing = true
        opened()
        refreshProcesses()
    }

    function parseProcessLine(line) {
        const parts = line.trim().split(/\s+/)
        if (parts.length < 4) return null
        return {
            pid: parts[0],
            name: parts[1],
            cpu: Number(parts[2]) || 0,
            mem: Number(parts[3]) || 0
        }
    }

    function parseProcessList(text) {
        const list = []
        const lines = (text || "").split(/\r?\n/)
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line) continue
            const proc = parseProcessLine(line)
            if (isProtectedProcess(proc)) continue
            list.push(proc)
            if (list.length >= 10) break
        }
        return list
    }

    function isProtectedProcess(proc) {
        if (!proc) return true
        const pid = Number(proc.pid || 0)
        const name = String(proc.name || "").toLowerCase()
        if (!Number.isFinite(pid) || pid <= 2) return true
        const protectedNames = [
            "quickshell", "hyprland", "systemd", "init", "dbus-daemon", "dbus-broker",
            "xwayland", "sddm", "greetd", "pipewire", "wireplumber", "networkmanager",
            "xdg-desktop-portal", "xdg-desktop-portal-hyprland", "ps"
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

    onShowingChanged: if (showing) refreshProcesses()

    Row {
        id: statsRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        StatPill {
            label: "CPU"
            value: cpuVal
            accent: root.showingCpu
                ? root.cAccent
                : cpuVal > 85
                    ? root.cRed
                    : root.cAccent
            trackColor: root.cDim
            textColor: root.cFg
            interactive: true
            onClicked: root.toggleView("cpu")
        }

        StatPill {
            label: "RAM"
            value: ramVal
            accent: root.showingMem
                ? root.cAccent
                : ramVal > 85
                    ? root.cRed
                    : root.cAccent
            trackColor: root.cDim
            textColor: root.cFg
            interactive: true
            onClicked: root.toggleView("mem")
        }
    }

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
        onTriggered: root.refreshProcesses()
    }

    Timer {
        interval: 3000
        running: !quietMode
        repeat: true
        onTriggered: refreshStats()
    }

    Timer {
        interval: 3000
        running: root.showing && !quietMode
        repeat: true
        onTriggered: refreshProcesses()
    }

    onQuietModeChanged: if (!quietMode) {
        refreshStats()
        if (showing) refreshProcesses()
    }

    Process {
        id: statsProc
        command: ["bash", "-c", "printf '%s\n' \"$(cat /proc/stat | head -1)\"; free | awk '/^Mem/{printf \"%d\\n\",$3/$2*100}'"]
        property var last: null
        running: true
        stdout: SplitParser {
            property int lineNo: 0
            onRead: data => {
                const text = data.trim()
                if (!text) return

                if (lineNo === 0) {
                    const p = text.split(/\s+/).slice(1).map(Number)
                    if (statsProc.last) {
                        const idle  = p[3] - statsProc.last[3]
                        const total = p.reduce((a, b) => a + b, 0) - statsProc.last.reduce((a, b) => a + b, 0)
                        cpuVal = total > 0 ? Math.round((1 - idle / total) * 100) : cpuVal
                    }
                    statsProc.last = p
                } else {
                    ramVal = parseInt(text) || 0
                }
                lineNo++
            }
        }
        onExited: statsProc.stdout.lineNo = 0
    }

    Process {
        id: cpuProc
        command: ["ps", "-eo", "pid=,comm=,%cpu=,%mem=", "--sort=-%cpu", "--no-headers"]
        running: false
        stdout: SplitParser {
            property string buf: ""
            onRead: data => {
                const chunk = String(data)
                buf += chunk.indexOf("\n") >= 0 ? chunk : chunk + "\n"
            }
        }
        onExited: {
            root.cpuProcesses = root.parseProcessList(stdout.buf)
            stdout.buf = ""
        }
        onRunningChanged: if (running) stdout.buf = ""
    }

    Process {
        id: memProc
        command: ["ps", "-eo", "pid=,comm=,%cpu=,%mem=", "--sort=-%mem", "--no-headers"]
        running: false
        stdout: SplitParser {
            property string buf: ""
            onRead: data => {
                const chunk = String(data)
                buf += chunk.indexOf("\n") >= 0 ? chunk : chunk + "\n"
            }
        }
        onExited: {
            root.memProcesses = root.parseProcessList(stdout.buf)
            stdout.buf = ""
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

    ProcessOverlay {
        showing: root.showing
        barOnBottom: root.barOnBottom
        overlayBarOffset: root.overlayBarOffset
        overlayScale: root.overlayScale
        namespaceName: "stats-impact"
        icon: "󰍛"
        title: root.panelTitle
        subtitle: root.panelSubtitle
        notice: root.notice
        listTitle: "Processes"
        valueKey: root.panelValueKey
        accent: root.panelAccent
        processes: root.panelProcesses
        emptyText: root.panelEmptyText
        theme: root.theme
        onCloseRequested: root.showing = false
        onRefreshRequested: root.refreshProcesses()
        onPidCopied: proc => root.copyPid(proc)
        onKillRequested: proc => root.requestKill(proc)
    }
}
