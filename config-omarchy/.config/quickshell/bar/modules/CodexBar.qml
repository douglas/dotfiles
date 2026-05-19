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
    property bool quietMode: false
    property bool showing: false
    property var state: ({})
    property var providers: []
    property int selectedIndex: 0
    property string notice: ""

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string helperPath: Quickshell.env("NEOSH_CODEXBAR_HELPER") || homeDir + "/.config/quickshell/scripts/neosh-codexbar"
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
    readonly property int providerCount: providers.length
    readonly property int errorCount: countErrors()
    readonly property int warningCount: countWarnings()
    readonly property real highestUsedPercent: Number(state.summary?.highestUsedPercent || 0)
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

    function countErrors() {
        let count = state.error ? 1 : 0;
        for (const provider of providers) {
            if (provider.error)
                count++;
        }
        return count;
    }

    function countWarnings() {
        let count = 0;
        for (const provider of providers) {
            const status = String(provider.status?.indicator || "none");
            if (status !== "none" && status !== "unknown")
                count++;
        }
        return count;
    }

    function topbarStatusDots() {
        return [
            { color: cAccent, count: providerCount },
            { color: cYellow, count: warningCount },
            { color: cRed, count: errorCount }
        ];
    }

    function providerColor(provider) {
        if (provider.error)
            return cRed;
        const status = String(provider.status?.indicator || "none");
        if (status === "major" || status === "critical")
            return cRed;
        if (status === "minor" || status === "maintenance")
            return cYellow;
        if (Number(provider.highestUsedPercent || 0) >= 80)
            return cYellow;
        return cGreen;
    }

    function providerSubtitle(provider) {
        if (provider.error)
            return String(provider.error.message || "Provider unavailable");
        const status = provider.status || {};
        const statusText = String(status.description || status.indicator || "Operational");
        return String(provider.source || "unknown") + " / " + statusText;
    }

    function accountLine(provider) {
        const identity = provider.identity || {};
        return String(identity.accountEmail || provider.account || identity.accountOrganization || "");
    }

    function formatCompactNumber(value) {
        const number = Number(value || 0);
        const abs = Math.abs(number);
        if (abs >= 1000000000)
            return (number / 1000000000).toFixed(abs >= 10000000000 ? 0 : 1).replace(".0", "") + "B";
        if (abs >= 1000000)
            return (number / 1000000).toFixed(abs >= 10000000 ? 0 : 1).replace(".0", "") + "M";
        if (abs >= 1000)
            return (number / 1000).toFixed(abs >= 10000 ? 0 : 1).replace(".0", "") + "K";
        return String(Math.round(number));
    }

    function formatCurrency(value) {
        const number = Number(value || 0);
        return "$" + number.toFixed(number >= 100 ? 0 : 2);
    }

    function hasCost(provider) {
        const cost = provider.cost || {};
        return cost.sessionTokens !== undefined
            || cost.sessionCostUSD !== undefined
            || cost.last30DaysTokens !== undefined
            || cost.last30DaysCostUSD !== undefined;
    }

    function sessionCostLine(provider) {
        if (!hasCost(provider))
            return "";
        const cost = provider.cost || {};
        return "Today " + formatCurrency(cost.sessionCostUSD) + " / " + formatCompactNumber(cost.sessionTokens);
    }

    function monthCostLine(provider) {
        if (!hasCost(provider))
            return "";
        const cost = provider.cost || {};
        return "30d " + formatCurrency(cost.last30DaysCostUSD) + " / " + formatCompactNumber(cost.last30DaysTokens);
    }

    function dailyBars(provider) {
        const rawDaily = ((provider.cost || {}).daily || []);
        const daily = rawDaily.length > 0 ? rawDaily.slice(-30) : [];
        if (daily.length === 0)
            return [];

        let maxCost = 0;
        for (const item of daily)
            maxCost = Math.max(maxCost, Number(item.totalCost || 0));

        if (maxCost <= 0)
            maxCost = 1;

        const bars = daily.map(item => ({
            date: String(item.date || ""),
            cost: Number(item.totalCost || 0),
            tokens: Number(item.totalTokens || 0),
            ratio: Math.max(0.12, Math.min(1, Number(item.totalCost || 0) / maxCost))
        }));

        while (bars.length < 30)
            bars.unshift({ date: "", cost: 0, tokens: 0, ratio: 0 });

        return bars;
    }

    function graphTooltipLine(bar) {
        if (!bar || !bar.date)
            return "";
        return String(bar.date) + " · " + formatCurrency(bar.cost) + " · " + formatCompactNumber(bar.tokens) + " tokens";
    }

    function usageLine(provider) {
        const windows = provider.windows || [];
        if (windows.length === 0) {
            if (hasCost(provider))
                return "Local logs";
            if (provider.credits && provider.credits.remaining !== undefined && provider.credits.remaining !== null)
                return "Credits " + String(provider.credits.remaining);
            return "No usage windows";
        }

        const first = windows[0];
        return String(first.label || "Usage") + " " + Math.round(Number(first.remainingPercent || 0)) + "% left";
    }

    function resetLine(window) {
        if (!window)
            return "";
        if (window.resetDescription)
            return String(window.resetDescription);
        if (window.resetsAt)
            return "Resets " + String(window.resetsAt).replace("T", " ").replace("Z", "");
        return "";
    }

    function refresh() {
        if (!loadProc.running)
            loadProc.running = true;
    }

    function openPanel() {
        showing = true;
        opened();
        refresh();
    }

    function togglePanel() {
        if (showing)
            hidePanel();
        else
            openPanel();
    }

    function hidePanel() {
        showing = false;
    }

    function rowHeight() {
        return root.overlayPx(112);
    }

    function listContentHeight() {
        return Math.min(root.overlayPx(420), providers.length * rowHeight());
    }

    function emptyStateHeight() {
        return root.overlayPx(58);
    }

    function panelContentHeight() {
        const margins = root.overlayPx(28);
        const header = root.overlayPx(42);
        const dividers = 2;
        const body = providers.length > 0 ? listContentHeight() : emptyStateHeight();
        const footer = root.overlayPx(34);
        return Math.min(root.overlayPx(560), margins + header + dividers + body + footer);
    }

    implicitWidth: barContent.implicitWidth
    implicitHeight: 28

    Timer {
        interval: root.showing ? 60000 : 300000
        repeat: true
        running: !root.quietMode
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
                root.state = JSON.parse(stdout.buf || "{}");
                root.providers = root.state.providers || [];
            } catch (e) {
                root.state = {
                    available: false,
                    error: { message: "Could not parse CodexBar helper output" }
                };
                root.providers = [];
            }
            root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, root.providers.length - 1));
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
                text: "󰘦"
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
        namespace: "codexbar-panel-dismiss"
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
        implicitWidth: root.overlayPx(520)
        implicitHeight: panel.height
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        namespace: "codexbar-panel"
        anchors.top: !root.barOnBottom
        anchors.bottom: root.barOnBottom
        anchors.right: true
        margins.top: !root.barOnBottom ? root.overlayBarOffset : 0
        margins.bottom: root.barOnBottom ? root.overlayBarOffset : 0
        margins.right: root.overlayPx(8)

        Rectangle {
            id: panel
            width: root.overlayPx(520)
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
                    root.notice = "Refreshing usage";
                    noticeTimer.restart();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.selectedIndex = Math.min(root.providers.length - 1, root.selectedIndex + 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.selectedIndex = Math.max(0, root.selectedIndex - 1);
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
                    height: root.providers.length > 0 ? root.listContentHeight() : 0
                    visible: root.providers.length > 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.providers
                    delegate: ProviderRow {
                        width: list.width
                        provider: modelData
                        rowIndex: index
                        selected: index === root.selectedIndex
                    }
                }

                Item {
                    visible: root.providers.length === 0
                    width: parent.width
                    height: visible ? root.emptyStateHeight() : 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: root.overlayPx(root.contentLeft)
                        anchors.right: parent.right
                        text: root.state.error?.message || "No CodexBar providers configured"
                        color: root.state.error ? root.cRed : root.cTextMuted
                        font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
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
                    color: root.errorCount > 0
                        ? root.overlayAccentColor(root.cRed)
                        : root.warningCount > 0 ? root.overlayAccentColor(root.cYellow) : root.overlayAccentColor(root.cAccent)
                }
            }

            Text {
                text: "CODEXBAR"
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
                glyph: ""
                tooltip: "Refresh"
                onClicked: {
                    root.refresh();
                    root.notice = "Refreshing usage";
                    noticeTimer.restart();
                }
            }

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
                text: root.notice !== "" ? root.notice : "Configured providers from ~/.codexbar/config.json · r refresh"
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

    component ProviderRow: Rectangle {
        id: providerRow

        property var provider: ({})
        property int rowIndex: 0
        property bool selected: false
        readonly property var primaryWindow: (provider.windows || [])[0]

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
            visible: rowIndex < root.providers.length - 1
        }

        MouseArea {
            id: rowHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = rowIndex
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.overlayPx(8)
            anchors.rightMargin: root.overlayPx(8)
            spacing: root.overlayPx(8)

            Item {
                Layout.preferredWidth: root.overlayPx(8)
                Layout.preferredHeight: root.overlayPx(46)

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.overlayPx(3)
                    height: root.overlayPx(44)
                    radius: root.overlayPx(1.5)
                    color: root.overlayAccentColor(root.providerColor(provider))
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
                        text: String(provider.label || provider.id || "provider")
                        color: provider.error ? root.cTextDimmed : root.cTextPrimary
                        font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Text {
                        text: String(provider.version || "")
                        visible: String(provider.version || "") !== ""
                        color: root.cTextMuted
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: Style.Typography.monoPropo
                    }
                }

                Text {
                    text: root.providerSubtitle(provider)
                    color: provider.error ? root.overlayAccentColor(root.cRed) : root.cTextSecondary
                    font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }

                Text {
                    text: root.accountLine(provider)
                    visible: root.accountLine(provider) !== ""
                    color: root.cTextMuted
                    font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }
            }

            ColumnLayout {
                Layout.minimumWidth: root.overlayPx(220)
                Layout.preferredWidth: root.overlayPx(220)
                Layout.maximumWidth: root.overlayPx(220)
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: root.overlayPx(3)

                Text {
                    text: root.usageLine(provider)
                    color: root.overlayAccentColor(root.providerColor(provider))
                    font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.sessionCostLine(provider)
                    visible: root.sessionCostLine(provider) !== ""
                    color: root.cTextPrimary
                    font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.monthCostLine(provider)
                    visible: root.monthCostLine(provider) !== ""
                    color: root.cTextMuted
                    font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                CostSparkline {
                    provider: providerRow.provider
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.overlayPx(22)
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.overlayPx(5)
                    radius: root.overlayPx(2.5)
                    color: Qt.alpha(root.cTextPrimary, root.cLightTheme ? 0.10 : 0.08)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.round(parent.width * Math.min(100, Number(provider.highestUsedPercent || 0)) / 100)
                        radius: parent.radius
                        color: root.overlayAccentColor(root.providerColor(provider))
                    }
                }

                Text {
                    text: root.resetLine(primaryWindow)
                    color: root.cTextMuted
                    font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                    font.family: Style.Typography.monoPropo
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    component CostSparkline: Item {
        property var provider: ({})
        readonly property var bars: root.dailyBars(provider)
        property var hoveredBar: null
        property real hoveredX: 0

        visible: bars.length > 0
        z: hoveredBar !== null ? 40 : 1

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.overlayPx(4)
            radius: root.overlayPx(2)
            color: Qt.alpha(root.cTextPrimary, root.cLightTheme ? 0.10 : 0.08)
        }

        Row {
            id: graphRow

            anchors.fill: parent
            spacing: root.overlayPx(2)
            layoutDirection: Qt.LeftToRight

            Repeater {
                model: bars

                Item {
                    required property var modelData

                    width: Math.max(2, Math.floor((graphRow.width - (graphRow.spacing * Math.max(0, bars.length - 1))) / Math.max(1, bars.length)))
                    height: graphRow.height
                    visible: Number(modelData.ratio || 0) > 0

                    Rectangle {
                        id: graphBar

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: Math.min(parent.width, root.overlayPx(4))
                        height: Math.max(root.overlayPx(3), Math.round(parent.height * Number(modelData.ratio || 0)))
                        radius: root.overlayPx(2)
                        color: barHover.containsMouse
                            ? root.overlayAccentColor(root.providerColor(provider))
                            : Qt.alpha(root.overlayAccentColor(root.providerColor(provider)), 0.72)
                    }

                    MouseArea {
                        id: barHover

                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            hoveredBar = modelData;
                            hoveredX = parent.x + (parent.width / 2);
                        }
                        onPositionChanged: (mouse) => {
                            hoveredX = parent.x + mouse.x;
                        }
                        onExited: hoveredBar = null
                    }
                }
            }
        }

        Rectangle {
            id: graphTooltip

            visible: hoveredBar !== null
            z: 50
            x: Math.max(0, Math.min(parent.width - width, hoveredX - (width / 2)))
            y: -height - root.overlayPx(6)
            width: tooltipText.implicitWidth + root.overlayPx(12)
            height: root.overlayPx(22)
            radius: root.overlayPx(6)
            color: Qt.darker(root.cBg, root.cLightTheme ? 1.02 : 1.18)
            border.color: root.cPanelBorder
            border.width: 1

            Text {
                id: tooltipText

                anchors.centerIn: parent
                text: root.graphTooltipLine(hoveredBar)
                color: root.cTextPrimary
                font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                font.family: Style.Typography.monoPropo
            }
        }
    }
}
