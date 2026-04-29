import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var theme: ({})
    property var barWindow: null
    property bool barOnBottom: false
    property bool quietMode: false
    property bool showing: false
    property bool loading: false
    property bool ok: true
    property string errorText: ""
    property var events: []
    property date now: new Date()
    property bool hovered: false
    property bool showBadge: false
    readonly property var displayEvents: events.filter(event => shouldShowEvent(event))

    readonly property color cBg: theme.bg || "#1e1e2e"
    readonly property color cFg: theme.fg || "#cdd6f4"
    readonly property color cMuted: theme.muted || "#585b70"
    readonly property color cDim: theme.dim || "#45475a"
    readonly property color cAccent: theme.accent || "#89b4fa"
    readonly property color cGreen: theme.green || "#a6e3a1"
    readonly property color cRed: theme.red || "#f38ba8"
    readonly property color cYellow: theme.yellow || "#f9e2af"
    readonly property int popupW: 390
    readonly property int popupH: Math.min(460, Math.max(170, 94 + displayEvents.length * 58))
    readonly property int nextSeconds: nextEventSeconds()
    readonly property int nextMinutes: nextEventMinutes()
    readonly property bool urgentMeeting: nextSeconds > 0 && nextSeconds < 600
    readonly property bool activeMeeting: hasActiveMeeting()
    readonly property string statusText: {
        if (!ok) return "Calendar unavailable"
        if (displayEvents.length === 0) return "No events today"
        if (nextMinutes >= 0 && nextMinutes <= 60) return "Next in " + nextMinutes + "m"
        return displayEvents.length + " event" + (displayEvents.length === 1 ? "" : "s") + " today"
    }

    implicitWidth: iconRow.implicitWidth
    implicitHeight: 28

    function refresh() {
        if (loading || quietMode)
            return

        loading = true
        eventsProc.running = false
        eventsProc.running = true
    }

    function nextEventSeconds() {
        const current = root.now.getTime()
        let best = -1

        for (let i = 0; i < root.events.length; i++) {
            const event = root.events[i]
            if (event.allDay)
                continue

            const diff = Math.ceil((new Date(event.start).getTime() - current) / 1000)
            if (diff >= 0 && (best < 0 || diff < best))
                best = diff
        }

        return best
    }

    function hasActiveMeeting() {
        const current = root.now.getTime()

        for (let i = 0; i < root.events.length; i++) {
            const event = root.events[i]
            if (event.allDay)
                continue

            const start = new Date(event.start).getTime()
            const end = new Date(event.end).getTime()
            if (start <= current && current < end)
                return true
        }

        return false
    }

    function nextEventMinutes() {
        const current = root.now.getTime()
        let best = -1

        for (let i = 0; i < root.events.length; i++) {
            const event = root.events[i]
            if (event.allDay)
                continue

            const diff = Math.ceil((new Date(event.start).getTime() - current) / 60000)
            if (diff >= 0 && (best < 0 || diff < best))
                best = diff
        }

        return best
    }

    function rowSubtext(event) {
        const parts = [event.timeLabel || "All day"]
        if (event.location)
            parts.push(event.location)
        else if (event.conferenceUrl)
            parts.push("Video meeting")
        return parts.join("  -  ")
    }

    function shouldShowEvent(event) {
        return !(event.allDay && event.title === "Home")
    }

    function eventAccentColor(event) {
        if (event.allDay)
            return root.cAccent

        const current = root.now.getTime()
        const start = new Date(event.start).getTime()
        const end = new Date(event.end).getTime()
        const secondsUntilStart = Math.ceil((start - current) / 1000)

        if (start <= current && current < end)
            return root.cYellow
        if (secondsUntilStart > 0 && secondsUntilStart < 600)
            return root.cRed
        if (current < start)
            return root.cGreen
        return root.cDim
    }

    function openUrl(url) {
        if (!url)
            return

        showing = false
        Quickshell.execDetached(["xdg-open", url])
    }

    Component.onCompleted: refresh()
    onShowingChanged: if (showing) refresh()
    onQuietModeChanged: if (!quietMode) refresh()

    Process {
        id: eventsProc
        command: [
            "bash",
            "-lc",
            "if command -v nika-google-calendar >/dev/null 2>&1; then nika-google-calendar today; else printf '%s\\n' '{\"ok\":false,\"error\":\"nika-google-calendar is not installed\",\"events\":[]}'; fi"
        ]
        running: false
        stdout: SplitParser {
            property string buf: ""
            onRead: data => buf += data + "\n"
        }
        onExited: {
            root.loading = false

            try {
                const parsed = JSON.parse(eventsProc.stdout.buf.trim() || "{}")
                root.ok = parsed.ok !== false
                root.errorText = parsed.error || ""
                root.events = Array.isArray(parsed.events) ? parsed.events : []
            } catch (e) {
                root.ok = false
                root.errorText = "Could not parse calendar events"
                root.events = []
            }

            eventsProc.stdout.buf = ""
        }
    }

    Timer {
        interval: 300000
        repeat: true
        running: !root.quietMode
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30000
        repeat: true
        running: !root.quietMode
        onTriggered: root.now = new Date()
    }

    Row {
        id: iconRow
        anchors.centerIn: parent
        spacing: 3

        Text {
            id: iconText
            anchors.verticalCenter: parent.verticalCenter
            text: "󰸗"
            color: root.urgentMeeting
                ? root.cRed
                : root.activeMeeting
                    ? root.cYellow
                    : root.showing ? root.cAccent : root.cMuted
            opacity: root.urgentMeeting || root.activeMeeting || root.hovered || root.showing ? 1 : 0.72
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            SequentialAnimation on scale {
                running: root.urgentMeeting
                loops: Animation.Infinite
                NumberAnimation { to: 1.4; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            id: badge
            anchors.verticalCenter: parent.verticalCenter
            width: badgeText.visible ? badgeText.implicitWidth + 8 : 0
            height: 15
            radius: 8
            color: Qt.alpha(root.urgentMeeting ? root.cRed : root.cAccent, 0.16)
            border.color: Qt.alpha(root.urgentMeeting ? root.cRed : root.cAccent, 0.35)
            border.width: badgeText.visible && root.showBadge ? 1 : 0
            visible: badgeText.visible && root.showBadge

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: root.nextMinutes >= 0 && root.nextMinutes <= 60
                    ? String(root.nextMinutes) + "m"
                    : (root.displayEvents.length > 0 ? String(root.displayEvents.length) : "")
                visible: text.length > 0
                color: root.urgentMeeting ? root.cRed : root.cAccent
                font.pixelSize: 8
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.DemiBold
            }
        }
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
            text: root.statusText
            color: root.cFg
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.showing = !root.showing
    }

    PopupWindow {
        id: popup
        visible: root.showing && !root.quietMode && root.barWindow !== null
        color: "transparent"
        implicitWidth: root.popupW
        implicitHeight: root.popupH
        anchor.window: root.barWindow
        anchor.rect.x: root.barWindow
            ? Math.max(12, Math.min(root.barWindow.width - width - 12, root.mapToItem(null, 0, 0).x + root.width / 2 - width / 2))
            : 0
        anchor.rect.y: root.barOnBottom ? -(height + 8) : ((root.barWindow ? root.barWindow.height : 0) + 8)

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: root.cBg
            border.color: root.cDim
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Today"
                            color: root.cFg
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.statusText
                            color: root.ok ? root.cMuted : root.cRed
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: root.loading ? "󰔟" : "󰑐"
                        color: root.cMuted
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -7
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refresh()
                        }
                    }

                    Text {
                        text: "󰅖"
                        color: root.cMuted
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -7
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showing = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(root.cFg, 0.10)
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: eventColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: eventColumn
                        width: parent.width
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 62
                            visible: !root.ok || root.displayEvents.length === 0

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 20
                                text: root.ok ? "No events scheduled for today" : root.errorText
                                color: root.ok ? root.cMuted : root.cRed
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }
                        }

                        Repeater {
                            model: root.displayEvents.length

                            Rectangle {
                                id: row
                                width: eventColumn.width
                                height: 52
                                radius: 9
                                color: rowMouse.containsMouse ? Qt.alpha(root.cFg, 0.06) : Qt.alpha(root.cFg, 0.025)
                                border.color: Qt.alpha(root.cFg, rowMouse.containsMouse ? 0.16 : 0.08)
                                border.width: 1

                                property var event: root.displayEvents[index]

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openUrl(row.event.openUrl)
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 9
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 4
                                        Layout.fillHeight: true
                                        Layout.topMargin: 10
                                        Layout.bottomMargin: 10
                                        radius: 2
                                        color: root.eventAccentColor(row.event)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Text {
                                            text: row.event.title
                                            color: root.cFg
                                            font.pixelSize: 11
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: root.rowSubtext(row.event)
                                            color: root.cMuted
                                            font.pixelSize: 9
                                            font.family: "JetBrainsMono Nerd Font"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        visible: row.event.conferenceUrl && row.event.conferenceUrl.length > 0
                                        text: "󰍫"
                                        color: root.cAccent
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono Nerd Font"

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -8
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.openUrl(row.event.conferenceUrl)
                                        }
                                    }

                                    Text {
                                        text: "󰏌"
                                        color: root.cMuted
                                        font.pixelSize: 12
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
