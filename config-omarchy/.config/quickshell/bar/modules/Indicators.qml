import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../style" as Style

Item {
    id: root

    property var notifServer: null
    property string accent: "#89b4fa"
    property string muted:  "#585b70"
    property string red:    "#f38ba8"
    property string green:  "#a6e3a1"
    property string fg:     "#cdd6f4"
    property bool quietMode: false
    property bool showUpdateIndicator: true
    property bool showRecordingIndicator: true

    implicitWidth:  indicatorRow.implicitWidth
    implicitHeight: 28
    visible:        (showUpdateIndicator && updateAvailable)
        || (showRecordingIndicator && isRecording)

    function refreshLiveStatus() {
        liveStatusProc.running = false
        liveStatusProc.running = true
    }

    // ── update ───────────────────────────────────────────────────
    property bool updateAvailable: false

    Process {
        id: updateChecker
        command: ["bash", "-c",
            "export PATH=\"$HOME/.local/share/omarchy/bin:$PATH\"; " +
            "omarchy-update-available 2>/dev/null; echo $?"]
        running: root.showUpdateIndicator
        stdout: SplitParser {
            property string buf: ""
            onRead: data => buf += data + "\n"
        }
        onExited: {
            var out = updateChecker.stdout.buf.toLowerCase()
            root.updateAvailable = out.indexOf("up to date") === -1
            updateChecker.stdout.buf = ""
        }
    }

    Timer {
        interval: 21600000 // 6 hours
        running:  root.showUpdateIndicator && !root.quietMode
        repeat:   true
        onTriggered: {
            updateChecker.running = false
            updateChecker.running = true
        }
    }

    property bool notifSilenced: notifServer?.dndEnabled ?? false
    property bool isRecording: false

    Process {
        id: liveStatusProc
        command: ["bash", "-c",
            "pgrep -f '^gpu-screen-recorder' > /dev/null && echo recording || echo stopped"]
        running: root.showRecordingIndicator
        stdout: SplitParser {
            onRead: data => {
                root.isRecording = data.trim() === "recording"
            }
        }
    }

    Timer {
        interval: 1000
        running:  root.showRecordingIndicator && !root.quietMode
        repeat:   true
        onTriggered: refreshLiveStatus()
    }

    onQuietModeChanged: if (!quietMode && showRecordingIndicator) refreshLiveStatus()

    // ── shell helpers ─────────────────────────────────────────────
    property int _cmdSeq: 0

    function runCmd(cmd) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { command: ["bash","-c",""]; running: false }',
            root, "proc" + (++_cmdSeq)
        )
        proc.onExited.connect(function() { proc.destroy() })
        proc.command = ["bash", "-c", "export PATH=\"$HOME/.local/share/omarchy/bin:$PATH\"; " + cmd]
        proc.running = true
    }

    function stopRecording() {
        root.isRecording = false
        runCmd("omarchy-capture-screenrecording --stop-recording")
    }

    // ── UI ────────────────────────────────────────────────────────
    Row {
        id:                     indicatorRow
        anchors.verticalCenter: parent.verticalCenter
        spacing:                8

        // update indicator
        Text {
            visible:                root.showUpdateIndicator && root.updateAvailable
            anchors.verticalCenter: parent.verticalCenter
            text:                   ""
            color:                  root.green
            font.pixelSize:         Style.Typography.barIcon
            font.family: Style.Typography.mono

            Behavior on opacity { NumberAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.runCmd(
                    "omarchy-launch-floating-terminal-with-presentation omarchy-update")
                onEntered: parent.opacity = 0.7
                onExited:  parent.opacity = 1.0
            }
        }

        // // notification silencing indicator
        // Text {
        //     visible:                root.notifSilenced
        //     anchors.verticalCenter: parent.verticalCenter
        //     text:                   "󰂛"
        //     color:                  root.accent
        //     font.pixelSize:         Style.Typography.barIcon
        //     font.family: Style.Typography.mono

        //     Behavior on opacity { NumberAnimation { duration: 150 } }

        //     MouseArea {
        //         anchors.fill: parent
        //         cursorShape:  Qt.PointingHandCursor
        //         hoverEnabled: true
        //         onClicked:    if (root.notifServer) root.notifServer.toggleDnd()
        //         onEntered:    parent.opacity = 0.7
        //         onExited:     parent.opacity = 1.0
        //     }
        // }

        // screen recording indicator — blinking red when active
        Item {
            id:                     recordingIcon
            readonly property int visualSize: Math.max(
                12,
                Math.round(Style.Typography.rightClusterIcon / 2) * 2
            )
            readonly property int stopSize: Math.max(
                4,
                Math.round((visualSize * 0.42) / 2) * 2
            )

            visible:                root.showRecordingIndicator && root.isRecording
            anchors.verticalCenter: parent.verticalCenter
            width:                  visualSize + 4
            height:                 width

            Rectangle {
                id:              recordingRing
                width:           recordingIcon.visualSize
                height:          width
                anchors.centerIn: parent
                radius:          width / 2
                color:           Qt.alpha(root.red, 0.12)
                border.color:    root.red
                border.width:    1
            }

            Rectangle {
                anchors.centerIn: recordingRing
                width:            recordingIcon.stopSize
                height:           width
                radius:           Math.max(1, Math.round(width / 4))
                color:            root.red
            }

            SequentialAnimation on opacity {
                loops:   Animation.Infinite
                running: root.isRecording
                NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked: root.stopRecording()
            }
        }
    }
}
