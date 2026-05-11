import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../style" as Style

Item {
    id: root

    property var theme: ({})
    property bool barOnBottom: false
    property int overlayBarOffset: 44
    property real overlayScale: 1.18
    property bool quietMode: false
    property bool showing: Quickshell.env("NEOSH_CCTOP_OPEN") === "1"
    property var sessions: []
    property var recentProjects: []
    property int selectedIndex: 0
    property string selectedTab: "active"
    property bool navigateMode: false
    property string notice: ""
    property double nowMs: Date.now()

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string helperPath: Quickshell.env("NEOSH_CCTOP_HELPER") || homeDir + "/.config/quickshell/scripts/neosh-cctop"
    readonly property bool useOmarchyTheme: theme.omarchyThemeLoaded === true
    readonly property color cBg: useOmarchyTheme ? theme.bg : "#1A1B26"
    readonly property bool cLightTheme: colorLuma(cBg) > 0.62
    readonly property color cPanelBorder: Qt.alpha(cTextPrimary, cLightTheme ? 0.16 : 0.10)
    readonly property color cCardBorder: Qt.alpha(cTextPrimary, cLightTheme ? 0.10 : 0.06)
    readonly property color cCardHover: cLightTheme ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.04)
    readonly property color cTextPrimary: useOmarchyTheme ? theme.fg : "#C0CAF5"
    readonly property color cTextSecondary: useOmarchyTheme ? theme.muted : "#787C99"
    readonly property color cTextMuted: cLightTheme ? Qt.alpha(cTextPrimary, 0.62) : Qt.alpha(cTextPrimary, 0.50)
    readonly property color cTextDimmed: cLightTheme ? Qt.alpha(cTextPrimary, 0.42) : Qt.alpha(cTextPrimary, 0.35)
    readonly property color cAccent: useOmarchyTheme ? theme.accent : "#89B4FA"
    readonly property color cPermission: useOmarchyTheme ? theme.red : "#F7768E"
    readonly property color cAttention: useOmarchyTheme ? theme.red : "#F7768E"
    readonly property color cWorking: useOmarchyTheme ? theme.yellow : "#E0AF68"
    readonly property color cCompacting: cWorking
    readonly property color cIdle: useOmarchyTheme ? theme.green : "#9ECE6A"
    readonly property var orderedSessions: sortedSessions()
    readonly property int permissionCount: countStatus("permission")
    readonly property int workingCount: countStatus("working")
    readonly property int idleCount: countStatus("idle")
    readonly property int totalCount: permissionCount + workingCount + idleCount
    readonly property int needsActionCount: permissionCount
    readonly property bool showTabs: recentProjects.length > 0
    readonly property int overlayWidth: 340

    signal opened()

    function colorLuma(color) {
        return (0.2126 * color.r) + (0.7152 * color.g) + (0.0722 * color.b);
    }

    function statusDisplayColor(color) {
        return cLightTheme ? Qt.darker(color, 1.45) : color;
    }

    function overlayAccentColor(color) {
        return Qt.alpha(statusDisplayColor(color), cLightTheme ? 0.72 : 0.78);
    }

    function topbarChipColor(color) {
        return Qt.alpha(statusDisplayColor(color), cLightTheme ? 0.72 : 0.82);
    }

    function overlayPx(value) {
        return Math.round(value * Math.max(1, overlayScale));
    }

    function reloadSessions() {
        if (!loadProc.running)
            loadProc.running = true;
    }

    function reload() {
        reloadSessions();

        if (!historyProc.running)
            historyProc.running = true;
    }

    function togglePanel(navigate) {
        showing = !showing;
        if (showing) {
            openPanel(navigate);
        } else {
            navigateMode = false;
        }
    }

    function openPanel(navigate) {
        showing = true;
        navigateMode = Boolean(navigate);
        opened();
        selectedIndex = Math.max(0, Math.min(selectedIndex, currentRows().length - 1));
        reload();
    }

    function hidePanel() {
        showing = false;
        navigateMode = false;
    }

    function rowHeight() {
        return selectedTab === "recent" ? 46 : 54;
    }

    function listContentHeight() {
        return Math.min(292, currentRows().length * rowHeight());
    }

    function emptyStateHeight() {
        return selectedTab === "active" ? 72 : 86;
    }

    function panelContentHeight() {
        const padding = 28;
        const header = 42;
        const dividers = 2 + (showTabs ? 1 : 0);
        const tabs = showTabs ? 30 : 0;
        const body = currentRows().length > 0 ? listContentHeight() : emptyStateHeight();
        const footer = 34;
        return Math.min(476, padding + header + dividers + tabs + body + footer);
    }

    function emptyStateMessage() {
        if (selectedTab === "active")
            return "No agent sessions running";

        return "Recent projects will appear here\nafter sessions end";
    }

    function effectiveStatus(session) {
        const status = String(session.status || "idle");
        if ((status === "waiting_permission" || status === "waiting_input" || status === "needs_attention")
                && isFreshBlockingStatus(session))
            return status;
        if (subagentCount(session) > 0)
            return "working";
        if (status === "working" || status === "compacting")
            return status;
        return "idle";
    }

    function isFreshBlockingStatus(session) {
        const parsed = Date.parse(String(session.last_activity || ""));
        if (Number.isNaN(parsed))
            return false;
        return (nowMs - parsed) <= 30 * 60 * 1000;
    }

    function statusGroup(session) {
        const status = effectiveStatus(session);
        if (status === "waiting_permission" || status === "waiting_input" || status === "needs_attention")
            return "permission";
        if (status === "working" || status === "compacting")
            return "working";
        return "idle";
    }

    function statusPriority(session) {
        const status = effectiveStatus(session);
        if (status === "waiting_permission" || status === "waiting_input" || status === "needs_attention")
            return 0;
        if (status === "working")
            return 2;
        if (status === "compacting")
            return 3;
        return 4;
    }

    function countStatus(group) {
        let count = 0;
        for (const session of sessions) {
            if (statusGroup(session) === group)
                count++;
        }
        return count;
    }

    function topbarStatusColor() {
        if (permissionCount > 0)
            return cPermission;
        if (workingCount > 0)
            return cWorking;
        if (idleCount > 0)
            return cIdle;

        return cTextMuted;
    }

    function topbarStatusDots() {
        return [
            { color: cPermission, count: permissionCount },
            { color: cWorking, count: workingCount },
            { color: cIdle, count: idleCount }
        ];
    }

    function statusColor(session) {
        const status = effectiveStatus(session);
        if (status === "waiting_permission" || status === "waiting_input" || status === "needs_attention")
            return cPermission;
        if (status === "working")
            return cWorking;
        if (status === "compacting")
            return cCompacting;
        return cIdle;
    }

    function statusLabel(session) {
        const status = effectiveStatus(session);
        if (status === "waiting_permission")
            return "Permission";
        if (status === "waiting_input" || status === "needs_attention")
            return "Waiting";
        if (status === "working")
            return "Working";
        if (status === "compacting")
            return "Compacting";
        return "Idle";
    }

    function sourceLabel(session) {
        const source = String(session.source || "");
        if (source === "opencode")
            return "OC";
        if (source === "pi")
            return "Pi";
        if (source === "codex")
            return "Codex";
        return "Claude";
    }

    function rawModelLabel(session) {
        const candidates = [
            session.model,
            session.model_name,
            session.modelName,
            session.codex_model,
            session.agent_model,
            session.agentModel
        ];

        for (const value of candidates) {
            const label = String(value || "").trim();
            if (label !== "")
                return label;
        }

        return "";
    }

    function sessionModelLabel(session) {
        const model = rawModelLabel(session);
        if (model !== "")
            return model;

        return sessionsHaveMultipleSources() ? sourceLabel(session) : "";
    }

    function sessionModelColor(session) {
        return cAccent;
    }

    function showSessionModelColumn() {
        for (const session of sessions) {
            if (sessionModelLabel(session) !== "")
                return true;
        }

        return false;
    }

    function subagentCount(session) {
        return Array.isArray(session.active_subagents) ? session.active_subagents.length : 0;
    }

    function displayName(session) {
        return String(session.session_name || session.project_name || "session");
    }

    function contextLine(session) {
        const status = effectiveStatus(session);
        if (status === "idle")
            return "";
        if (status === "compacting")
            return "Compacting context...";
        if (status === "waiting_permission")
            return String(session.notification_message || "Permission needed");
        if (status === "waiting_input" || status === "needs_attention")
            return promptSnippet(session);
        if (session.last_tool)
            return toolDisplay(session);
        return promptSnippet(session);
    }

    function promptSnippet(session) {
        const prompt = String(session.last_prompt || "");
        if (prompt === "")
            return "";
        return "\"" + prompt.slice(0, 36).replace(/\s+/g, " ") + "\"";
    }

    function toolDisplay(session) {
        const tool = String(session.last_tool || "");
        const detail = String(session.last_tool_detail || "");
        if (detail === "")
            return tool + "...";

        const lower = tool.toLowerCase();
        const fileName = detail.split("/").pop();
        if (lower === "bash")
            return "Running: " + detail.slice(0, 30);
        if (lower === "edit")
            return "Editing " + fileName;
        if (lower === "write")
            return "Writing " + fileName;
        if (lower === "read")
            return "Reading " + fileName;
        if (lower === "grep" || lower === "websearch")
            return "Searching: " + detail.slice(0, 30);
        if (lower === "glob")
            return "Finding: " + detail.slice(0, 30);
        if (lower === "webfetch")
            return "Fetching: " + detail.slice(0, 30);
        if (lower === "task" || lower === "agent")
            return "Task: " + detail.slice(0, 30);
        return tool + ": " + detail.slice(0, 30);
    }

    function relativeTime(session) {
        const parsed = Date.parse(String(session.last_activity || ""));
        if (!Number.isFinite(parsed))
            return "just now";

        const seconds = Math.floor((nowMs - parsed) / 1000);
        if (seconds <= 0)
            return "just now";
        if (seconds >= 86400)
            return Math.floor(seconds / 86400) + "d ago";
        if (seconds >= 3600)
            return Math.floor(seconds / 3600) + "h ago";
        if (seconds >= 60)
            return Math.floor(seconds / 60) + "m ago";
        return seconds + "s ago";
    }

    function sortedSessions() {
        const copy = sessions.slice();
        copy.sort((a, b) => {
            const byStatus = statusPriority(a) - statusPriority(b);
            if (byStatus !== 0)
                return byStatus;

            return Date.parse(String(b.last_activity || "")) - Date.parse(String(a.last_activity || ""));
        });
        return copy;
    }

    function activateSession(session) {
        if (!session)
            return;

        Quickshell.execDetached([
            "bash",
            root.helperPath,
            "focus",
            String(session.pid || ""),
            String(session.project_path || "")
        ]);
        notice = "Jumping to " + displayName(session);
        noticeTimer.restart();
        hidePanel();
    }

    function activateRecent(project) {
        if (!project)
            return;

        Quickshell.execDetached([
            "bash",
            root.helperPath,
            "focus",
            "",
            String(project.workspace_file || project.project_path || "")
        ]);
        notice = "Opening " + String(project.project_name || "project");
        noticeTimer.restart();
        hidePanel();
    }

    function activateCurrent() {
        if (selectedTab === "recent")
            activateRecent(recentProjects[selectedIndex]);
        else
            activateSession(orderedSessions[selectedIndex]);
    }

    function switchTab(tab) {
        if (tab === "recent" && recentProjects.length === 0)
            return;

        selectedTab = tab;
        selectedIndex = 0;
    }

    function currentRows() {
        return selectedTab === "recent" ? (recentProjects || []) : (orderedSessions || []);
    }

    implicitWidth: barPill.implicitWidth
    implicitHeight: 28
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    visible: true

    onSessionsChanged: {
        selectedIndex = Math.max(0, Math.min(selectedIndex, currentRows().length - 1));
    }

    onRecentProjectsChanged: {
        if (selectedTab === "recent" && recentProjects.length === 0)
            switchTab("active");
    }

    Timer {
        interval: 30000
        repeat: true
        running: !root.quietMode
        onTriggered: root.reload()
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.nowMs = Date.now()
    }

    Timer {
        id: noticeTimer

        interval: 1800
        repeat: false
        onTriggered: root.notice = ""
    }

    Process {
        id: loadProc

        command: ["bash", root.helperPath, "sessions"]
        running: true
        onRunningChanged: {
            if (running)
                stdout.buf = "";
        }
        onExited: {
            try {
                root.sessions = JSON.parse(stdout.buf || "[]");
            } catch (e) {
                root.sessions = [];
            }
            stdout.buf = "";
        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                buf += String(data);
            }
        }
    }

    Process {
        id: historyProc

        command: ["bash", root.helperPath, "history"]
        running: true
        onRunningChanged: {
            if (running)
                stdout.buf = "";
        }
        onExited: {
            try {
                root.recentProjects = JSON.parse(stdout.buf || "[]");
            } catch (e) {
                root.recentProjects = [];
            }
            stdout.buf = "";
        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                buf += String(data);
            }
        }
    }

    Item {
        id: barPill

        implicitWidth: barContent.implicitWidth
        implicitHeight: 28

        Row {
            id: barContent

            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: Style.Typography.rightClusterIcon
                height: Style.Typography.rightClusterIcon

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    text: "󰚩"
                    color: root.cTextPrimary
                    opacity: 0.5
                    font.pixelSize: Style.Typography.rightClusterIcon
                    font.family: Style.Typography.mono
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Repeater {
                model: root.topbarStatusDots()

                TopbarChip {
                    required property var modelData

                    count: modelData.count
                    chipColor: modelData.color
                }
            }
        }

        MouseArea {
            id: barHover

            anchors.fill: parent
            anchors.margins: -7
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: root.togglePanel(false)
        }
    }

    WlrLayershell {
        visible: root.showing
        color: "transparent"
        layer: WlrLayer.Top
        keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        namespace: "cctop-panel-dismiss"

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.hidePanel()
        }
    }

    WlrLayershell {
        id: cctopWindow

        visible: root.showing
        color: "transparent"
        implicitWidth: root.overlayPx(root.overlayWidth)
        implicitHeight: cctopPanel.height
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        namespace: "cctop-panel"

        anchors {
            top: !root.barOnBottom
            bottom: root.barOnBottom
            right: true
        }

        margins {
            top: !root.barOnBottom ? root.overlayBarOffset : 0
            bottom: root.barOnBottom ? root.overlayBarOffset : 0
            right: root.overlayPx(8)
        }

        Rectangle {
            id: cctopPanel

            width: root.overlayPx(root.overlayWidth)
            height: root.overlayPx(root.panelContentHeight())
            radius: root.overlayPx(12)
            color: root.cBg
            border.color: root.cPanelBorder
            border.width: 1
            clip: true

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                    root.hidePanel();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.selectedIndex = Math.min(root.currentRows().length - 1, root.selectedIndex + 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right) {
                    root.switchTab(root.selectedTab === "active" ? "recent" : "active");
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    root.switchTab("active");
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activateCurrent();
                    event.accepted = true;
                } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                    const idx = event.key - Qt.Key_1;
                    if (idx < root.currentRows().length) {
                        root.selectedIndex = idx;
                        root.activateCurrent();
                    }
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()
            onVisibleChanged: {
                if (visible)
                    forceActiveFocus();
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: root.overlayPx(14)
                spacing: 0

                HeaderRow {
                    width: parent.width
                    height: root.overlayPx(42)
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.cPanelBorder
                }

                TabRow {
                    visible: root.showTabs
                    width: parent.width
                    height: visible ? root.overlayPx(31) : 0
                }

                Rectangle {
                    visible: root.showTabs
                    width: parent.width
                    height: visible ? 1 : 0
                    color: root.cPanelBorder
                }

                ListView {
                    id: sessionList

                    width: parent.width
                    height: root.currentRows().length > 0 ? root.overlayPx(root.listContentHeight()) : 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.currentRows()

                    delegate: Loader {
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: root.overlayPx(root.rowHeight())
                        sourceComponent: root.selectedTab === "recent" ? recentRowComponent : sessionRowComponent

                        Component {
                            id: sessionRowComponent

                            SessionRow {
                                width: sessionList.width
                                session: modelData
                                rowIndex: index
                                selected: root.selectedIndex === index
                            }
                        }

                        Component {
                            id: recentRowComponent

                            RecentRow {
                                width: sessionList.width
                                project: modelData
                                rowIndex: index
                                selected: root.selectedIndex === index
                            }
                        }
                    }

                    onContentYChanged: root.nowMs = Date.now()
                }

                Item {
                    width: parent.width
                    height: root.currentRows().length === 0 ? root.overlayPx(root.emptyStateHeight()) : 0
                    visible: root.currentRows().length === 0

                    Text {
                        anchors.centerIn: parent
                        text: root.emptyStateMessage()
                        color: root.cTextMuted
                        font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.cPanelBorder
                }

                FooterRow {
                    width: parent.width
                    height: root.overlayPx(34)
                }
            }
        }
    }

    component HeaderRow: Item {
        RowLayout {
            id: titleGroup

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.overlayPx(8)

            Item {
                Layout.preferredWidth: root.overlayPx(16)
                Layout.preferredHeight: root.overlayPx(38)
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.overlayPx(3)
                    height: root.overlayPx(30)
                    radius: root.overlayPx(1.5)
                    color: root.overlayAccentColor(root.cAccent)
                }
            }

            Text {
                text: "CCTOP"
                color: root.cTextPrimary
                font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                font.family: Style.Typography.monoPropo
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
            }
        }

        RowLayout {
            id: actionGroup

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.overlayPx(2)

            HeaderActionButton {
                glyph: ""
                tooltip: "Refresh"
                onClicked: {
                    root.reload();
                    root.notice = "Refreshing sessions";
                    noticeTimer.restart();
                }
            }

            HeaderActionButton {
                glyph: "󰌌"
                tooltip: root.navigateMode ? "Exit Navigate" : "Navigate"
                active: root.navigateMode
                onClicked: root.navigateMode = !root.navigateMode
            }

            HeaderActionButton {
                glyph: "󰒓"
                tooltip: "Settings unavailable"
                onClicked: {
                    root.notice = "Settings are not implemented in the Quickshell port yet";
                    noticeTimer.restart();
                }
            }

            HeaderActionButton {
                glyph: "󰅖"
                tooltip: "Close"
                tone: root.cPermission
                onClicked: root.hidePanel()
            }
        }

    }

    component FooterRow: Item {
        RowLayout {
            anchors.fill: parent
            spacing: root.overlayPx(8)

            Text {
                text: root.notice !== "" ? root.notice : "1-9 jump · ↑↓ select · Enter open · Esc close"
                color: root.notice !== "" ? root.cAttention : root.cTextMuted
                font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                font.family: Style.Typography.monoPropo
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.selectedTab === "active" ? "Active" : "Recent"
                color: root.cTextMuted
                font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                font.family: Style.Typography.monoPropo
            }
        }
    }

    component TabRow: Item {
        Row {
            anchors.left: parent.left
            anchors.leftMargin: root.overlayPx(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.overlayPx(6)

            TabButton {
                label: "Active"
                count: root.sessions.length
                active: root.selectedTab === "active"
                onClicked: root.switchTab("active")
            }

            TabButton {
                label: "Recent"
                count: root.recentProjects.length
                active: root.selectedTab === "recent"
                onClicked: root.switchTab("recent")
            }
        }
    }

    component TabButton: Item {
        property string label: ""
        property int count: 0
        property bool active: false
        signal clicked()

        width: tabLabel.implicitWidth + root.overlayPx(12)
        height: root.overlayPx(24)

        Text {
            id: tabLabel

            anchors.centerIn: parent
            text: parent.label + " (" + parent.count + ")"
            color: parent.active ? root.cTextPrimary : root.cTextMuted
            font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
            font.family: Style.Typography.monoPropo
            font.weight: parent.active ? Font.Medium : Font.Normal
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.overlayPx(2)
            radius: root.overlayPx(1)
            color: root.cAccent
            visible: parent.active
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component HeaderActionButton: Item {
        property string glyph: ""
        property string tooltip: ""
        property color tone: root.cAccent
        property bool active: false
        signal clicked()

        Layout.preferredWidth: root.overlayPx(22)
        Layout.preferredHeight: root.overlayPx(22)
        Layout.alignment: Qt.AlignVCenter
        z: actionHover.containsMouse ? 20 : 1

        Rectangle {
            anchors.fill: parent
            radius: root.overlayPx(5)
            color: parent.active
                ? Qt.alpha(parent.tone, root.cLightTheme ? 0.18 : 0.16)
                : actionHover.containsMouse ? root.cCardHover : "transparent"
            border.color: parent.active ? Qt.alpha(parent.tone, 0.42) : "transparent"
            border.width: 1
        }

        Text {
            anchors.centerIn: parent
            text: parent.glyph
            color: parent.active || actionHover.containsMouse ? parent.tone : root.cTextMuted
            font.pixelSize: Style.Typography.scaledCalendarIcon(root.overlayScale)
            font.family: Style.Typography.mono
        }

        Rectangle {
            visible: actionHover.containsMouse && parent.tooltip !== ""
            anchors.top: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: root.overlayPx(6)
            width: tooltipText.implicitWidth + root.overlayPx(12)
            height: root.overlayPx(22)
            radius: root.overlayPx(6)
            color: Qt.darker(root.cBg, root.cLightTheme ? 1.02 : 1.18)
            border.color: root.cPanelBorder
            border.width: 1

            Text {
                id: tooltipText

                anchors.centerIn: parent
                text: parent.parent.tooltip
                color: root.cTextPrimary
                font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                font.family: Style.Typography.monoPropo
            }
        }

        MouseArea {
            id: actionHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: parent.clicked()
        }
    }

    component TopbarChip: Item {
        property int count: 0
        property color chipColor: root.cTextMuted

        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: dot.width + chipText.implicitWidth + 3
        height: 18

        Row {
            anchors.centerIn: parent
            spacing: 3

            Rectangle {
                id: dot

                anchors.verticalCenter: parent.verticalCenter
                width: 5
                height: 5
                radius: 2.5
                color: root.topbarChipColor(chipColor)
            }

            Text {
                id: chipText

                anchors.verticalCenter: parent.verticalCenter
                text: String(count)
                color: root.topbarChipColor(chipColor)
                font.pixelSize: Style.Typography.componentSubtitle
                font.family: Style.Typography.text
                font.weight: Font.Medium
            }
        }
    }

    component SessionRow: Rectangle {
        property var session: ({})
        property int rowIndex: 0
        property bool selected: false

        height: root.overlayPx(54)
        color: selected || rowHover.containsMouse ? root.cCardHover : "transparent"

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: root.overlayPx(16)
            anchors.right: parent.right
            anchors.rightMargin: root.overlayPx(16)
            height: 1
            color: root.cCardBorder
            visible: rowIndex < root.orderedSessions.length - 1
        }

        MouseArea {
            id: rowHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = rowIndex
            onClicked: root.activateSession(session)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.overlayPx(8)
            anchors.rightMargin: root.overlayPx(8)
            spacing: root.overlayPx(8)

            Item {
                Layout.preferredWidth: root.overlayPx(root.navigateMode && rowIndex < 9 ? 25 : 8)
                Layout.preferredHeight: root.overlayPx(38)

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.overlayPx(3)
                    height: root.overlayPx(36)
                    radius: root.overlayPx(1.5)
                    color: root.overlayAccentColor(root.statusColor(session))
                }

                Rectangle {
                    visible: root.navigateMode && rowIndex < 9
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.overlayPx(16)
                    height: root.overlayPx(16)
                    radius: root.overlayPx(4)
                    color: root.overlayAccentColor(root.statusColor(session))

                    Text {
                        anchors.centerIn: parent
                        text: String(rowIndex + 1)
                        color: "white"
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        font.weight: Font.Bold
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: root.overlayPx(2)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.overlayPx(6)

                    Text {
                        text: root.displayName(session)
                        color: root.effectiveStatus(session) === "idle" ? root.cTextDimmed : root.cTextPrimary
                        font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Text {
                        visible: root.subagentCount(session) > 0
                        text: root.subagentCount(session) + " agent" + (root.subagentCount(session) === 1 ? "" : "s")
                        color: root.cCompacting
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.overlayPx(5)

                    Text {
                        text: String(session.branch || "unknown")
                        color: root.cTextSecondary
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.text
                        elide: Text.ElideRight
                        Layout.maximumWidth: root.overlayPx(92)
                    }

                    Text {
                        visible: root.contextLine(session) !== ""
                        text: "/"
                        color: Qt.alpha(root.cTextMuted, 0.6)
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                    }

                    Text {
                        visible: root.contextLine(session) !== ""
                        text: root.contextLine(session)
                        color: root.cTextSecondary
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.minimumWidth: root.overlayPx(126)
                Layout.preferredWidth: root.overlayPx(126)
                Layout.maximumWidth: root.overlayPx(126)
                Layout.fillWidth: false
                spacing: root.overlayPx(1)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.overlayPx(3)

                    Text {
                        visible: root.showSessionModelColumn()
                        text: root.sessionModelLabel(session)
                        color: root.overlayAccentColor(root.sessionModelColor(session))
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Text {
                        text: root.statusLabel(session)
                        color: root.overlayAccentColor(root.statusColor(session))
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: root.overlayPx(66)
                    }
                }

                Text {
                    text: root.relativeTime(session)
                    color: root.cTextMuted
                    font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    component RecentRow: Rectangle {
        property var project: ({})
        property int rowIndex: 0
        property bool selected: false

        height: root.overlayPx(46)
        color: selected || rowHover.containsMouse ? root.cCardHover : "transparent"

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: root.overlayPx(16)
            anchors.right: parent.right
            anchors.rightMargin: root.overlayPx(16)
            height: 1
            color: root.cCardBorder
            visible: rowIndex < root.recentProjects.length - 1
        }

        MouseArea {
            id: rowHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = rowIndex
            onClicked: root.activateRecent(project)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.overlayPx(12)
            anchors.rightMargin: root.overlayPx(12)
            spacing: root.overlayPx(8)

            Rectangle {
                Layout.preferredWidth: root.overlayPx(2)
                Layout.preferredHeight: root.overlayPx(20)
                radius: root.overlayPx(1)
                color: Qt.alpha(root.cTextMuted, 0.3)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.overlayPx(2)

                Text {
                    text: String(project.project_name || "project")
                    color: root.cTextPrimary
                    font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.overlayPx(5)

                    Text {
                        text: String(project.last_branch || "unknown")
                        color: root.cTextMuted
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.text
                        elide: Text.ElideRight
                        Layout.maximumWidth: root.overlayPx(112)
                    }

                    Text {
                        text: "·"
                        color: root.cTextMuted
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                    }

                    Text {
                        text: String(project.session_count || 0) + " session" + (Number(project.session_count || 0) === 1 ? "" : "s")
                        color: root.cTextMuted
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            Text {
                text: root.recentRelativeTime(project)
                color: root.cTextMuted
                font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                font.family: Style.Typography.monoPropo
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: root.overlayPx(56)
            }
        }
    }

    function recentRelativeTime(project) {
        const parsed = Date.parse(String(project.last_session_at || ""));
        if (!Number.isFinite(parsed))
            return "recent";

        return relativeTime({
            last_activity: project.last_session_at
        });
    }

    function sessionsHaveMultipleSources() {
        const seen = {};
        for (const session of sessions)
            seen[sourceLabel(session)] = true;

        return Object.keys(seen).length > 1;
    }
}
