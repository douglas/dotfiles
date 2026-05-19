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
    property real overlayScale: 1.12
    property bool showing: false
    property var uiState: ({})
    property var runs: []
    property var history: []
    property int selectedIndex: 0
    property string selectedTab: "active"
    property string notice: ""

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string helperPath: Quickshell.env("NEOSH_AUTORESEARCH_HELPER") || homeDir + "/.config/quickshell/scripts/neosh-autoresearch"
    readonly property color cBg: theme.bg || "#1A1B26"
    readonly property color cFg: theme.fg || "#C0CAF5"
    readonly property color cMuted: theme.muted || "#787C99"
    readonly property color cAccent: theme.accent || "#89B4FA"
    readonly property color cGreen: theme.green || "#9ECE6A"
    readonly property color cYellow: theme.yellow || "#E0AF68"
    readonly property color cRed: theme.red || "#F7768E"
    readonly property bool cLightTheme: colorLuma(cBg) > 0.62
    readonly property color cPanelBorder: Qt.alpha(cTextPrimary, cLightTheme ? 0.16 : 0.10)
    readonly property color cCardBorder: Qt.alpha(cTextPrimary, cLightTheme ? 0.10 : 0.06)
    readonly property color cCardHover: cLightTheme ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.04)
    readonly property color cTextPrimary: cFg
    readonly property color cTextSecondary: cMuted
    readonly property color cTextMuted: cLightTheme ? Qt.alpha(cTextPrimary, 0.62) : Qt.alpha(cTextPrimary, 0.50)
    readonly property color cTextDimmed: cLightTheme ? Qt.alpha(cTextPrimary, 0.42) : Qt.alpha(cTextPrimary, 0.35)
    readonly property int trainingCount: countStatus("training")
    readonly property int blockedCount: countStatus("blocked") + countStatus("crashed")
    readonly property int activeCount: runs.length
    readonly property bool autoresearchActive: activeCount > 0 || uiState.active === true
    readonly property int contentLeft: 24

    signal opened()

    function colorLuma(color) {
        return (0.2126 * color.r) + (0.7152 * color.g) + (0.0722 * color.b);
    }

    function statusDisplayColor(color) {
        return cLightTheme ? Qt.darker(color, 1.45) : color;
    }

    function topbarChipColor(color) {
        return Qt.alpha(statusDisplayColor(color), cLightTheme ? 0.72 : 0.82);
    }

    function overlayAccentColor(color) {
        return Qt.alpha(statusDisplayColor(color), cLightTheme ? 0.72 : 0.78);
    }

    function overlayPx(value) {
        return Math.round(value * Math.max(1, overlayScale));
    }

    function countStatus(status) {
        let count = 0;
        for (const run of runs) {
            if (String(run.status || "") === status)
                count++;
        }
        return count;
    }

    function rowModel() {
        return selectedTab === "history" ? history : runs;
    }

    function statusColor(run) {
        const status = String(run.status || "idle");
        if (status === "training" || status === "evaluating" || status === "committing")
            return cYellow;
        if (status === "blocked" || status === "crashed")
            return cRed;
        if (status === "kept" || status === "keep")
            return cGreen;
        return cAccent;
    }

    function displayName(run) {
        if (run.tag || run.run_id || run.id)
            return String(run.tag || run.run_id || run.id);
        if (run.run !== undefined && run.run !== null)
            return "run " + String(run.run);
        return "autoresearch";
    }

    function primaryMetricName() {
        const metric = uiState.metric || {};
        return String(metric.name || "metric");
    }

    function topbarStatusDots() {
        return [
            { color: cAccent, count: activeCount },
            { color: cYellow, count: trainingCount },
            { color: cRed, count: blockedCount }
        ];
    }

    function metricText(run) {
        if (run.metric !== undefined && run.metric !== null)
            return String(run.metric_name || primaryMetricName()) + " " + String(run.metric);
        const best = run.best || {};
        if (best.metric === undefined || best.metric === null)
            return "no metric";
        return String(best.metric_name || "metric") + " " + String(best.metric);
    }

    function contextLine(run) {
        const current = run.current || {};
        const desc = String(run.description || current.description || current.command || current.event || "");
        return desc.length > 0 ? desc : String(run.phase || run.status || "");
    }

    function refresh() {
        if (!loadProc.running)
            loadProc.running = true;
    }

    function togglePanel() {
        if (showing)
            hidePanel();
        else
            openPanel();
    }

    function openPanel() {
        showing = true;
        selectedTab = "active";
        opened();
        refresh();
    }

    function hidePanel() {
        showing = false;
    }

    function rowHeight() {
        return root.overlayPx(58);
    }

    function listContentHeight() {
        return Math.min(root.overlayPx(232), root.rowModel().length * rowHeight());
    }

    function emptyStateHeight() {
        return root.overlayPx(34);
    }

    function panelContentHeight() {
        const margins = root.overlayPx(28);
        const header = root.overlayPx(42);
        const dividers = 2;
        const body = root.rowModel().length > 0 ? listContentHeight() : emptyStateHeight();
        const footer = root.overlayPx(34);
        return Math.min(root.overlayPx(360), margins + header + dividers + body + footer);
    }

    function activate(run) {
        if (!run)
            return;
        Quickshell.execDetached(["bash", helperPath, "action", "focus", String(run.run_id || run.id || "")]);
        notice = "Opening " + displayName(run);
        noticeTimer.restart();
        hidePanel();
    }

    implicitWidth: barContent.implicitWidth
    implicitHeight: 28

    Timer {
        interval: root.showing || root.trainingCount > 0 ? 2000 : 30000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: noticeTimer
        interval: 1800
        onTriggered: root.notice = ""
    }

    Process {
        id: loadProc
        command: ["bash", root.helperPath, "state"]
        running: true
        onRunningChanged: if (running) stdout.buf = ""
        onExited: {
            try {
                root.uiState = JSON.parse(stdout.buf || "{}");
                root.runs = root.uiState.runs || [];
                root.history = root.uiState.history || [];
            } catch (e) {
                root.uiState = {};
                root.runs = [];
                root.history = [];
            }
            stdout.buf = "";
        }
        stdout: SplitParser {
            property string buf: ""
            onRead: (data) => { buf += String(data); }
        }
    }

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
                text: "󰂓"
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
        anchors.fill: parent
        anchors.margins: -7
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
    }

    WlrLayershell {
        visible: root.showing
        color: "transparent"
        layer: WlrLayer.Top
        keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        namespace: "autoresearch-panel-dismiss"
        anchors.left: true
        anchors.right: true
        anchors.top: true
        anchors.bottom: true
        MouseArea {
            anchors.fill: parent
            onClicked: root.hidePanel()
        }
    }

    WlrLayershell {
        id: panelWindow
        visible: root.showing
        color: "transparent"
        implicitWidth: root.overlayPx(380)
        implicitHeight: panel.height
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        namespace: "autoresearch-panel"
        anchors.top: !root.barOnBottom
        anchors.bottom: root.barOnBottom
        anchors.right: true
        margins.top: !root.barOnBottom ? root.overlayBarOffset : 0
        margins.bottom: root.barOnBottom ? root.overlayBarOffset : 0
        margins.right: root.overlayPx(8)

        Rectangle {
            id: panel
            width: root.overlayPx(380)
            height: root.panelContentHeight()
            radius: root.overlayPx(12)
            color: root.cBg
            border.color: root.cPanelBorder
            border.width: 1
            clip: true

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                    root.hidePanel();
                    event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    root.refresh();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.selectedIndex = Math.min(root.rowModel().length - 1, root.selectedIndex + 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate(root.rowModel()[root.selectedIndex]);
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()
            onVisibleChanged: if (visible) forceActiveFocus()

            Column {
                anchors.fill: parent
                anchors.margins: root.overlayPx(14)
                spacing: 0

                HeaderRow {
                    width: parent.width
                    height: root.overlayPx(42)
                }

                Rectangle {
                    x: root.overlayPx(root.contentLeft)
                    width: parent.width - x
                    height: 1
                    color: root.cPanelBorder
                }

                ListView {
                    id: list
                    width: parent.width
                    height: root.rowModel().length > 0 ? root.listContentHeight() : 0
                    visible: root.rowModel().length > 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.rowModel()
                    delegate: RunRow {
                        width: list.width
                        run: modelData
                        rowIndex: index
                        selected: index === root.selectedIndex
                    }
                }

                Item {
                    visible: root.rowModel().length === 0
                    width: parent.width
                    height: visible ? root.emptyStateHeight() : 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: root.overlayPx(root.contentLeft)
                        anchors.right: parent.right
                        text: root.selectedTab === "active" ? "No active autoresearch runs" : "No autoresearch history"
                        color: root.cTextMuted
                        font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        horizontalAlignment: Text.AlignLeft
                    }
                }

                Rectangle {
                    x: root.overlayPx(root.contentLeft)
                    width: parent.width - x
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
                    color: root.autoresearchActive ? root.overlayAccentColor(root.cGreen) : root.cTextMuted
                }
            }

            Text {
                text: String(root.uiState.name || "AUTORESEARCH").toUpperCase()
                color: root.cTextPrimary
                font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                font.family: Style.Typography.monoPropo
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.overlayPx(2)

            HeaderActionButton {
                glyph: "󰅖"
                tooltip: "Close"
                tone: root.cRed
                onClicked: root.hidePanel()
            }
        }
    }

    component FooterRow: Item {
        RowLayout {
            anchors.fill: parent
            spacing: root.overlayPx(8)

            Text {
                text: root.notice !== "" ? root.notice : "↑↓/j/k move · Enter select · r refresh"
                color: root.notice !== "" ? root.cRed : root.cTextMuted
                font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                font.family: Style.Typography.monoPropo
                elide: Text.ElideRight
                Layout.leftMargin: root.overlayPx(root.contentLeft)
                Layout.fillWidth: true
            }
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

    component RunRow: Rectangle {
        property var run: ({})
        property int rowIndex: 0
        property bool selected: false
        height: root.rowHeight()
        color: selected || rowHover.containsMouse ? root.cCardHover : "transparent"

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: root.overlayPx(16)
            anchors.right: parent.right
            anchors.rightMargin: root.overlayPx(16)
            height: 1
            color: root.cCardBorder
            visible: rowIndex < root.rowModel().length - 1
        }

        MouseArea {
            id: rowHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = rowIndex
            onClicked: root.activate(run)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.overlayPx(8)
            anchors.rightMargin: root.overlayPx(8)
            spacing: root.overlayPx(8)

            Item {
                Layout.preferredWidth: root.overlayPx(8)
                Layout.preferredHeight: root.overlayPx(38)

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.overlayPx(3)
                    height: root.overlayPx(36)
                    radius: root.overlayPx(1.5)
                    color: root.overlayAccentColor(root.statusColor(run))
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: root.overlayPx(3)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.overlayPx(6)

                    Text {
                        text: root.displayName(run)
                        color: root.cTextPrimary
                        font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Text {
                        text: String(run.status || "idle")
                        color: root.overlayAccentColor(root.statusColor(run))
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                    }
                }

                Text {
                    text: root.contextLine(run)
                    color: root.cTextSecondary
                    font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }

                Text {
                    text: root.metricText(run)
                    color: root.cTextSecondary
                    font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }
            }
        }
    }
}
