import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire

PanelWindow {
    id: cc

    property var  theme:   ({})
    property var  notifServer: null
    property var  powerActions: null
    property var  settingsWindow: null
    property bool showing: false
    property real btManagerScale: Math.max(1.0, Math.min(1.4, Math.min(screen.width / 1920, screen.height / 1080) * 1.25))
    property real btManagerFontScale: Math.max(1.0, btManagerScale * 0.86)

    visible: showing

    implicitWidth:  284
    implicitHeight: Math.min(mainCol.implicitHeight + 28, screen.height - 58)

    anchors { top: true; right: true }
    margins { top: 44; right: 10 }

    WlrLayershell.exclusiveZone: -1
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"

    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    property bool   wifiEnabled:    false
    property string wifiDevice:     ""
    property string wifiState:      ""
    property string wifiConnection: ""
    property string wifiSsid:       ""
    property int    wifiSignal:     0
    property bool   wifiSecure:     false
    property bool   ethernetActive: false
    property string ethernetIface:  ""
    property bool   btEnabled:      false
    property string btConnectedName: ""
    property string btConnectedIconName: ""
    property int    btConnectedBattery: -1
    property int    btConnectedCount: 0
    property string lastBtNotifiedName: ""
    property string lastBtDisconnectedName: ""
    property bool   dndEnabled:     notifServer?.dndEnabled ?? false
    property bool   showWifiList:   false
    property bool   showBtList:     false
    property bool   wifiManagerOpen: false
    property bool   btManagerOpen:   false
    property var    wifiNetworks:   []
    property var    savedWifiSsids: []
    property var    btDevices:      []
    property bool   hasNmcli:       false
    property bool   hasBluetoothctl: false
    property bool   hasBluetoothDevice: false
    property bool   btScanning: false
    property int    btScanTicks: 0
    property bool   wifiScanning: false
    property int    wifiScanTicks: 0
    property bool   wifiPasswordOpen: false
    property string wifiPasswordSsid: ""
    property string wifiPasswordError: ""
    property bool   wifiPasswordWorking: false
    property bool   wifiPasswordSecure: false
    property bool   hasBrightnessctl: false
    property bool   hasBrightnessDevice: false
    property bool   hasDdcutil: false
    property bool   hasDdcBrightness: false
    property bool   ddcBrightnessChecked: false
    property int    pendingDdcBrightness: -1
    property bool   hasIp:          false

    function restart(proc) {
        proc.running = false
        proc.running = true
    }

    function btpx(value) {
        return Math.round(value * btManagerScale)
    }

    function btfont(value) {
        return Math.round(value * btManagerFontScale)
    }

    function refreshConnectivity() {
        if (hasNmcli)
            restart(wifiStatus)
        else {
            wifiEnabled = false
            wifiDevice = ""
            wifiState = ""
            wifiConnection = ""
            wifiSsid = ""
            wifiSignal = 0
            wifiSecure = false
            wifiNetworks = []
        }

        if (hasIp)
            restart(ethernetStatus)
        else {
            ethernetActive = false
            ethernetIface = ""
        }

        if (hasBluetoothctl && hasBluetoothDevice) {
            restart(btStatus)
            restart(btScan)
        } else {
            btEnabled = false
            btDevices = []
            btConnectedName = ""
            btConnectedIconName = ""
            btConnectedBattery = -1
            btConnectedCount = 0
        }
    }

    function hasBrightness() {
        return (hasBrightnessctl && hasBrightnessDevice)
            || (hasDdcutil && (!ddcBrightnessChecked || hasDdcBrightness))
    }

    function refreshBrightness() {
        if (!showing || !hasBrightness() || briProc.running)
            return

        briProc.stdout.sawValue = false
        if (hasDdcutil && !hasBrightnessDevice)
            ddcBrightnessChecked = true
        restart(briProc)
    }

    function scheduleBrightnessRefresh() {
        if (showing)
            brightnessRefreshTimer.restart()
    }

    function runDdcSet(value) {
        Quickshell.execDetached([
            "timeout",
            "4s",
            "ddcutil",
            "setvcp",
            "10",
            String(value)
        ])
    }

    function flushPendingDdcBrightness() {
        if (pendingDdcBrightness < 0)
            return

        runDdcSet(pendingDdcBrightness)
        pendingDdcBrightness = -1
        scheduleBrightnessRefresh()
    }

    function restartBrightnessRead() {
        if (!showing || briProc.running)
            return
        briProc.stdout.sawValue = false
        if (hasDdcutil && !hasBrightnessDevice)
            ddcBrightnessChecked = true
        restart(briProc)
    }

    function refreshWifiScan() {
        if (hasNmcli)
            restart(wifiScan)
    }

    function refreshWifiSaved() {
        if (hasNmcli)
            restart(wifiSaved)
    }

    function refreshBtScan() {
        if (hasBluetoothctl && hasBluetoothDevice) {
            if (btScan.running) return
            restart(btScan)
        }
    }

    function runNmcli(args) {
        if (hasNmcli)
            Quickshell.execDetached(["nmcli"].concat(args))
    }

    function startWifiConnect(ssid) {
        wifiPasswordWorking = true
        wifiConnectProc.targetSsid = ssid
        wifiConnectProc.command = [
            "nmcli", "-t", "device", "wifi", "connect", ssid
        ]
        wifiConnectProc.running = false
        wifiConnectProc.running = true
    }

    function connectWifi(ssid, secure) {
        wifiPasswordSecure = secure
        wifiPasswordSsid = ssid
        wifiPasswordError = ""

        if (secure && savedWifiSsids.indexOf(ssid) < 0) {
            wifiPasswordOpen = true
            wifiPasswordError = "Use the system Wi-Fi tool to enter credentials securely."
            return
        }

        startWifiConnect(ssid)
    }

    function openSecureWifiManager() {
        wifiPasswordOpen = false
        wifiPasswordError = ""
        Quickshell.execDetached([
            "bash", "-lc",
            "if command -v omarchy-launch-wifi >/dev/null 2>&1; then " +
            "  omarchy-launch-wifi; " +
            "elif command -v nm-connection-editor >/dev/null 2>&1; then " +
            "  nm-connection-editor; " +
            "elif command -v nmtui >/dev/null 2>&1 && command -v xdg-terminal-exec >/dev/null 2>&1; then " +
            "  xdg-terminal-exec nmtui-connect; " +
            "fi"
        ])
    }

    function forgetWifi(ssid) {
        runNmcli(["connection", "delete", ssid])
        refreshConnectivity()
        refreshWifiScan()
    }

    function runBluetoothctl(args) {
        if (hasBluetoothctl && hasBluetoothDevice)
            Quickshell.execDetached(["bluetoothctl"].concat(args))
    }

    function bluetoothUnavailableLabel(adapterLabel) {
        if (!hasBluetoothctl) return "Install bluez-utils"
        return adapterLabel
    }

    function setBrightnessPercent(value) {
        const pct = Math.max(1, Math.min(100, Math.round(value)))

        if (hasBrightnessctl && hasBrightnessDevice)
            Quickshell.execDetached(["brightnessctl", "set", pct + "%"])
        else if (hasDdcutil && hasDdcBrightness) {
            pendingDdcBrightness = pct
            ddcBrightnessSetTimer.restart()
            return
        } else
            return

        scheduleBrightnessRefresh()
    }

    function wifiStateLabel() {
        if (!wifiEnabled) return "Off"
        if (ethernetActive) return ethernetIface
        if (wifiState === "connected") return wifiSsid !== "" ? wifiSsid : "Connected"
        if (wifiState === "connecting") return "Connecting"
        if (wifiState === "failed") return "Failed"
        if (wifiState === "disconnected") return "Disconnected"
        if (wifiState !== "") return wifiState
        return "On"
    }

    function wifiStateColor() {
        if (!wifiEnabled) return theme.muted || "#585b70"
        if (wifiState === "connected") return theme.accent || "#89b4fa"
        if (wifiState === "connecting") return "#fab387"
        if (wifiState === "failed") return theme.red || "#f38ba8"
        return theme.muted || "#585b70"
    }

    Timer {
        id: btRescanTimer
        interval: 6500
        repeat: false
        onTriggered: {
            refreshBtScan()
            cc.btScanning = false
        }
    }

    Timer {
        interval: 7000
        running:  true
        repeat:   true
        onTriggered: refreshBtScan()
    }

    Timer {
        id: btScanTicker
        interval: 350
        repeat: true
        running: cc.btScanning
        onTriggered: cc.btScanTicks = (cc.btScanTicks + 1) % 4
    }

    Timer {
        id: wifiRescanTimer
        interval: 3500
        repeat: false
        onTriggered: cc.wifiScanning = false
    }

    Timer {
        id: wifiScanTicker
        interval: 350
        repeat: true
        running: cc.wifiScanning
        onTriggered: cc.wifiScanTicks = (cc.wifiScanTicks + 1) % 4
    }

    Timer {
        id: brightnessRefreshTimer
        interval: 350
        repeat: false
        onTriggered: restartBrightnessRead()
    }

    Timer {
        id: ddcBrightnessSetTimer
        interval: 250
        repeat: false
        onTriggered: cc.flushPendingDdcBrightness()
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    Process {
        id: depsProbe
        command: ["bash", "-lc",
            "printf 'nmcli=%s\\n' \"$(command -v nmcli >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'bluetoothctl=%s\\n' \"$(command -v bluetoothctl >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'bluetoothdevice=%s\\n' \"$(command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl list 2>/dev/null | grep -q 'Controller' && echo 1 || echo 0)\"; " +
            "printf 'brightnessctl=%s\\n' \"$(command -v brightnessctl >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'brightnessdevice=%s\\n' \"$(command -v brightnessctl >/dev/null 2>&1 && brightnessctl -l 2>/dev/null | awk '/backlight/{found=1} END{exit found ? 0 : 1}' && echo 1 || echo 0)\"; " +
            "printf 'ddcutil=%s\\n' \"$(command -v ddcutil >/dev/null 2>&1 && echo 1 || echo 0)\"; " +
            "printf 'ip=%s\\n' \"$(command -v ip >/dev/null 2>&1 && echo 1 || echo 0)\""
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("=")
                if (parts.length !== 2)
                    return
                const enabled = parts[1].trim() === "1"
                if (parts[0] === "nmcli")
                    cc.hasNmcli = enabled
                else if (parts[0] === "bluetoothctl")
                    cc.hasBluetoothctl = enabled
                else if (parts[0] === "bluetoothdevice")
                    cc.hasBluetoothDevice = enabled
                else if (parts[0] === "brightnessctl")
                    cc.hasBrightnessctl = enabled
                else if (parts[0] === "brightnessdevice")
                    cc.hasBrightnessDevice = enabled
                else if (parts[0] === "ddcutil") {
                    cc.hasDdcutil = enabled
                    cc.hasDdcBrightness = enabled
                }
                else if (parts[0] === "ip")
                    cc.hasIp = enabled
            }
        }
        onExited: {
            refreshConnectivity()
        }
    }

    Process {
        id: wifiStatus
        command: ["bash", "-c",
            "nmcli radio wifi; " +
            "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | " +
            "awk -F: '$2==\"wifi\"{print $1; print $3; print $4; found=1; exit} END{if(!found){print \"\"; print \"\"; print \"\"}}'; " +
            "nmcli -t -f active,ssid,signal,security dev wifi 2>/dev/null | " +
            "awk -F: '$1==\"yes\"{print $2; print $3; print $4; found=1; exit} END{if(!found){print \"\"; print \"\"; print \"\"}}'"]
        running: false
        stdout: SplitParser {
            property int ln: 0
            onRead: data => {
                const t = data.trim()
                if (ln === 0) cc.wifiEnabled = t === "enabled"
                else if (ln === 1) cc.wifiDevice = t
                else if (ln === 2) cc.wifiState = t
                else if (ln === 3) cc.wifiConnection = t
                else if (ln === 4) cc.wifiSsid = t
                else if (ln === 5) cc.wifiSignal = parseInt(t) || 0
                else cc.wifiSecure = t !== "" && t !== "--"
                ln++
            }
        }
        onExited: {
            wifiStatus.stdout.ln = 0
            if (!cc.wifiEnabled) {
                cc.wifiState = ""
                cc.wifiConnection = ""
                cc.wifiSsid = ""
                cc.wifiSignal = 0
                cc.wifiSecure = false
            }
        }
    }

    Process {
        id: ethernetStatus
        command: ["bash", "-c",
            "if command -v nmcli >/dev/null 2>&1; then " +
            "  nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | " +
            "  awk -F: '$2==\"ethernet\" && $3==\"connected\" {print $1; exit}'; " +
            "else " +
            "  ip link show | awk '/^[0-9]+: e[a-z0-9]+:.*UP/{gsub(/:$/,\"\",$2); print $2; exit}'; " +
            "fi"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const iface = data.trim()
                cc.ethernetActive = iface !== ""
                cc.ethernetIface = iface
            }
        }
    }

    Process {
        id: wifiScan
        command: ["bash", "-c",
            "nmcli -t -f ssid,signal,security dev wifi list 2>/dev/null | head -12"]
        running: false
        stdout: SplitParser {
            property var nets: []
            onRead: data => {
                const p = data.trim().split(":")
                if (p[0]?.trim()) nets.push({
                    ssid:   p[0].trim(),
                    signal: parseInt(p[1]) || 0,
                    secure: (p[2] || "--") !== "--"
                })
            }
        }
        onExited: {
            cc.wifiNetworks      = wifiScan.stdout.nets.slice()
            wifiScan.stdout.nets = []
        }
    }

    Process {
        id: wifiSaved
        command: ["bash", "-c",
            "nmcli -t -f NAME,TYPE connection show 2>/dev/null | " +
            "awk -F: '$2==\"wifi\"{print $1}' | head -50"]
        running: false
        stdout: SplitParser {
            property var names: []
            onRead: data => {
                const name = data.trim()
                if (name) names.push(name)
            }
        }
        onExited: {
            cc.savedWifiSsids = wifiSaved.stdout.names.slice()
            wifiSaved.stdout.names = []
        }
    }

    Process {
        id: wifiConnectProc
        property string targetSsid: ""
        command: ["bash", "-lc", "true"]
        running: false
        stdout: SplitParser {
            property string buf: ""
            onRead: data => buf += data
        }
        onExited: exitCode => {
            const msg = (wifiConnectProc.stdout.buf || "").trim()
            wifiConnectProc.stdout.buf = ""
            wifiPasswordWorking = false
            if (exitCode === 0) {
                wifiPasswordOpen = false
                wifiPasswordError = ""
                refreshConnectivity()
                refreshWifiScan()
                return
            }
            if (wifiPasswordSecure) {
                wifiPasswordOpen = true
                wifiPasswordError = "Could not connect. Use the system Wi-Fi tool to manage credentials."
            } else {
                wifiPasswordOpen = false
                wifiPasswordError = msg
            }
        }
    }

    Process {
        id: btStatus
        command: ["bash", "-c", "bluetoothctl show | grep Powered | awk '{print $2}'"]
        running: false
        stdout: SplitParser {
            onRead: data => { cc.btEnabled = data.trim() === "yes" }
        }
    }

    Process {
        id: btScan
        command: ["bash", "-c",
            "bluetoothctl devices 2>/dev/null | head -8 | while read -r _ mac rest; do " +
            "bat=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F'[()]' '/Battery Percentage/{print $2; exit}' | tr -d '%'); " +
            "trst=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F': ' '/Trusted:/{print $2; exit}'); " +
            "conn=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F': ' '/Connected:/{print $2; exit}'); " +
            "icon=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F': ' '/Icon:/{print $2; exit}'); " +
            "printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$mac\" \"$rest\" \"$bat\" \"$trst\" \"$conn\" \"$icon\"; " +
            "done"]
        running: false
        stdout: SplitParser {
            property var devs: []
            onRead: data => {
                const line = data.trim()
                if (!line) return
                const parts = line.split("\t")
                if (parts.length < 2) return
                const mac = parts[0].trim()
                const name = parts[1].trim()
                const bRaw = (parts.length > 2 ? parts[2] : "").trim()
                const trustedRaw = (parts.length > 3 ? parts[3] : "").trim().toLowerCase()
                const connectedRaw = (parts.length > 4 ? parts[4] : "").trim().toLowerCase()
                const iconRaw = (parts.length > 5 ? parts[5] : "").trim()
                const b = parseInt(bRaw)
                if (mac && name) devs.push({
                    mac: mac,
                    name: name,
                    battery: isNaN(b) ? -1 : Math.max(0, Math.min(100, b)),
                    trusted: trustedRaw === "yes" || trustedRaw === "true",
                    connected: connectedRaw === "yes" || connectedRaw === "true",
                    iconName: iconRaw
                })
            }
        }
        onExited: {
            cc.btDevices       = btScan.stdout.devs.slice()
            const connected = cc.btDevices.filter(d => d.connected)
            cc.btConnectedCount = connected.length
            cc.btConnectedName = connected.length > 0 ? connected[0].name : ""
            cc.btConnectedIconName = connected.length > 0 ? connected[0].iconName : ""
            cc.btConnectedBattery = connected.length > 0 ? connected[0].battery : -1
            btScan.stdout.devs = []
        }
    }

    Process {
        id: briProc
        command: ["bash", "-c",
            "if command -v brightnessctl >/dev/null 2>&1 && brightnessctl -l 2>/dev/null | awk '/backlight/{found=1} END{exit found ? 0 : 1}'; then " +
            "  brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'; " +
            "elif command -v ddcutil >/dev/null 2>&1; then " +
            "  timeout 2s ddcutil getvcp 10 2>/dev/null | awk -F'current value = *|,' '/current value/{print $2; exit}'; " +
            "fi"
        ]
        running: false
        stdout: SplitParser {
            property bool sawValue: false
            onRead: data => {
                const v = parseInt(data.trim())
                if (!isNaN(v)) {
                    sawValue = true
                    cc.hasDdcBrightness = true
                    briSlider.value = v / 100
                }
            }
        }
        onExited: {
            if (!hasBrightnessDevice && hasDdcutil && !stdout.sawValue)
                hasDdcBrightness = false
        }
    }

    Timer {
        interval: 3000; running: cc.showing || cc.wifiManagerOpen || cc.btManagerOpen; repeat: true
        onTriggered: refreshConnectivity()
    }

    onShowingChanged: {
        if (showing) {
            refreshConnectivity()
            refreshBrightness()
        }
    }

    function openWifiManager() {
        cc.showWifiList = false
        cc.showBtList = false
        cc.showing = false
        cc.btManagerOpen = false
        cc.wifiManagerOpen = true
        refreshConnectivity()
        refreshWifiScan()
        refreshWifiSaved()
    }

    function openBtManager() {
        if (!hasBluetoothctl) {
            Quickshell.execDetached(["bash", "-lc", "omarchy-launch-bluetooth"])
            return
        }

        cc.showWifiList = false
        cc.showBtList = false
        cc.showing = false
        cc.wifiManagerOpen = false
        cc.btManagerOpen = true
        refreshConnectivity()
        refreshBtScan()
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius:       14
        color:        theme.bg  || "#1e1e2e"
        border.color: theme.dim || "#45475a"
        border.width: 1
        clip:         true

        states: [
            State {
                name: "open"; when: cc.showing
                PropertyChanges { target: slideX; x: 0 }
            },
            State {
                name: "closed"; when: !cc.showing
                PropertyChanges { target: slideX; x: 300 }
            }
        ]
        transitions: [
            Transition {
                from: "closed"; to: "open"
                NumberAnimation { target: slideX; property: "x"; duration: 240; easing.type: Easing.OutCubic }
            },
            Transition {
                from: "open"; to: "closed"
                NumberAnimation { target: slideX; property: "x"; duration: 200; easing.type: Easing.InCubic }
            }
        ]

        transform: Translate { id: slideX; x: 300 }

        Column {
            id: mainCol
            anchors {
                top: parent.top; left: parent.left; right: parent.right
                topMargin: 14; leftMargin: 12; rightMargin: 12
            }
            spacing: 12

            // ── HEADER ────────────────────────────────────────────────────────
            Rectangle {
                width: parent.width; height: 62; radius: 12
                color: theme.bg
                    ? Qt.tint(theme.bg, Qt.rgba(1, 1, 1, 0.08))
                    : Qt.alpha(theme.dim || "#45475a", 0.6)
                border.color: Qt.alpha(theme.dim || "#45475a", 0.45)
                border.width: 1

                Row {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                    spacing: 12
                    Rectangle {
                        width: 38; height: 38; radius: 19
                        color: Qt.alpha(theme.accent || "#89b4fa", 0.15)
                        border.color: Qt.alpha(theme.accent || "#89b4fa", 0.4); border.width: 1
                        Text {
                            anchors.centerIn: parent; text: "󰀄"; font.pixelSize: 20
                            font.family: "JetBrainsMono Nerd Font Propo"; color: theme.accent || "#89b4fa"
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 3
                        Text {
                            text: Quickshell.env("USER") || "user"
                            color: theme.fg || "#cdd6f4"
                            font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.Medium
                        }
                        Text {
                            text: Quickshell.env("HOSTNAME") || "localhost"
                            color: theme.muted || "#585b70"
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }
                }

                Row {
                    anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 12 }
                    spacing: 8
                    Repeater {
                        model: [
                            { icon: "󰌾", hoverColor: theme.accent || "#89b4fa", cmd: ["hyprlock"] },
                            { icon: "󰜉", hoverColor: "#fab387",                 cmd: ["systemctl", "reboot"] },
                            { icon: "󰐥", hoverColor: "#f38ba8",                 cmd: ["systemctl", "poweroff"] }
                        ]
                        delegate: Rectangle {
                            width: 30; height: 30; radius: 9
                            color: btnMa.containsMouse
                                ? Qt.alpha(modelData.hoverColor, 0.18)
                                : Qt.alpha(theme.dim || "#45475a", 0.4)
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Text {
                                anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 15
                                font.family: "JetBrainsMono Nerd Font Propo"
                                color: btnMa.containsMouse ? modelData.hoverColor : (theme.muted || "#585b70")
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            MouseArea {
                                id: btnMa; anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: {
                                    if (modelData.cmd[0] === "hyprlock") {
                                        Quickshell.execDetached(modelData.cmd)
                                    } else if (cc.powerActions) {
                                        cc.powerActions.requestAction(
                                            modelData.cmd[1] === "reboot" ? "Restart" : "Shutdown",
                                            modelData.cmd[1] === "reboot" ? "Restart the system?" : "Power off the system?",
                                            modelData.cmd
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── TOGGLES ROW 1 — Network · Bluetooth · DND ────────────────────
            Row {
                width: parent.width; spacing: 8

                // Network
                Rectangle {
                    width: (parent.width - 16) / 3; height: 72; radius: 12
                    color: (cc.ethernetActive || cc.wifiEnabled)
                        ? Qt.alpha(theme.accent || "#89b4fa", 0.15)
                        : Qt.alpha(theme.dim    || "#45475a", 0.35)
                    border.color: (cc.ethernetActive || cc.wifiEnabled)
                        ? Qt.alpha(theme.accent || "#89b4fa", 0.4) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.ethernetActive ? "󰈀" : cc.wifiEnabled ? "󰤨" : "󰤭"
                            color: (cc.ethernetActive || cc.wifiEnabled)
                                ? (theme.accent || "#89b4fa") : (theme.muted || "#585b70")
                            font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font Propo"
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.ethernetActive ? "Ethernet" : "Wi-Fi"
                            color: (cc.ethernetActive || cc.wifiEnabled)
                                ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.ethernetActive ? cc.ethernetIface
                                : (cc.wifiSsid !== ""
                                    ? cc.wifiSsid + (cc.wifiSignal > 0 ? " " + cc.wifiSignal + "%" : "") + (cc.wifiSecure ? " 󰌾" : "")
                                    : cc.wifiStateLabel())
                            color: cc.ethernetActive ? (theme.muted || "#585b70") : cc.wifiStateColor()
                            font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font Propo"
                            elide: Text.ElideRight; width: parent.parent.width - 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    cc.openWifiManager()
                                } else {
                                    if (cc.ethernetActive) return
                                    cc.runNmcli(["radio", "wifi", cc.wifiEnabled ? "off" : "on"])
                                    refreshConnectivity()
                                }
                            }
                        }
                }

                // Bluetooth
                Rectangle {
                    width: (parent.width - 16) / 3; height: 72; radius: 12
                    color: cc.btEnabled
                        ? Qt.alpha(theme.accent || "#89b4fa", 0.15)
                        : Qt.alpha(theme.dim    || "#45475a", 0.35)
                    border.color: cc.btEnabled
                        ? Qt.alpha(theme.accent || "#89b4fa", 0.4) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.btEnabled ? "󰂱" : "󰂲"
                            color: cc.btEnabled ? (theme.accent || "#89b4fa") : (theme.muted || "#585b70")
                            font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font Propo"
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Bluetooth"
                            color: cc.btEnabled ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.btConnectedName !== ""
                                ? cc.btConnectedName + (cc.btConnectedBattery >= 0 ? " " + cc.btConnectedBattery + "%" : "")
                                : (cc.hasBluetoothDevice
                                    ? (cc.btEnabled ? "Right-click for manager" : "Off")
                                    : cc.bluetoothUnavailableLabel("No adapter"))
                            color: theme.muted || "#585b70"
                            font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font Propo"
                            elide: Text.ElideRight
                            width: parent.parent.width - 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                cc.openBtManager()
                            } else {
                                if (!cc.hasBluetoothDevice) return
                                cc.runBluetoothctl(["power", cc.btEnabled ? "off" : "on"])
                                refreshConnectivity()
                            }
                        }
                    }
                }

                // DND
                Rectangle {
                    width: (parent.width - 16) / 3; height: 72; radius: 12
                    color: cc.dndEnabled ? Qt.alpha("#fab387", 0.15) : Qt.alpha(theme.dim || "#45475a", 0.35)
                    border.color: cc.dndEnabled ? Qt.alpha("#fab387", 0.4) : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Column {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.dndEnabled ? "󰂛" : "󰂚"
                            color: cc.dndEnabled ? "#fab387" : (theme.muted || "#585b70")
                            font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font Propo"
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "DND"
                            color: cc.dndEnabled ? (theme.fg || "#cdd6f4") : (theme.muted || "#585b70")
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cc.dndEnabled ? "On" : "Off"
                            color: theme.muted || "#585b70"
                            font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (cc.notifServer) cc.notifServer.toggleDnd()
                    }
                }
            }

            // WiFi sub-list
            Column {
                width: parent.width; spacing: 3
                visible: cc.showWifiList && cc.wifiNetworks.length > 0
                Text {
                    text: "Available Networks"; color: theme.muted || "#585b70"
                    font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font Propo"; bottomPadding: 2
                }
                Repeater {
                    model: cc.wifiNetworks
                    delegate: Rectangle {
                        width: parent.width; height: 34; radius: 8
                        color: wifiMa.containsMouse
                            ? Qt.alpha(theme.accent || "#89b4fa", 0.12)
                            : Qt.alpha(theme.dim    || "#45475a", 0.25)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Row {
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 12 }
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.signal > 66 ? "󰤨" : modelData.signal > 33 ? "󰤢" : "󰤟"
                                color: theme.accent || "#89b4fa"; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font Propo"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; text: modelData.ssid
                                color: modelData.ssid === cc.wifiSsid ? (theme.accent || "#89b4fa") : (theme.fg || "#cdd6f4")
                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                                font.weight: modelData.ssid === cc.wifiSsid ? Font.Medium : Font.Normal
                                elide: Text.ElideRight; width: parent.width - 44
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.secure; text: "󰌾"
                                color: theme.muted || "#585b70"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                            }
                        }
                        MouseArea {
                            id: wifiMa; anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: {
                                cc.connectWifi(modelData.ssid, modelData.secure)
                                cc.showWifiList = false
                                refreshConnectivity()
                            }
                        }
                    }
                }
            }

            // BT sub-list
            Column {
                width: parent.width; spacing: 3
                visible: cc.showBtList && cc.btDevices.length > 0
                Text {
                    text: "Paired Devices"; color: theme.muted || "#585b70"
                    font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font Propo"; bottomPadding: 2
                }
                Repeater {
                    model: cc.btDevices
                    delegate: Rectangle {
                        width: parent.width; height: 34; radius: 8
                        color: btMa.containsMouse
                            ? Qt.alpha(theme.accent || "#89b4fa", 0.12)
                            : Qt.alpha(theme.dim    || "#45475a", 0.25)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Row {
                            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰂯"; color: theme.accent || "#89b4fa"
                                font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font Propo"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; text: modelData.name
                                color: theme.fg || "#cdd6f4"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font Propo"
                                elide: Text.ElideRight; width: parent.parent.width - 50
                            }
                        }
                        MouseArea {
                            id: btMa; anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: {
                                cc.runBluetoothctl(["connect", modelData.mac])
                                cc.showBtList = false
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: theme.dim || "#45475a"; opacity: 0.3 }

            // ── SLIDERS ───────────────────────────────────────────────────────
            CCSlider {
                width: parent.width
                icon:  Pipewire.defaultAudioSink?.audio?.muted ?? false ? "󰝟" : "󰕾"
                value: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                theme: cc.theme
                onMoved: v => {
                    const s = Pipewire.defaultAudioSink
                    if (s?.audio) { s.audio.muted = false; s.audio.volume = v }
                }
                onIconClicked: {
                    const s = Pipewire.defaultAudioSink
                    if (s?.audio) s.audio.muted = !s.audio.muted
                }
            }
            CCSlider {
                width: parent.width
                icon:  Pipewire.defaultAudioSource?.audio?.muted ?? false ? "󰍭" : "󰍬"
                value: Pipewire.defaultAudioSource?.audio?.volume ?? 0
                theme: cc.theme
                onMoved: v => {
                    const s = Pipewire.defaultAudioSource
                    if (s?.audio) { s.audio.muted = false; s.audio.volume = v }
                }
                onIconClicked: {
                    const s = Pipewire.defaultAudioSource
                    if (s?.audio) s.audio.muted = !s.audio.muted
                }
            }
            CCSlider {
                id: briSlider; width: parent.width
                visible: cc.hasBrightness()
                height: visible ? implicitHeight : 0
                icon: "󰃞"; value: 0.5; theme: cc.theme
                onMoved: v => {
                    briSlider.value = v
                    cc.setBrightnessPercent(v * 100)
                }
            }

            Item { width: 1; height: 6 }
        }
    }

    PanelWindow {
        id: wifiManager
        visible: cc.wifiManagerOpen

        anchors { top: true; right: true }
        margins { top: 44; right: 10 }

        implicitWidth: cc.btpx(340)
        implicitHeight: Math.min(wifiManagerCol.implicitHeight + cc.btpx(24), cc.screen.height - cc.btpx(58))

        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Behavior on implicitHeight {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        onVisibleChanged: {
            if (visible) {
                refreshConnectivity()
                refreshWifiScan()
                refreshWifiSaved()
            } else {
                cc.wifiPasswordOpen = false
                cc.wifiPasswordError = ""
            }
        }

        Rectangle {
            id: wifiManagerCard
            anchors.fill: parent
            radius: cc.btpx(14)
            color: cc.theme.bg || "#1e1e2e"
            border.color: cc.theme.dim || "#45475a"
            border.width: 1
            clip: true
            opacity: cc.wifiManagerOpen ? 1 : 0

            transform: Translate {
                y: cc.wifiManagerOpen ? 0 : -cc.btpx(14)
                Behavior on y {
                    NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Column {
                id: wifiManagerCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: cc.btpx(12) }
                spacing: cc.btpx(8)

                RowLayout {
                    width: parent.width
                    height: cc.btpx(24)
                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: "Wi-Fi Manager"
                        color: cc.theme.fg || "#cdd6f4"
                        font.pixelSize: cc.btfont(11)
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.weight: Font.Medium
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "✕"
                        color: wifiCloseMa.containsMouse ? (cc.theme.red || "#f38ba8") : (cc.theme.muted || "#585b70")
                        font.pixelSize: cc.btfont(8)
                        font.family: "JetBrainsMono Nerd Font Propo"
                        MouseArea {
                            id: wifiCloseMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cc.wifiManagerOpen = false
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: cc.btpx(40)
                    radius: cc.btpx(8)
                    color: wifiPowerMa.containsMouse
                        ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.16)
                        : Qt.alpha(cc.theme.dim || "#45475a", 0.22)
                    border.color: wifiPowerMa.containsMouse
                        ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.38)
                        : Qt.alpha(cc.theme.accent || "#89b4fa", 0.22)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: cc.btpx(10)
                        anchors.rightMargin: cc.btpx(10)
                        spacing: cc.btpx(8)
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.wifiEnabled ? "󰤨" : "󰤭"
                            color: cc.wifiEnabled ? (cc.theme.accent || "#89b4fa") : (cc.theme.muted || "#585b70")
                            font.pixelSize: cc.btfont(13)
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.wifiEnabled
                                ? (cc.wifiSsid !== ""
                                    ? cc.wifiSsid + (cc.wifiSignal > 0 ? "  " + cc.wifiSignal + "%" : "")
                                    : cc.wifiStateLabel())
                                : "Wi-Fi Off"
                            color: cc.theme.fg || "#cdd6f4"
                            font.pixelSize: cc.btfont(11)
                            font.family: "JetBrainsMono Nerd Font Propo"
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.wifiEnabled ? "Disable" : "Enable"
                            color: cc.theme.accent || "#89b4fa"
                            font.pixelSize: cc.btfont(11)
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }
                    MouseArea {
                        id: wifiPowerMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cc.runNmcli(["radio", "wifi", cc.wifiEnabled ? "off" : "on"])
                            refreshConnectivity()
                            refreshWifiScan()
                            refreshWifiSaved()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: cc.btpx(34)
                    radius: cc.btpx(8)
                    color: Qt.alpha(cc.theme.dim || "#45475a", 0.18)
                    border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.3)
                    border.width: 1
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: cc.btpx(10)
                        anchors.rightMargin: cc.btpx(10)
                        spacing: cc.btpx(8)
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: "Rescan Networks"
                            color: cc.theme.muted || "#585b70"
                            font.pixelSize: cc.btfont(11)
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: cc.btpx(6)
                            Row {
                                visible: cc.wifiScanning
                                spacing: cc.btpx(2)
                                Repeater {
                                    model: 3
                                    delegate: Rectangle {
                                        width: cc.btpx(4); height: cc.btpx(4); radius: cc.btpx(2)
                                        color: cc.theme.accent || "#89b4fa"
                                        opacity: cc.wifiScanTicks === (index + 1) ? 1 : 0.25
                                    }
                                }
                            }
                            Text {
                                text: cc.wifiScanning ? "Scanning" : "Scan"
                                color: cc.theme.accent || "#89b4fa"
                                font.pixelSize: cc.btfont(11)
                                font.family: "JetBrainsMono Nerd Font Propo"
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            cc.runNmcli(["dev", "wifi", "rescan"])
                            refreshConnectivity()
                            refreshWifiScan()
                            refreshWifiSaved()
                            cc.wifiScanning = true
                            cc.wifiScanTicks = 0
                            wifiRescanTimer.restart()
                        }
                    }
                }

                Flickable {
                    width: parent.width
                    height: Math.min(Math.max(wifiListCol.implicitHeight, cc.btpx(66)), cc.btpx(270))
                    contentHeight: wifiListCol.implicitHeight
                    clip: true

                    Column {
                        id: wifiListCol
                        width: parent.width
                        spacing: cc.btpx(4)

                        Repeater {
                            model: cc.wifiNetworks
                            delegate: Rectangle {
                                required property var modelData
                                width: wifiListCol.width
                                height: cc.btpx(42)
                                radius: cc.btpx(8)
                                color: wifiMgrItemMa.containsMouse
                                    ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.12)
                                    : Qt.alpha(cc.theme.dim || "#45475a", 0.22)
                                border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.35)
                                border.width: 1
                                RowLayout {
                                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: cc.btpx(10); rightMargin: cc.btpx(10) }
                                    spacing: cc.btpx(8)

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: modelData.signal > 66 ? "󰤨" : modelData.signal > 33 ? "󰤢" : "󰤟"
                                        color: cc.theme.accent || "#89b4fa"
                                        font.pixelSize: cc.btfont(12)
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.fillWidth: true
                                        text: modelData.ssid
                                        color: modelData.ssid === cc.wifiSsid ? (cc.theme.accent || "#89b4fa") : (cc.theme.fg || "#cdd6f4")
                                        font.pixelSize: cc.btfont(11)
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: modelData.ssid === cc.wifiSsid && cc.wifiState !== "" ? cc.wifiState : (modelData.secure ? "secure" : "")
                                        color: modelData.ssid === cc.wifiSsid ? cc.wifiStateColor() : (cc.theme.muted || "#585b70")
                                        font.pixelSize: cc.btfont(9)
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                    }
                                    RowLayout {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: cc.btpx(6)
                                        readonly property bool hasSaved: cc.savedWifiSsids.indexOf(modelData.ssid) >= 0

                                        Rectangle {
                                            width: modelData.ssid === cc.wifiSsid ? cc.btpx(72) : cc.btpx(62)
                                            height: cc.btpx(20)
                                            radius: cc.btpx(6)
                                            color: Qt.alpha(cc.theme.accent || "#89b4fa", 0.18)
                                            border.color: Qt.alpha(cc.theme.accent || "#89b4fa", 0.35)
                                            border.width: 1
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.ssid === cc.wifiSsid ? "Disconnect" : "Connect"
                                                color: cc.theme.accent || "#89b4fa"
                                                font.pixelSize: cc.btfont(9)
                                                font.family: "JetBrainsMono Nerd Font Propo"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.ssid === cc.wifiSsid && cc.wifiDevice !== "") {
                                                        cc.runNmcli(["device", "disconnect", cc.wifiDevice])
                                                    } else {
                                                        cc.connectWifi(modelData.ssid, modelData.secure)
                                                    }
                                                    refreshConnectivity()
                                                    refreshWifiScan()
                                                    refreshWifiSaved()
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: cc.btpx(52)
                                            height: cc.btpx(20)
                                            radius: cc.btpx(6)
                                            visible: hasSaved
                                            color: Qt.alpha(cc.theme.dim || "#45475a", 0.25)
                                            border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.35)
                                            border.width: 1
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Forget"
                                                color: cc.theme.muted || "#585b70"
                                                font.pixelSize: cc.btfont(9)
                                                font.family: "JetBrainsMono Nerd Font Propo"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: cc.forgetWifi(modelData.ssid)
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: wifiMgrItemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        cc.connectWifi(modelData.ssid, modelData.secure)
                                    }
                                }
                            }
                        }

                        Item {
                            visible: cc.wifiNetworks.length === 0
                            width: parent.width
                            height: cc.btpx(56)
                            Text {
                                anchors.centerIn: parent
                                text: "No networks found"
                                color: cc.theme.muted || "#585b70"
                                font.pixelSize: cc.btfont(11)
                                font.family: "JetBrainsMono Nerd Font Propo"
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: wifiPasswordOverlay
                anchors.fill: parent
                visible: cc.wifiPasswordOpen
                color: Qt.alpha("#000000", 0.45)
                z: 20

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.ArrowCursor
                    onClicked: {
                        cc.wifiPasswordOpen = false
                        cc.wifiPasswordError = ""
                    }
                }

                Rectangle {
                    width: parent.width - cc.btpx(36)
                    radius: cc.btpx(12)
                    color: cc.theme.bg || "#1e1e2e"
                    border.color: cc.theme.dim || "#45475a"
                    border.width: 1
                    anchors.centerIn: parent

                    Column {
                        anchors.fill: parent
                        anchors.margins: cc.btpx(14)
                        spacing: cc.btpx(8)

                        Text {
                            text: "Secure Wi‑Fi Network"
                            color: cc.theme.fg || "#cdd6f4"
                            font.pixelSize: cc.btfont(11)
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.Medium
                        }

                        Text {
                            text: cc.wifiPasswordSsid
                            color: cc.theme.muted || "#585b70"
                            font.pixelSize: cc.btfont(9)
                            font.family: "JetBrainsMono Nerd Font Propo"
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: true
                            text: cc.wifiPasswordError !== ""
                                ? cc.wifiPasswordError
                                : "Credentials are handled outside Quickshell so passwords are not exposed through shell arguments."
                            color: cc.theme.muted || "#585b70"
                            font.pixelSize: cc.btfont(9)
                            font.family: "JetBrainsMono Nerd Font Propo"
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }

                        Row {
                            spacing: cc.btpx(8)
                            Rectangle {
                                width: cc.btpx(70)
                                height: cc.btpx(24)
                                radius: cc.btpx(6)
                                color: Qt.alpha(cc.theme.dim || "#45475a", 0.25)
                                border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.35)
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    color: cc.theme.muted || "#585b70"
                                    font.pixelSize: cc.btfont(9)
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        cc.wifiPasswordOpen = false
                                        cc.wifiPasswordError = ""
                                    }
                                }
                            }
                            Rectangle {
                                width: cc.btpx(80)
                                height: cc.btpx(24)
                                radius: cc.btpx(6)
                                color: Qt.alpha(cc.theme.accent || "#89b4fa", 0.18)
                                border.color: Qt.alpha(cc.theme.accent || "#89b4fa", 0.35)
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Open Wi‑Fi"
                                    color: cc.theme.accent || "#89b4fa"
                                    font.pixelSize: cc.btfont(9)
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cc.openSecureWifiManager()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: btManager
        visible: cc.btManagerOpen

        anchors { top: true; right: true }
        margins { top: 44; right: 10 }

        implicitWidth: cc.btpx(340)
        implicitHeight: Math.min(btManagerCol.implicitHeight + cc.btpx(24), cc.screen.height - cc.btpx(58))

        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Behavior on implicitHeight {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        onVisibleChanged: {
            if (visible) {
                refreshConnectivity()
                refreshBtScan()
            }
        }

        Rectangle {
            id: btManagerCard
            anchors.fill: parent
            radius: cc.btpx(14)
            color: cc.theme.bg || "#1e1e2e"
            border.color: cc.theme.dim || "#45475a"
            border.width: 1
            clip: true
            opacity: cc.btManagerOpen ? 1 : 0

            transform: Translate {
                y: cc.btManagerOpen ? 0 : -cc.btpx(14)
                Behavior on y {
                    NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Column {
                id: btManagerCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: cc.btpx(12) }
                spacing: cc.btpx(8)

                RowLayout {
                    width: parent.width
                    height: cc.btpx(24)
                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: "Bluetooth Manager"
                        color: cc.theme.fg || "#cdd6f4"
                        font.pixelSize: cc.btfont(11)
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.weight: Font.Medium
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "✕"
                        color: btCloseMa.containsMouse ? (cc.theme.red || "#f38ba8") : (cc.theme.muted || "#585b70")
                        font.pixelSize: cc.btfont(8)
                        font.family: "JetBrainsMono Nerd Font Propo"
                        MouseArea {
                            id: btCloseMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cc.btManagerOpen = false
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: cc.btpx(40)
                    radius: cc.btpx(8)
                    color: Qt.alpha(cc.theme.dim || "#45475a", 0.22)
                    border.color: Qt.alpha(cc.theme.accent || "#89b4fa", 0.22)
                    border.width: 1
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: cc.btpx(10)
                        anchors.rightMargin: cc.btpx(10)
                        spacing: cc.btpx(8)
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.btEnabled ? "󰂱" : "󰂲"
                            color: cc.btEnabled ? (cc.theme.accent || "#89b4fa") : (cc.theme.muted || "#585b70")
                            font.pixelSize: cc.btfont(13)
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.hasBluetoothDevice
                                ? (cc.btEnabled ? "Bluetooth On" : "Bluetooth Off")
                                : cc.bluetoothUnavailableLabel("Bluetooth adapter not found")
                            color: cc.theme.fg || "#cdd6f4"
                            font.pixelSize: cc.btfont(11)
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.hasBluetoothDevice ? (cc.btEnabled ? "Disable" : "Enable") : ""
                            color: cc.theme.accent || "#89b4fa"
                            font.pixelSize: cc.btfont(11)
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }
                    MouseArea {
                        id: btPowerMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: cc.hasBluetoothDevice
                        onClicked: {
                            cc.runBluetoothctl(["power", cc.btEnabled ? "off" : "on"])
                            refreshConnectivity()
                            refreshBtScan()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: cc.btpx(34)
                    radius: cc.btpx(8)
                    color: btScanMa.containsMouse
                        ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.14)
                        : Qt.alpha(cc.theme.dim || "#45475a", 0.18)
                    border.color: btScanMa.containsMouse
                        ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.32)
                        : Qt.alpha(cc.theme.dim || "#45475a", 0.3)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: cc.btpx(10)
                        anchors.rightMargin: cc.btpx(10)
                        spacing: cc.btpx(8)
                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: cc.hasBluetoothDevice ? "Scan nearby devices" : cc.bluetoothUnavailableLabel("No Bluetooth adapter found")
                            color: cc.hasBluetoothDevice ? (cc.theme.muted || "#585b70") : (cc.theme.red || "#f38ba8")
                            font.pixelSize: cc.btfont(11)
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: cc.btpx(6)
                            Row {
                                visible: cc.hasBluetoothDevice && cc.btScanning
                                spacing: cc.btpx(2)
                                Repeater {
                                    model: 3
                                    delegate: Rectangle {
                                        width: cc.btpx(4); height: cc.btpx(4); radius: cc.btpx(2)
                                        color: cc.theme.accent || "#89b4fa"
                                        opacity: cc.btScanTicks === (index + 1) ? 1 : 0.25
                                    }
                                }
                            }
                            Text {
                                text: cc.hasBluetoothDevice ? (cc.btScanning ? "Scanning" : "Scan") : ""
                                color: cc.theme.accent || "#89b4fa"
                                font.pixelSize: cc.btfont(11)
                                font.family: "JetBrainsMono Nerd Font Propo"
                            }
                        }
                    }
                    MouseArea {
                        id: btScanMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: cc.hasBluetoothDevice
                        onClicked: {
                            if (cc.hasBluetoothctl)
                                Quickshell.execDetached(["bash", "-lc", "bluetoothctl --timeout 6 scan on >/dev/null 2>&1"])
                            if (!cc.btScanning) {
                                cc.btScanning = true
                                cc.btScanTicks = 0
                                btRescanTimer.restart()
                            }
                        }
                    }
                }

                Flickable {
                    width: parent.width
                    height: Math.min(Math.max(btListCol.implicitHeight, cc.btpx(86)), cc.btpx(270))
                    contentHeight: btListCol.implicitHeight
                    clip: true

                    Column {
                        id: btListCol
                        width: parent.width
                        spacing: cc.btpx(4)

                        Repeater {
                            model: cc.btDevices
                            delegate: Rectangle {
                                required property var modelData
                                width: btListCol.width
                                height: cc.btpx(66)
                                radius: cc.btpx(8)
                                color: btMgrItemMa.containsMouse
                                    ? Qt.alpha(cc.theme.accent || "#89b4fa", 0.12)
                                    : Qt.alpha(cc.theme.dim || "#45475a", 0.22)
                                border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.35)
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: cc.btpx(10)
                                    anchors.rightMargin: cc.btpx(10)
                                    anchors.topMargin: cc.btpx(8)
                                    anchors.bottomMargin: cc.btpx(8)
                                    spacing: cc.btpx(6)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: cc.btpx(8)

                                        Text {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: "󰂯"
                                            color: cc.theme.accent || "#89b4fa"
                                            font.pixelSize: cc.btfont(12)
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            text: modelData.name
                                            color: cc.theme.fg || "#cdd6f4"
                                            font.pixelSize: cc.btfont(11)
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignVCenter
                                            visible: modelData.battery >= 0
                                            text: "󰁹 " + modelData.battery + "%"
                                            color: cc.theme.muted || "#585b70"
                                            font.pixelSize: cc.btfont(9)
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: modelData.connected ? "connected" : (modelData.trusted ? "trusted" : "untrusted")
                                            color: modelData.connected
                                                ? (cc.theme.accent || "#89b4fa")
                                                : modelData.trusted
                                                    ? (cc.theme.green || "#a6e3a1")
                                                    : (cc.theme.red || "#f38ba8")
                                            font.pixelSize: cc.btfont(9)
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: cc.btpx(6)

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            width: actConnect.implicitWidth + cc.btpx(12)
                                            height: cc.btpx(20)
                                            radius: cc.btpx(10)
                                            visible: !modelData.connected
                                            color: Qt.alpha(cc.theme.accent || "#89b4fa", 0.16)
                                            Text {
                                                id: actConnect
                                                anchors.centerIn: parent
                                                text: "connect"
                                                color: cc.theme.accent || "#89b4fa"
                                                font.pixelSize: cc.btfont(9)
                                                font.family: "JetBrainsMono Nerd Font Propo"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    cc.runBluetoothctl(["connect", modelData.mac])
                                                    refreshConnectivity()
                                                }
                                            }
                                        }
                                        Rectangle {
                                            width: actDisconnect.implicitWidth + cc.btpx(12)
                                            height: cc.btpx(20)
                                            radius: cc.btpx(10)
                                            visible: modelData.connected
                                            color: Qt.alpha("#fab387", 0.16)
                                            Text {
                                                id: actDisconnect
                                                anchors.centerIn: parent
                                                text: "disconnect"
                                                color: "#fab387"
                                                font.pixelSize: cc.btfont(9)
                                                font.family: "JetBrainsMono Nerd Font Propo"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    cc.runBluetoothctl(["disconnect", modelData.mac])
                                                    refreshConnectivity()
                                                }
                                            }
                                        }
                                        Rectangle {
                                            width: actRemove.implicitWidth + cc.btpx(12)
                                            height: cc.btpx(20)
                                            radius: cc.btpx(10)
                                            color: Qt.alpha(cc.theme.red || "#f38ba8", 0.16)
                                            Text {
                                                id: actRemove
                                                anchors.centerIn: parent
                                                text: "remove"
                                                color: cc.theme.red || "#f38ba8"
                                                font.pixelSize: cc.btfont(9)
                                                font.family: "JetBrainsMono Nerd Font Propo"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    cc.runBluetoothctl(["remove", modelData.mac])
                                                    refreshConnectivity()
                                                }
                                            }
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: btMgrItemMa
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }

                        Rectangle {
                            visible: cc.btDevices.length === 0
                            width: parent.width
                            height: cc.btpx(76)
                            radius: cc.btpx(8)
                            color: Qt.alpha(cc.theme.dim || "#45475a", 0.18)
                            border.color: Qt.alpha(cc.theme.dim || "#45475a", 0.35)
                            border.width: 1
                            Column {
                                anchors.centerIn: parent
                                spacing: cc.btpx(4)
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: cc.hasBluetoothDevice ? "No devices found" : cc.bluetoothUnavailableLabel("Bluetooth adapter not detected")
                                    color: cc.hasBluetoothDevice ? (cc.theme.fg || "#cdd6f4") : (cc.theme.red || "#f38ba8")
                                    font.pixelSize: cc.btfont(11)
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: cc.hasBluetoothDevice
                                        ? "Click Scan to discover"
                                        : (cc.hasBluetoothctl ? "Enable Bluetooth in system" : "Use Omarchy Bluetooth TUI")
                                    color: cc.theme.muted || "#585b70"
                                    font.pixelSize: cc.btfont(9)
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
