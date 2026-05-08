import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property var theme: ({
    })
    property bool barOnBottom: false
    property int overlayBarOffset: 44
    property real overlayScale: 1.18
    property bool quietMode: false
    property bool showing: false
    property string activeView: "cpu"
    property string notice: ""
    property var cpuProcesses: []
    property var memProcesses: []
    property var cpuProcessTree: []
    property var memProcessTree: []
    property bool cpuProcessesLoaded: false
    property bool memProcessesLoaded: false
    property bool cpuProcessesFirstLoading: false
    property bool memProcessesFirstLoading: false
    property real cpuVal: 0
    property real ramVal: 0
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
    readonly property string panelSubtitle: activeView === "cpu" ? "CPU " + Math.round(cpuVal) + "%" : "RAM " + Math.round(ramVal) + "%"
    readonly property string panelValueKey: activeView === "cpu" ? "cpu" : "mem"
    readonly property color panelAccent: cAccent
    readonly property var panelProcesses: activeView === "cpu" ? cpuProcesses : memProcesses
    readonly property var panelProcessTree: activeView === "cpu" ? cpuProcessTree : memProcessTree
    readonly property bool panelLoading: activeView === "cpu" ? cpuProcessesFirstLoading : memProcessesFirstLoading
    readonly property string panelEmptyText: activeView === "cpu" ? "no CPU data" : "no memory data"
    readonly property string processTreeScript: (Quickshell.env("HOME") || "") + "/.config/quickshell/scripts/quickshell-process-tree"

    signal opened()

    function overlayPx(value) {
        return Math.round(value * Math.max(1, overlayScale));
    }

    function refreshStats() {
        statsProc.running = false;
        statsProc.running = true;
    }

    function startProcessRefresh() {
        cpuProc.running = false;
        memProc.running = false;
        cpuProc.running = true;
        memProc.running = true;
    }

    function refreshProcesses(forceLoading) {
        const showLoading = forceLoading === true;
        if (showLoading || !cpuProcessesLoaded) {
            cpuProcessesFirstLoading = true;
            cpuFirstLoadingGate.restart();
        }
        if (showLoading || !memProcessesLoaded) {
            memProcessesFirstLoading = true;
            memFirstLoadingGate.restart();
        }
        processRefreshDelay.restart();
    }

    function toggleView(view) {
        if (showing && activeView === view) {
            showing = false;
            return ;
        }
        activeView = view;
        opened();
        refreshProcesses();
        showing = true;
    }

    function parseProcessLine(line) {
        const parts = line.trim().split(/\s+/);
        if (parts.length < 4)
            return null;

        return {
            "pid": parts[0],
            "name": parts[1],
            "cpu": Number(parts[2]) || 0,
            "mem": Number(parts[3]) || 0
        };
    }

    function parseProcessList(text) {
        const list = [];
        const lines = (text || "").split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line)
                continue;

            const proc = parseProcessLine(line);
            if (isProtectedProcess(proc))
                continue;

            list.push(proc);
            if (list.length >= 10)
                break;

        }
        return list;
    }

    function processCountLabel(count) {
        return count + " proc" + (count === 1 ? "" : "s");
    }

    function shortContainerName(name, id) {
        let display = String(name || id || "");
        display = display.replace(/^[a-z0-9-]+-compose_/, "");
        display = display.replace(/_[0-9]+$/, "");
        return display || String(id || "container");
    }

    function parseProcessTree(text) {
        const systemRows = [];
        const containers = ({
        });
        const containerOrder = [];
        let systemCpu = 0;
        let systemMem = 0;
        let dockerCpu = 0;
        let dockerMem = 0;
        let dockerCount = 0;
        const lines = (text || "").split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (!line)
                continue;

            const parts = line.split("\t");
            if (parts.length < 8 || parts[0] !== "proc")
                continue;

            const proc = {
                "pid": parts[1],
                "ppid": parts[2],
                "name": parts[3],
                "cpu": Number(parts[4]) || 0,
                "mem": Number(parts[5]) || 0,
                "containerId": parts[6],
                "containerName": parts[7]
            };
            if (isProtectedProcess(proc))
                continue;

            if (proc.containerId !== "") {
                const key = "docker:" + (proc.containerName || proc.containerId);
                if (!containers[key]) {
                    const fullTitle = proc.containerName || proc.containerId;
                    containers[key] = {
                        "key": key,
                        "rowType": "container",
                        "title": shortContainerName(fullTitle, proc.containerId),
                        "fullTitle": fullTitle,
                        "rows": [],
                        "cpu": 0,
                        "mem": 0,
                        "count": 0
                    };
                    containerOrder.push(key);
                }
                containers[key].rows.push(proc);
                containers[key].cpu += proc.cpu;
                containers[key].mem += proc.mem;
                containers[key].count += 1;
                dockerCpu += proc.cpu;
                dockerMem += proc.mem;
                dockerCount += 1;
            } else {
                systemRows.push(proc);
                systemCpu += proc.cpu;
                systemMem += proc.mem;
            }
        }
        const groups = [{
            "key": "system",
            "rowType": "group",
            "title": "System",
            "subtitle": processCountLabel(systemRows.length),
            "rows": systemRows,
            "cpu": systemCpu,
            "mem": systemMem
        }];
        if (containerOrder.length > 0) {
            const children = [];
            for (const key of containerOrder) {
                const container = containers[key];
                container.subtitle = processCountLabel(container.count);
                children.push(container);
            }
            groups.push({
                "key": "docker",
                "rowType": "group",
                "title": "Docker",
                "subtitle": containerOrder.length + " containers",
                "children": children,
                "cpu": dockerCpu,
                "mem": dockerMem,
                "count": dockerCount
            });
        }
        return groups;
    }

    function isProtectedProcess(proc) {
        if (!proc)
            return true;

        const pid = Number(proc.pid || 0);
        const name = String(proc.name || "").toLowerCase();
        if (!Number.isFinite(pid) || pid <= 2)
            return true;

        const protectedNames = ["quickshell", "qs", "hyprland", "systemd", "init", "dbus-daemon", "dbus-broker", "xwayland", "sddm", "greetd", "pipewire", "wireplumber", "networkmanager", "xdg-desktop-portal", "xdg-desktop-portal-hyprland", "ps"];
        for (const protectedName of protectedNames) {
            if (name === protectedName || name.startsWith(protectedName))
                return true;

        }
        return false;
    }

    function requestKill(proc) {
        if (!proc || isProtectedProcess(proc))
            return ;

        killProc.kill(proc.pid);
        notice = "Sent SIGTERM to " + (proc.name || proc.pid);
        noticeTimer.restart();
        refreshAfterKill.restart();
    }

    function copyPid(proc) {
        if (!proc || !/^\d+$/.test(String(proc.pid || "")))
            return ;

        Quickshell.execDetached(["bash", "-lc", "printf '%s' \"" + proc.pid + "\" | wl-copy"]);
        notice = "Copied PID " + proc.pid;
        noticeTimer.restart();
    }

    function copyBranch(branch) {
        const fullTitle = String(branch.fullTitle || branch.title || "");
        if (fullTitle === "")
            return ;

        Quickshell.execDetached(["wl-copy", fullTitle]);
        notice = "Copied " + fullTitle;
        noticeTimer.restart();
    }

    implicitWidth: statsRow.implicitWidth
    implicitHeight: 28
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    onShowingChanged: {
        if (showing)
            refreshProcesses();

    }
    onQuietModeChanged: {
        if (!quietMode) {
            refreshStats();
            if (showing)
                refreshProcesses();

        }
    }

    Row {
        id: statsRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        StatPill {
            label: "CPU"
            value: cpuVal
            accent: root.showingCpu ? root.cAccent : cpuVal > 85 ? root.cRed : root.cAccent
            trackColor: root.cDim
            textColor: root.cFg
            interactive: true
            onClicked: root.toggleView("cpu")
        }

        StatPill {
            label: "RAM"
            value: ramVal
            accent: root.showingMem ? root.cAccent : ramVal > 85 ? root.cRed : root.cAccent
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

    Timer {
        id: processRefreshDelay

        interval: 60
        repeat: false
        onTriggered: root.startProcessRefresh()
    }

    Process {
        id: statsProc

        property var last: null

        command: ["bash", "-c", "printf '%s\n' \"$(cat /proc/stat | head -1)\"; free | awk '/^Mem/{printf \"%d\\n\",$3/$2*100}'"]
        running: true
        onExited: statsProc.stdout.lineNo = 0

        stdout: SplitParser {
            property int lineNo: 0

            onRead: (data) => {
                const text = data.trim();
                if (!text)
                    return ;

                if (lineNo === 0) {
                    const p = text.split(/\s+/).slice(1).map(Number);
                    if (statsProc.last) {
                        const idle = p[3] - statsProc.last[3];
                        const total = p.reduce((a, b) => {
                            return a + b;
                        }, 0) - statsProc.last.reduce((a, b) => {
                            return a + b;
                        }, 0);
                        cpuVal = total > 0 ? Math.round((1 - idle / total) * 100) : cpuVal;
                    }
                    statsProc.last = p;
                } else {
                    ramVal = parseInt(text) || 0;
                }
                lineNo++;
            }
        }

    }

    Process {
        id: cpuProc

        command: ["bash", root.processTreeScript, "cpu"]
        running: false
        onExited: {
            root.cpuProcessTree = root.parseProcessTree(stdout.buf);
            root.cpuProcessesLoaded = true;
            if (!cpuFirstLoadingGate.running)
                root.cpuProcessesFirstLoading = false;

            stdout.buf = "";
        }
        onRunningChanged: {
            if (running)
                stdout.buf = "";

        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                const chunk = String(data);
                buf += chunk.indexOf("\n") >= 0 ? chunk : chunk + "\n";
            }
        }

    }

    Process {
        id: memProc

        command: ["bash", root.processTreeScript, "mem"]
        running: false
        onExited: {
            root.memProcessTree = root.parseProcessTree(stdout.buf);
            root.memProcessesLoaded = true;
            if (!memFirstLoadingGate.running)
                root.memProcessesFirstLoading = false;

            stdout.buf = "";
        }
        onRunningChanged: {
            if (running)
                stdout.buf = "";

        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                const chunk = String(data);
                buf += chunk.indexOf("\n") >= 0 ? chunk : chunk + "\n";
            }
        }

    }

    Process {
        id: killProc

        property string targetPid: ""

        function kill(pid) {
            targetPid = String(pid || "").trim();
            if (!/^\d+$/.test(targetPid))
                return ;

            running = false;
            running = true;
        }

        command: ["kill", "-TERM", targetPid]
    }

    Timer {
        id: cpuFirstLoadingGate

        interval: 350
        repeat: false
        onTriggered: {
            if (root.cpuProcessesLoaded)
                root.cpuProcessesFirstLoading = false;

        }
    }

    Timer {
        id: memFirstLoadingGate

        interval: 350
        repeat: false
        onTriggered: {
            if (root.memProcessesLoaded)
                root.memProcessesFirstLoading = false;

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
        treeGroups: root.panelProcessTree
        emptyText: root.panelEmptyText
        loading: root.panelLoading
        theme: root.theme
        onCloseRequested: root.showing = false
        onRefreshRequested: root.refreshProcesses(true)
        onPidCopied: (proc) => {
            return root.copyPid(proc);
        }
        onBranchCopied: (branch) => {
            return root.copyBranch(branch);
        }
        onKillRequested: (proc) => {
            return root.requestKill(proc);
        }
    }

}
