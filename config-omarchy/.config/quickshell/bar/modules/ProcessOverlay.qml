import "../../style" as Style
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    property bool showing: false
    property bool barOnBottom: false
    property int overlayBarOffset: 44
    property real overlayScale: 1.18
    property int overlayWidth: 236
    property int overlayHeight: 408
    property var theme: ({
    })
    property string namespaceName: "process-overlay"
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string notice: ""
    property string listTitle: "Processes"
    property string valueKey: "cpu"
    property color accent: theme.accent || "#89b4fa"
    property var processes: []
    property var treeGroups: []
    property var collapsedKeys: []
    property var displayRows: []
    property string emptyText: "no data"
    property bool loading: false
    property bool showPids: false
    property bool settingsOpen: false
    property int maxProcessRows: 3
    property int processLimit: maxProcessRows
    readonly property int effectiveProcessRows: Math.max(1, Math.min(10, Math.round(processLimit)))
    readonly property string textFont: Style.Typography.monoPropo
    readonly property string iconFont: Style.Typography.mono
    readonly property color cBg: theme.bg || "#1e1e2e"
    readonly property color cFg: theme.fg || "#cdd6f4"
    readonly property color cMuted: theme.muted || "#585b70"
    readonly property color cDim: theme.dim || "#45475a"
    readonly property color cRed: theme.red || "#f38ba8"
    readonly property color cYellow: theme.yellow || "#f9e2af"

    signal closeRequested()
    signal refreshRequested()
    signal pidCopied(var proc)
    signal killRequested(var proc)
    signal branchCopied(var branch)
    signal processLimitRequested(int limit)

    function overlayPx(value) {
        return Math.round(value * Math.max(1, overlayScale));
    }

    function keyCollapsed(key) {
        return collapsedKeys.indexOf(String(key || "")) >= 0;
    }

    function toggleKey(key) {
        const normalized = String(key || "");
        if (normalized === "")
            return ;

        const next = collapsedKeys.slice();
        const index = next.indexOf(normalized);
        if (index >= 0)
            next.splice(index, 1);
        else
            next.push(normalized);
        collapsedKeys = next;
        rebuildRows();
    }

    function processRow(proc, level) {
        return {
            "rowType": "process",
            "level": level,
            "pid": proc.pid || "",
            "name": proc.name || "process",
            "cpu": Number(proc.cpu || 0),
            "mem": Number(proc.mem || 0)
        };
    }

    function branchRow(branch, level, fallbackType) {
        return {
            "rowType": branch.rowType || fallbackType,
            "key": branch.key || branch.title || fallbackType,
            "level": level,
            "title": branch.title || fallbackType,
            "fullTitle": branch.fullTitle || branch.title || fallbackType,
            "subtitle": branch.subtitle || "",
            "cpu": Number(branch.cpu || 0),
            "mem": Number(branch.mem || 0)
        };
    }

    function rebuildRows() {
        const rows = [];
        let processRowsShown = 0;

        function pushProcess(proc, level) {
            if (processRowsShown >= root.effectiveProcessRows)
                return false;

            rows.push(processRow(proc, level));
            processRowsShown++;
            return true;
        }
        if (treeGroups.length > 0) {
            for (const group of treeGroups) {
                const groupKey = group.key || group.title;
                rows.push(branchRow(group, 0, "group"));
                if (keyCollapsed(groupKey))
                    continue;

                const children = group.children || [];
                for (const child of children) {
                    const childKey = child.key || child.title;
                    rows.push(branchRow(child, 1, "container"));
                    if (keyCollapsed(childKey))
                        continue;

                    const childRows = child.rows || [];
                    for (const proc of childRows) {
                        if (!pushProcess(proc, 2))
                            break;
                    }
                }
                const processRows = group.rows || [];
                for (const proc of processRows) {
                    if (!pushProcess(proc, 1))
                        break;
                }
            }
        } else {
            for (const proc of processes.slice(0, root.effectiveProcessRows)) rows.push(processRow(proc, 0))
        }
        displayRows = rows;
    }

    function setProcessLimit(value) {
        const next = Math.max(1, Math.min(10, Math.round(value)));
        if (root.processLimit === next)
            return ;

        root.maxProcessRows = next;
        root.processLimitRequested(next);
        root.rebuildRows();
    }

    function copyableBranch(row) {
        return row.rowType === "container" && String(row.fullTitle || row.title || "") !== "";
    }

    function rowExpanded(row) {
        return !keyCollapsed(row.key);
    }

    onProcessesChanged: rebuildRows()
    onTreeGroupsChanged: rebuildRows()
    onCollapsedKeysChanged: rebuildRows()
    onEffectiveProcessRowsChanged: rebuildRows()
    onShowingChanged: {
        if (!showing)
            settingsOpen = false;
    }

    WlrLayershell {
        visible: root.showing
        color: "transparent"
        layer: WlrLayer.Top
        keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        namespace: root.namespaceName + "-dismiss"

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        margins {
            top: 0
            bottom: 0
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.closeRequested()
        }

    }

    WlrLayershell {
        visible: root.showing
        color: "transparent"
        implicitWidth: root.overlayPx(root.overlayWidth)
        implicitHeight: root.overlayPx(root.overlayHeight)
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        namespace: root.namespaceName

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
            width: root.overlayPx(root.overlayWidth)
            height: root.overlayPx(root.overlayHeight)
            radius: 12
            color: root.cBg
            border.color: Qt.alpha(root.cDim, 0.8)
            border.width: 1
            clip: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.overlayPx(14)
                spacing: root.overlayPx(10)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: parent.width
                    spacing: 10

                    Text {
                        text: root.icon
                        color: root.accent
                        font.pixelSize: Style.Typography.scaledCalendarHeaderIcon(root.overlayScale)
                        font.family: root.iconFont
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: root.title
                            color: root.cFg
                            font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                            font.family: root.textFont
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.subtitle
                            color: root.cMuted
                            font.pixelSize: Style.Typography.scaledComponentSubtitle(root.overlayScale)
                            font.family: root.textFont
                        }

                    }

                    Text {
                        visible: root.notice !== ""
                        text: root.notice
                        color: root.accent
                        font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                        font.family: root.textFont
                        elide: Text.ElideRight
                        Layout.maximumWidth: root.overlayPx(120)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Row {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        spacing: root.overlayPx(12)

                        Text {
                            text: ""
                            color: refreshHover.containsMouse ? root.accent : root.cMuted
                            font.pixelSize: Style.Typography.scaledCalendarIcon(root.overlayScale)
                            font.family: root.iconFont

                            MouseArea {
                                id: refreshHover

                                anchors.fill: parent
                                anchors.margins: -7
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.refreshRequested()
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }

                            }

                        }

                        Text {
                            text: ""
                            color: settingsHover.containsMouse || root.settingsOpen ? root.accent : root.cMuted
                            font.pixelSize: Style.Typography.scaledCalendarIcon(root.overlayScale)
                            font.family: root.iconFont

                            MouseArea {
                                id: settingsHover

                                anchors.fill: parent
                                anchors.margins: -7
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.settingsOpen = !root.settingsOpen
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }

                            }

                        }

                        Text {
                            text: "󰅖"
                            color: closeHover.containsMouse ? root.cRed : root.cMuted
                            font.pixelSize: Style.Typography.scaledCalendarIcon(root.overlayScale)
                            font.family: root.iconFont

                            MouseArea {
                                id: closeHover

                                anchors.fill: parent
                                anchors.margins: -7
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.closeRequested()
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }

                            }

                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(root.cDim, 0.55)
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.listTitle
                        color: root.cFg
                        font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                        font.family: root.textFont
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                    Row {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        spacing: root.overlayPx(6)

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.overlayPx(12)
                            height: root.overlayPx(12)
                            radius: 4
                            color: root.showPids ? root.accent : "transparent"
                            border.color: root.showPids ? root.accent : Qt.alpha(root.cFg, 0.22)
                            border.width: 1

                            Rectangle {
                                visible: root.showPids
                                anchors.centerIn: parent
                                width: root.overlayPx(7)
                                height: 2
                                radius: 1
                                color: root.cBg
                                rotation: -45
                                x: root.overlayPx(-1)
                                y: root.overlayPx(1)
                            }

                            Rectangle {
                                visible: root.showPids
                                anchors.centerIn: parent
                                width: root.overlayPx(4)
                                height: 2
                                radius: 1
                                color: root.cBg
                                rotation: 45
                                x: root.overlayPx(-3)
                                y: root.overlayPx(2)
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showPids = !root.showPids
                            }

                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "PID"
                            color: root.cMuted
                            font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                            font.family: root.textFont
                        }

                    }

                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.loading && root.displayRows.length > 0
                    clip: true
                    spacing: root.overlayPx(6)
                    model: root.displayRows

                    delegate: Rectangle {
                        required property var modelData

                        width: ListView.view.width
                        height: root.overlayPx(modelData.rowType === "process" ? 34 : 28)
                        radius: 8
                        color: modelData.rowType === "process" ? (rowHover.hovered ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(1, 1, 1, 0.022)) : (rowHover.hovered ? Qt.alpha(root.accent, 0.12) : Qt.alpha(root.accent, modelData.level === 0 ? 0.08 : 0.05))
                        border.color: modelData.rowType === "process" ? Qt.rgba(1, 1, 1, 0.045) : Qt.alpha(root.accent, 0.16)
                        border.width: 1

                        HoverHandler {
                            id: rowHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: false
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.rowType === "process")
                                    root.pidCopied(modelData);
                                else
                                    root.toggleKey(modelData.key);
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10 + root.overlayPx((modelData.level || 0) * 14)
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                visible: modelData.rowType !== "process"
                                text: root.rowExpanded(modelData) ? "⌄" : "›"
                                color: root.accent
                                font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                                font.family: root.textFont
                                horizontalAlignment: Text.AlignHCenter
                                Layout.preferredWidth: root.overlayPx(10)
                            }

                            Text {
                                text: modelData.rowType === "process" ? (modelData.name || "process") : (modelData.title || "group")
                                color: modelData.rowType === "process" ? root.cFg : root.accent
                                font.pixelSize: modelData.rowType === "process" ? Style.Typography.scaledComponentBody(root.overlayScale) : Style.Typography.scaledComponentSubtitle(root.overlayScale)
                                font.family: root.textFont
                                font.weight: modelData.rowType === "process" ? Font.Normal : Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: modelData.rowType === "process" || !root.copyableBranch(modelData)
                                Layout.preferredWidth: root.copyableBranch(modelData) ? root.overlayPx(96) : -1

                                MouseArea {
                                    visible: root.copyableBranch(modelData)
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.branchCopied(modelData)
                                }

                            }

                            Text {
                                visible: root.copyableBranch(modelData) && String(modelData.fullTitle || "") !== String(modelData.title || "")
                                text: modelData.fullTitle || ""
                                color: root.cMuted
                                font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                                font.family: root.textFont
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: modelData.rowType !== "process" && String(modelData.subtitle || "") !== ""
                                text: modelData.subtitle || ""
                                color: root.cMuted
                                font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                                font.family: root.textFont
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignRight
                                Layout.maximumWidth: root.overlayPx(72)
                            }

                            Text {
                                text: Number(modelData[root.valueKey] || 0).toFixed(1) + "%"
                                color: Number(modelData[root.valueKey] || 0) >= 30 ? root.cRed : Number(modelData[root.valueKey] || 0) >= 10 ? root.cYellow : root.accent
                                font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                                font.family: root.textFont
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: root.overlayPx(48)
                            }

                            Text {
                                visible: root.showPids && modelData.rowType === "process"
                                text: String(modelData.pid || "")
                                color: root.cMuted
                                font.pixelSize: Style.Typography.scaledComponentMeta(root.overlayScale)
                                font.family: root.textFont
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: root.showPids ? root.overlayPx(44) : 0
                            }

                            Text {
                                visible: modelData.rowType === "process"
                                text: "󰆴"
                                color: killHover.containsMouse ? root.cRed : root.cMuted
                                font.pixelSize: Style.Typography.scaledCalendarIcon(root.overlayScale)
                                font.family: root.iconFont

                                MouseArea {
                                    id: killHover

                                    anchors.fill: parent
                                    anchors.margins: -7
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.killRequested(modelData)
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }

                                }

                            }

                        }

                    }

                }

                Item {
                    visible: root.loading || root.displayRows.length === 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Column {
                        visible: root.loading
                        anchors.centerIn: parent
                        spacing: root.overlayPx(6)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰔟"
                            color: root.accent
                            font.pixelSize: Style.Typography.scaledCalendarIcon(root.overlayScale)
                            font.family: root.iconFont

                            RotationAnimation on rotation {
                                running: root.loading
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 900
                            }

                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Loading processes..."
                            color: root.cMuted
                            font.pixelSize: Style.Typography.scaledComponentSubtitle(root.overlayScale)
                            font.family: root.textFont
                        }

                    }

                    Text {
                        visible: !root.loading && root.displayRows.length === 0
                        anchors.centerIn: parent
                        text: root.emptyText
                        color: root.cMuted
                        font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                        font.family: root.textFont
                        opacity: 0.65
                    }

                }

            }

            Rectangle {
                id: settingsPanel

                visible: root.settingsOpen
                z: 20
                width: root.overlayPx(178)
                height: root.overlayPx(86)
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: root.overlayPx(48)
                anchors.rightMargin: root.overlayPx(14)
                radius: 8
                color: root.cBg
                border.width: 1
                border.color: Qt.alpha(root.accent, 0.42)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.overlayPx(12)
                    spacing: root.overlayPx(10)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.overlayPx(8)

                        Text {
                            Layout.fillWidth: true
                            text: "Top processes"
                            color: root.cFg
                            font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                            font.family: root.textFont
                            font.weight: Font.Medium
                        }

                        Text {
                            text: root.effectiveProcessRows
                            color: root.accent
                            font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                            font.family: root.textFont
                            font.weight: Font.DemiBold
                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.overlayPx(8)

                        Repeater {
                            model: [{
                                "label": "-1",
                                "delta": -1
                            }, {
                                "label": "+1",
                                "delta": 1
                            }, {
                                "label": "+5",
                                "delta": 5
                            }]

                            Rectangle {
                                Layout.fillWidth: true
                                height: root.overlayPx(30)
                                radius: 6
                                color: Qt.alpha(root.cDim, 0.34)
                                border.width: 1
                                border.color: Qt.alpha(root.cDim, 0.7)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: root.cFg
                                    font.pixelSize: Style.Typography.scaledComponentBody(root.overlayScale)
                                    font.family: root.textFont
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setProcessLimit(root.effectiveProcessRows + modelData.delta)
                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
