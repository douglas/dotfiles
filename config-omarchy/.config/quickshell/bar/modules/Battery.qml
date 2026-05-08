import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland

Item {
    id: root

    property var theme: ({
    })
    property bool barOnBottom: false
    property int overlayBarOffset: 44
    property real overlayScale: 1.18
    property bool showing: false
    readonly property bool hovered: batteryPill.hovered
    property string notice: ""
    property var processes: []
    property var processTree: []
    property bool showPids: false
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
    readonly property string processTreeScript: (Quickshell.env("HOME") || "") + "/.config/quickshell/scripts/quickshell-process-tree"

    signal opened()

    function overlayPx(value) {
        return Math.round(value * Math.max(1, overlayScale));
    }

    function iconForLevel() {
        if (!ready)
            return "󰂑";

        if (charging)
            return "󰂄";

        if (percentage <= 5)
            return "󰂎";

        if (percentage <= 10)
            return "󰁺";

        if (percentage <= 20)
            return "󰁻";

        if (percentage <= 30)
            return "󰁼";

        if (percentage <= 40)
            return "󰁽";

        if (percentage <= 50)
            return "󰁾";

        if (percentage <= 60)
            return "󰁿";

        if (percentage <= 70)
            return "󰂀";

        if (percentage <= 80)
            return "󰂁";

        if (percentage <= 90)
            return "󰂂";

        return "󰁹";
    }

    function levelColor() {
        if (!ready)
            return cMuted;

        if (percentage <= 15)
            return cRed;

        if (percentage <= 30)
            return cYellow;

        return cFg;
    }

    function stateLabel() {
        if (!ready)
            return "Battery unavailable";

        return UPowerDeviceState.toString(device.state);
    }

    function refreshImpact() {
        impactProc.running = false;
        impactProc.running = true;
    }

    function processCountLabel(count) {
        return count + " proc" + (count === 1 ? "" : "s");
    }

    function shortContainerName(name, id) {
        let display = String(name || id || "");
        display = display.replace(/^dox-compose_/, "");
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

    visible: hasLaptopBattery
    enabled: hasLaptopBattery
    implicitWidth: hasLaptopBattery ? batteryPill.implicitWidth : 0
    implicitHeight: hasLaptopBattery ? 28 : 0
    onHasLaptopBatteryChanged: {
        if (!hasLaptopBattery)
            showing = false;

    }
    onShowingChanged: {
        if (showing)
            refreshImpact();

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

        command: ["bash", root.processTreeScript, "cpu"]
        running: false
        onExited: {
            root.processTree = root.parseProcessTree(stdout.buf);
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

    StatPill {
        id: batteryPill

        anchors.centerIn: parent
        label: "BAT"
        value: root.percentage
        accent: root.cAccent
        trackColor: root.cDim
        textColor: root.cFg
        interactive: true
        onClicked: {
            if (root.showing) {
                root.showing = false;
                return ;
            }
            root.showing = true;
            root.opened();
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
        subtitle: root.ready ? root.percentage + "% · " + root.stateLabel() : "Unavailable"
        notice: root.notice
        listTitle: "Processes"
        valueKey: "cpu"
        accent: root.cAccent
        processes: root.processes
        treeGroups: root.processTree
        emptyText: "no process data"
        loading: impactProc.running
        theme: root.theme
        onCloseRequested: root.showing = false
        onRefreshRequested: root.refreshImpact()
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
