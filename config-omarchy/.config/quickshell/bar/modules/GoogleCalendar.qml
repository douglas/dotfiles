import "../../style" as Style
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property var theme: ({
    })
    property var settings: null
    property var barWindow: null
    property bool barOnBottom: false
    property int overlayBarOffset: 44
    property real overlayScale: 1.18
    property bool quietMode: false
    property bool showTrigger: true
    property bool showing: false
    property bool loading: false
    property bool ok: true
    property string errorText: ""
    property string eventRequestDate: ""
    property var events: []
    property date now: new Date()
    property date selectedDate: new Date()
    property int viewYear: selectedDate.getFullYear()
    property int viewMonth: selectedDate.getMonth()
    property bool hovered: false
    property bool showBadge: false
    property bool settingsOpen: false
    readonly property var displayEvents: events.filter((event) => {
        return shouldShowEvent(event);
    })
    readonly property string selectedDateKey: Qt.formatDate(selectedDate, "yyyy-MM-dd")
    readonly property string todayKey: Qt.formatDate(now, "yyyy-MM-dd")
    readonly property bool selectedIsToday: selectedDateKey === todayKey
    readonly property string selectedLabel: selectedIsToday ? "Today" : Qt.formatDate(selectedDate, "ddd, MMM d")
    readonly property bool eventsEnabled: settings ? settings.googleCalendarEventsEnabled : false
    readonly property color cBg: theme.bg || "#1e1e2e"
    readonly property color cFg: theme.fg || "#cdd6f4"
    readonly property color cMuted: theme.muted || "#585b70"
    readonly property color cDim: theme.dim || "#45475a"
    readonly property color cAccent: theme.accent || "#89b4fa"
    readonly property color cGreen: theme.green || "#a6e3a1"
    readonly property color cRed: theme.red || "#f38ba8"
    readonly property color cYellow: theme.yellow || "#f9e2af"
    readonly property int popupW: overlayPx(320)
    readonly property int calendarRows: Math.ceil((firstDayOfMonth(viewYear, viewMonth) + daysInMonth(viewYear, viewMonth)) / 7)
    readonly property int calendarGridBaseHeight: calendarRows * 28 + Math.max(0, calendarRows - 1) * 2
    readonly property int eventRows: Math.max(1, Math.min(4, displayEvents.length))
    readonly property int eventListBaseHeight: loading || !ok || displayEvents.length === 0 ? 50 : eventRows * 42 + Math.max(0, eventRows - 1) * 6
    readonly property int settingsPanelBaseHeight: 58
    readonly property int popupH: overlayPx(settingsOpen ? 388 : eventsEnabled ? 342 + eventListBaseHeight : 306)
    readonly property int nextSeconds: nextEventSeconds()
    readonly property int nextMinutes: nextEventMinutes()
    readonly property bool urgentMeeting: selectedIsToday && nextSeconds > 0 && nextSeconds < 600
    readonly property bool activeMeeting: selectedIsToday && hasActiveMeeting()
    readonly property string statusText: {
        if (!eventsEnabled)
            return "Calendar only";

        if (!ok)
            return "Calendar unavailable";

        if (displayEvents.length === 0)
            return selectedIsToday ? "No events today" : "No events on " + selectedLabel;

        if (selectedIsToday && nextMinutes >= 0 && nextMinutes <= 60)
            return "Next in " + nextMinutes + "m";

        return displayEvents.length + " event" + (displayEvents.length === 1 ? "" : "s") + (selectedIsToday ? " today" : "");
    }

    function overlayPx(value) {
        return Math.round(value * Math.max(1, overlayScale));
    }

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate();
    }

    function firstDayOfMonth(y, m) {
        const d = new Date(y, m, 1).getDay();
        return (d + 6) % 7;
    }

    function monthTitle() {
        const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        return months[viewMonth] + " " + viewYear;
    }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear--;
        } else {
            viewMonth--;
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear++;
        } else {
            viewMonth++;
        }
    }

    function selectDay(day) {
        const nextDate = new Date(viewYear, viewMonth, day);
        if (Qt.formatDate(nextDate, "yyyy-MM-dd") === selectedDateKey)
            return ;

        if (eventsEnabled) {
            events = [];
            ok = true;
            errorText = "";
            loading = true;
        }
        selectedDate = new Date(viewYear, viewMonth, day);
    }

    function resetToToday() {
        selectedDate = new Date();
        viewYear = selectedDate.getFullYear();
        viewMonth = selectedDate.getMonth();
    }

    function setEventsEnabled(enabled) {
        if (!settings)
            return ;

        settings.googleCalendarEventsEnabled = enabled;
    }

    function refresh(clearEvents) {
        if (quietMode || !eventsEnabled) {
            loading = false;
            ok = true;
            errorText = "";
            events = [];
            return ;
        }
        loading = true;
        ok = true;
        errorText = "";
        if (clearEvents)
            events = [];

        eventRequestDate = selectedDateKey;
        eventsProc.stdout.buf = "";
        eventsProc.running = false;
        eventsProc.running = true;
    }

    function nextEventSeconds() {
        const current = root.now.getTime();
        let best = -1;
        for (let i = 0; i < root.events.length; i++) {
            const event = root.events[i];
            if (event.allDay)
                continue;

            const diff = Math.ceil((new Date(event.start).getTime() - current) / 1000);
            if (diff >= 0 && (best < 0 || diff < best))
                best = diff;

        }
        return best;
    }

    function hasActiveMeeting() {
        const current = root.now.getTime();
        for (let i = 0; i < root.events.length; i++) {
            const event = root.events[i];
            if (event.allDay)
                continue;

            const start = new Date(event.start).getTime();
            const end = new Date(event.end).getTime();
            if (start <= current && current < end)
                return true;

        }
        return false;
    }

    function nextEventMinutes() {
        const current = root.now.getTime();
        let best = -1;
        for (let i = 0; i < root.events.length; i++) {
            const event = root.events[i];
            if (event.allDay)
                continue;

            const diff = Math.ceil((new Date(event.start).getTime() - current) / 60000);
            if (diff >= 0 && (best < 0 || diff < best))
                best = diff;

        }
        return best;
    }

    function rowSubtext(event) {
        const parts = [event.timeLabel || "All day"];
        if (event.location)
            parts.push(event.location);
        else if (event.conferenceUrl)
            parts.push("Video meeting");
        return parts.join("  -  ");
    }

    function shouldShowEvent(event) {
        return !(event.allDay && event.title === "Home");
    }

    function eventAccentColor(event) {
        if (event.allDay)
            return root.cAccent;

        const current = root.now.getTime();
        const start = new Date(event.start).getTime();
        const end = new Date(event.end).getTime();
        const secondsUntilStart = Math.ceil((start - current) / 1000);
        if (start <= current && current < end)
            return root.cYellow;

        if (secondsUntilStart > 0 && secondsUntilStart < 600)
            return root.cRed;

        if (current < start)
            return root.cGreen;

        return root.cDim;
    }

    function openUrl(url) {
        if (!url)
            return ;

        showing = false;
        Quickshell.execDetached(["xdg-open", url]);
    }

    implicitWidth: showTrigger ? iconRow.implicitWidth : 0
    implicitHeight: showTrigger ? 28 : 0
    Component.onCompleted: refresh()
    onShowingChanged: {
        if (showing && eventsEnabled)
            refresh();

        if (!showing)
            settingsOpen = false;

    }
    onSelectedDateKeyChanged: {
        if (showing)
            refresh(true);

    }
    onEventsEnabledChanged: refresh(true)
    onQuietModeChanged: {
        if (!quietMode && eventsEnabled)
            refresh();

    }

    Process {
        id: eventsProc

        command: ["bash", "-lc", "helper=\"$HOME/.local/bin/kurama-google-calendar\"; " + "if [ -x \"$helper\" ]; then \"$helper\" today " + root.eventRequestDate + "; " + "elif command -v kurama-google-calendar >/dev/null 2>&1; then kurama-google-calendar today " + root.eventRequestDate + "; " + "else printf '%s\\n' '{\"ok\":false,\"error\":\"kurama-google-calendar is not installed\",\"events\":[]}'; fi"]
        running: false
        onExited: {
            const output = eventsProc.stdout.buf.trim();
            eventsProc.stdout.buf = "";
            if (output === "")
                return ;

            try {
                const parsed = JSON.parse(output || "{}");
                const responseDate = parsed.date || root.eventRequestDate;
                if (responseDate !== root.selectedDateKey)
                    return ;

                root.loading = false;
                root.ok = parsed.ok !== false;
                root.errorText = parsed.error || "";
                root.events = Array.isArray(parsed.events) ? parsed.events : [];
            } catch (e) {
                if (root.eventRequestDate !== root.selectedDateKey)
                    return ;

                root.ok = false;
                root.errorText = "Could not parse calendar events";
                root.events = [];
                root.loading = false;
            }
        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                return buf += data + "\n";
            }
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

        visible: root.showTrigger
        anchors.centerIn: parent
        spacing: 3

        Text {
            id: iconText

            anchors.verticalCenter: parent.verticalCenter
            text: "󰸗"
            color: root.urgentMeeting ? root.cRed : root.activeMeeting ? root.cYellow : root.showing ? root.cAccent : root.cMuted
            opacity: root.urgentMeeting || root.activeMeeting || root.hovered || root.showing ? 1 : 0.72
            font.pixelSize: Style.Typography.titleSmall
            font.family: Style.Typography.mono
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
                text: root.nextMinutes >= 0 && root.nextMinutes <= 60 ? String(root.nextMinutes) + "m" : (root.displayEvents.length > 0 ? String(root.displayEvents.length) : "")
                visible: text.length > 0
                color: root.urgentMeeting ? root.cRed : root.cAccent
                font.pixelSize: Style.Typography.micro
                font.family: Style.Typography.mono
                font.weight: Font.DemiBold
            }

        }

    }

    Rectangle {
        visible: root.showTrigger && root.hovered && !root.showing
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
            font.pixelSize: Style.Typography.label
            font.family: Style.Typography.mono
        }

    }

    MouseArea {
        enabled: root.showTrigger
        anchors.fill: parent
        anchors.margins: -5
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.showing = !root.showing
    }

    PanelWindow {
        visible: root.showing && !root.quietMode
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Top

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {
                root.settingsOpen = false;
                root.showing = false;
            }
        }

    }

    WlrLayershell {
        id: popup

        visible: root.showing && !root.quietMode
        color: "transparent"
        implicitWidth: root.popupW
        implicitHeight: root.popupH
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        namespace: "google-calendar-overlay"

        anchors {
            top: !root.barOnBottom
            bottom: root.barOnBottom
            left: true
            right: true
        }

        margins {
            top: !root.barOnBottom ? root.overlayBarOffset : 0
            bottom: root.barOnBottom ? root.overlayBarOffset : 0
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {
                root.settingsOpen = false;
                root.showing = false;
            }
        }

        Rectangle {
            id: popupCard

            width: root.popupW
            height: root.popupH
            anchors.centerIn: parent
            radius: 12
            color: root.cBg
            border.color: Qt.alpha(root.cDim, 0.8)
            border.width: 1
            clip: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: {
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.overlayPx(14)
                spacing: root.overlayPx(3)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: parent.width
                    spacing: 10

                    Text {
                        text: "󰸗"
                        color: root.cAccent
                        font.pixelSize: Style.Typography.scaledHeading(root.overlayScale)
                        font.family: Style.Typography.mono
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: root.selectedLabel
                            color: root.cFg
                            font.pixelSize: Style.Typography.scaledBody(root.overlayScale)
                            font.family: Style.Typography.monoPropo
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.statusText
                            color: root.ok ? root.cMuted : root.cRed
                            font.pixelSize: Style.Typography.scaledBodySmall(root.overlayScale)
                            font.family: Style.Typography.monoPropo
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Row {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        spacing: root.overlayPx(8)

                        Rectangle {
                            width: root.overlayPx(22)
                            height: root.overlayPx(22)
                            radius: 0
                            color: root.settingsOpen ? Qt.alpha(root.cAccent, 0.18) : "transparent"
                            border.width: root.settingsOpen ? 1 : 0
                            border.color: Qt.alpha(root.cAccent, 0.45)

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: root.settingsOpen ? root.cAccent : settingsHover.containsMouse ? root.cAccent : Qt.alpha(root.cMuted, 0.75)
                                font.pixelSize: Style.Typography.scaledBodyLarge(root.overlayScale)
                                font.family: Style.Typography.mono
                            }

                            MouseArea {
                                id: settingsHover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.settingsOpen = !root.settingsOpen
                            }

                        }

                        Rectangle {
                            visible: root.eventsEnabled
                            width: root.overlayPx(22)
                            height: root.overlayPx(22)
                            radius: 0
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: refreshHover.containsMouse ? root.cAccent : root.cMuted
                                font.pixelSize: Style.Typography.scaledBodyLarge(root.overlayScale)
                                font.family: Style.Typography.mono
                            }

                            MouseArea {
                                id: refreshHover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.refresh()
                            }

                        }

                        Rectangle {
                            width: root.overlayPx(22)
                            height: root.overlayPx(22)
                            radius: 0
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: closeHover.containsMouse ? root.cRed : root.cMuted
                                font.pixelSize: Style.Typography.scaledBodyLarge(root.overlayScale)
                                font.family: Style.Typography.mono
                            }

                            MouseArea {
                                id: closeHover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showing = false
                            }

                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(root.cDim, 0.55)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: implicitHeight
                    Layout.maximumHeight: implicitHeight
                    spacing: root.overlayPx(6)

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "‹"
                            color: prevMonthHover.containsMouse ? root.cAccent : root.cMuted
                            font.pixelSize: Style.Typography.scaledTitle(root.overlayScale)
                            font.family: Style.Typography.mono
                            Layout.preferredWidth: root.overlayPx(24)
                            horizontalAlignment: Text.AlignHCenter

                            MouseArea {
                                id: prevMonthHover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.prevMonth()
                            }

                        }

                        Text {
                            text: root.monthTitle()
                            color: root.cFg
                            font.pixelSize: Style.Typography.scaledBody(root.overlayScale)
                            font.family: Style.Typography.monoPropo
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "›"
                            color: nextMonthHover.containsMouse ? root.cAccent : root.cMuted
                            font.pixelSize: Style.Typography.scaledTitle(root.overlayScale)
                            font.family: Style.Typography.mono
                            Layout.preferredWidth: root.overlayPx(24)
                            horizontalAlignment: Text.AlignHCenter

                            MouseArea {
                                id: nextMonthHover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.nextMonth()
                            }

                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                            Text {
                                text: modelData
                                color: root.cMuted
                                font.pixelSize: Style.Typography.scaledLabel(root.overlayScale)
                                font.family: Style.Typography.monoPropo
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }

                        }

                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: root.overlayPx(root.calendarGridBaseHeight)
                        Layout.maximumHeight: root.overlayPx(root.calendarGridBaseHeight)
                        columns: 7
                        columnSpacing: 0
                        rowSpacing: root.overlayPx(2)

                        Repeater {
                            model: root.calendarRows * 7

                            Item {
                                readonly property int dayNum: index - root.firstDayOfMonth(root.viewYear, root.viewMonth) + 1
                                readonly property bool isValid: dayNum > 0 && dayNum <= root.daysInMonth(root.viewYear, root.viewMonth)
                                readonly property date cellDate: new Date(root.viewYear, root.viewMonth, Math.max(1, dayNum))
                                readonly property bool isSelected: isValid && Qt.formatDate(cellDate, "yyyy-MM-dd") === root.selectedDateKey
                                readonly property bool isToday: isValid && Qt.formatDate(cellDate, "yyyy-MM-dd") === root.todayKey

                                Layout.fillWidth: true
                                Layout.preferredHeight: root.overlayPx(28)

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: root.overlayPx(26)
                                    height: root.overlayPx(24)
                                    radius: root.overlayPx(8)
                                    visible: isValid
                                    color: isSelected ? Qt.alpha(root.cAccent, 0.28) : isToday ? Qt.alpha(root.cAccent, 0.12) : dayHover.containsMouse ? Qt.alpha(root.cFg, 0.08) : "transparent"
                                    border.color: isSelected ? Qt.alpha(root.cAccent, 0.55) : "transparent"
                                    border.width: isSelected ? 1 : 0
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: isValid ? dayNum : ""
                                    color: isSelected ? root.cAccent : root.cFg
                                    opacity: isValid ? 1 : 0
                                    font.pixelSize: Style.Typography.scaledBodySmall(root.overlayScale)
                                    font.family: Style.Typography.monoPropo
                                    font.weight: isSelected || isToday ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    id: dayHover

                                    anchors.fill: parent
                                    enabled: isValid
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectDay(dayNum)
                                }

                            }

                        }

                    }

                }

                Rectangle {
                    visible: root.settingsOpen
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(root.cDim, 0.55)
                }

                RowLayout {
                    visible: root.settingsOpen
                    Layout.fillWidth: true

                    Text {
                        text: "Settings"
                        color: root.cFg
                        font.pixelSize: Style.Typography.scaledBody(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                }

                Item {
                    visible: root.settingsOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.overlayPx(root.settingsPanelBaseHeight)

                    RowLayout {
                        anchors.fill: parent
                        spacing: root.overlayPx(10)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: root.overlayPx(3)

                            Text {
                                text: "Google events"
                                color: root.cFg
                                font.pixelSize: Style.Typography.scaledBody(root.overlayScale)
                                font.family: Style.Typography.monoPropo
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: root.eventsEnabled ? "Fetch activities for the selected day." : "Keep the popup as a local calendar."
                                color: root.cMuted
                                font.pixelSize: Style.Typography.scaledBodySmall(root.overlayScale)
                                font.family: Style.Typography.monoPropo
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                        }

                        Rectangle {
                            Layout.preferredWidth: root.overlayPx(42)
                            Layout.preferredHeight: root.overlayPx(22)
                            radius: root.overlayPx(11)
                            color: root.eventsEnabled ? Qt.alpha(root.cAccent, 0.3) : Qt.alpha(root.cDim, 0.38)
                            border.width: 1
                            border.color: root.eventsEnabled ? Qt.alpha(root.cAccent, 0.58) : Qt.alpha(root.cAccent, 0.14)

                            Rectangle {
                                width: root.overlayPx(16)
                                height: root.overlayPx(16)
                                radius: root.overlayPx(8)
                                y: root.overlayPx(3)
                                x: root.eventsEnabled ? parent.width - width - root.overlayPx(3) : root.overlayPx(3)
                                color: root.eventsEnabled ? root.cAccent : Qt.alpha(root.cFg, 0.62)
                            }

                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setEventsEnabled(!root.eventsEnabled)
                    }

                }

                Rectangle {
                    visible: root.eventsEnabled && !root.settingsOpen
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(root.cDim, 0.55)
                }

                RowLayout {
                    visible: root.eventsEnabled && !root.settingsOpen
                    Layout.fillWidth: true

                    Text {
                        text: "Events"
                        color: root.cFg
                        font.pixelSize: Style.Typography.scaledBody(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                }

                ListView {
                    visible: root.eventsEnabled && !root.settingsOpen && !root.loading && root.ok && root.displayEvents.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.overlayPx(root.eventListBaseHeight)
                    clip: true
                    spacing: root.overlayPx(6)
                    model: root.displayEvents

                    delegate: Rectangle {
                        id: row

                        required property var modelData

                        width: ListView.view.width
                        height: root.overlayPx(42)
                        radius: 8
                        color: rowHover.hovered ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(1, 1, 1, 0.022)
                        border.color: Qt.rgba(1, 1, 1, 0.045)
                        border.width: 1

                        HoverHandler {
                            id: rowHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: false
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openUrl(row.modelData.openUrl)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.overlayPx(10)
                            anchors.rightMargin: root.overlayPx(8)
                            spacing: root.overlayPx(8)

                            Rectangle {
                                Layout.preferredWidth: 4
                                Layout.fillHeight: true
                                Layout.topMargin: root.overlayPx(9)
                                Layout.bottomMargin: root.overlayPx(9)
                                radius: 2
                                color: root.eventAccentColor(row.modelData)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    text: row.modelData.title
                                    color: root.cFg
                                    font.pixelSize: Style.Typography.scaledBody(root.overlayScale)
                                    font.family: Style.Typography.monoPropo
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: root.rowSubtext(row.modelData)
                                    color: root.cMuted
                                    font.pixelSize: Style.Typography.scaledBodySmall(root.overlayScale)
                                    font.family: Style.Typography.monoPropo
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                            }

                            Text {
                                visible: row.modelData.conferenceUrl && row.modelData.conferenceUrl.length > 0
                                text: "󰍫"
                                color: root.cAccent
                                font.pixelSize: Style.Typography.scaledBodyLarge(root.overlayScale)
                                font.family: Style.Typography.mono

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -7
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openUrl(row.modelData.conferenceUrl)
                                }

                            }

                            Text {
                                text: "󰏌"
                                color: root.cMuted
                                font.pixelSize: Style.Typography.scaledBodyLarge(root.overlayScale)
                                font.family: Style.Typography.mono
                            }

                        }

                    }

                }

                Item {
                    visible: root.eventsEnabled && !root.settingsOpen && (root.loading || !root.ok || root.displayEvents.length === 0)
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.overlayPx(root.eventListBaseHeight)

                    Column {
                        visible: root.loading
                        anchors.centerIn: parent
                        spacing: root.overlayPx(6)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰔟"
                            color: root.cAccent
                            font.pixelSize: Style.Typography.scaledBodyLarge(root.overlayScale)
                            font.family: Style.Typography.mono

                            RotationAnimation on rotation {
                                running: root.loading
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 900
                            }

                        }

                        Text {
                            text: "Loading events..."
                            color: root.cMuted
                            font.pixelSize: Style.Typography.scaledBodySmall(root.overlayScale)
                            font.family: Style.Typography.monoPropo
                        }

                    }

                    Text {
                        visible: !root.loading
                        anchors.centerIn: parent
                        width: parent.width - root.overlayPx(20)
                        text: root.ok ? "No events scheduled for " + root.selectedLabel : root.errorText
                        color: root.ok ? root.cMuted : root.cRed
                        font.pixelSize: Style.Typography.scaledBody(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        opacity: 0.65
                    }

                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.overlayPx(7)
                }

            }

        }

    }

}
