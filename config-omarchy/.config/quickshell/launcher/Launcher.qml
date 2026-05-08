import "."
import "../style" as Style
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: launcher

    property bool showing: false
    property var theme: ({
    })
    property var powerActions: null
    property string mode: "menu"
    property real uiScale: 0
    property real uiScaleMultiplier: 0.5
    readonly property real detectedScale: screen && screen.devicePixelRatio > 0 ? screen.devicePixelRatio : 1
    property real launcherScale: Math.max(1, Math.min(2.5, uiScale > 0 ? uiScale : detectedScale * uiScaleMultiplier))
    readonly property int menuCardWidth: menuView.preferredWidth
    readonly property int menuCardHeight: Math.max(210, Math.min(520, menuView.preferredHeight + 20))
    property string appSearchText: ""

    function toggle() {
        showing = !showing;
    }

    function findRootItem(label) {
        const tree = MenuData.buildTree();
        for (let i = 0; i < tree.length; i++) {
            if (tree[i].label === label)
                return tree[i];

        }
        return null;
    }

    function findChildItem(items, label) {
        if (!items)
            return null;

        for (let i = 0; i < items.length; i++) {
            if (items[i].label === label)
                return items[i];

        }
        return null;
    }

    // Functions for keybindings
    function openScreenrecord() {
        showing = true;
        mode = "menu";
        Qt.callLater(function() {
            menuView.reset();
            const triggerItem = findRootItem("Trigger");
            const captureItem = findChildItem(triggerItem ? triggerItem.children : null, "Capture");
            const screenrecordItem = findChildItem(captureItem ? captureItem.children : null, "Screenrecord");
            if (triggerItem && triggerItem.children)
                menuView.pushPage(triggerItem.label, triggerItem.children);

            if (captureItem && captureItem.children)
                menuView.pushPage(captureItem.label, captureItem.children);

            if (screenrecordItem && screenrecordItem.children)
                menuView.pushPage(screenrecordItem.label, screenrecordItem.children);

        });
    }

    function openSystem() {
        showing = true;
        mode = "menu";
        Qt.callLater(function() {
            menuView.reset();
            const systemItem = findRootItem("System");
            if (systemItem && systemItem.children)
                menuView.pushPage(systemItem.label, systemItem.children);

        });
    }

    function openToggle() {
        showing = true;
        mode = "menu";
        Qt.callLater(function() {
            menuView.reset();
            const triggerItem = findRootItem("Trigger");
            const toggleItem = findChildItem(triggerItem ? triggerItem.children : null, "Toggle");
            if (triggerItem && triggerItem.children)
                menuView.pushPage(triggerItem.label, triggerItem.children);

            if (toggleItem && toggleItem.children)
                menuView.pushPage(toggleItem.label, toggleItem.children);

        });
    }

    color: "transparent"
    exclusiveZone: 0
    visible: showing
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    onShowingChanged: {
        if (showing) {
            if (mode === "apps") {
                appList.reload();
                appSearchText = "";
                appList.filter("");
                appList.selectedIdx = 0;
            } else {
                mode = "menu";
                menuView.reset();
            }
            focusTimer.start();
        }
    }

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: true
        Keys.onPressed: (e) => {
            if (mode === "menu") {
                menuView.handleKey(e);
            } else {
                if (e.key === Qt.Key_Escape) {
                    mode = "menu";
                    e.accepted = true;
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    appList.launchSelected();
                    e.accepted = true;
                } else if (e.key === Qt.Key_Down) {
                    appList.moveDown();
                    e.accepted = true;
                } else if (e.key === Qt.Key_Up) {
                    appList.moveUp();
                    e.accepted = true;
                } else if (e.key === Qt.Key_Backspace) {
                    if (appSearchText.length > 0) {
                        appSearchText = appSearchText.slice(0, -1);
                        appList.filter(appSearchText);
                    } else {
                        mode = "menu";
                    }
                    e.accepted = true;
                } else if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 32) {
                    appSearchText += e.text;
                    appList.filter(appSearchText);
                    e.accepted = true;
                }
            }
        }

        // fullscreen background — click outside closes
        MouseArea {
            anchors.fill: parent
            onClicked: launcher.showing = false
        }

        // card — centered on screen
        Rectangle {
            id: card

            width: launcher.mode === "apps" ? 560 : launcher.menuCardWidth
            height: launcher.mode === "apps" ? 520 : launcher.menuCardHeight
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            transformOrigin: Item.Center
            scale: launcher.launcherScale
            radius: 12
            color: theme.bg || "#1e1e2e"
            border.color: theme.dim || "#45475a"
            border.width: 1
            clip: true
            opacity: launcher.showing ? 1 : 0

            // block clicks from reaching background MouseArea
            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            // ── menu mode ─────────────────────────────────────────
            MenuView {
                id: menuView

                anchors.fill: parent
                anchors.margins: 10
                theme: launcher.theme
                powerActions: launcher.powerActions
                active: launcher.showing && launcher.mode === "menu"
                visible: launcher.mode === "menu"
                onCloseRequested: launcher.showing = false
                onAppsRequested: {
                    appList.reload();
                    appSearchText = "";
                    appList.filter("");
                    appList.selectedIdx = 0;
                    launcher.mode = "apps";
                }
                onThemesRequested: {
                    launcher.showing = false;
                }
            }

            // ── apps mode ─────────────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                anchors.topMargin: 14
                spacing: 8
                visible: launcher.mode === "apps"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: ""
                        color: Qt.alpha(theme.accent || "#89b4fa", 0.7)
                        font.pixelSize: Style.Typography.componentMeta
                        font.family: Style.Typography.mono

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: launcher.mode = "menu"
                        }

                    }

                    Text {
                        text: "Go › Apps"
                        color: theme.fg || "#cdd6f4"
                        font.pixelSize: Style.Typography.titleSmall
                        font.family: Style.Typography.mono
                        font.weight: Font.DemiBold
                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 8
                    color: Qt.alpha(theme.dim || "#45475a", 0.4)
                    border.color: theme.accent || "#89b4fa"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "󰍉"
                            color: theme.accent || "#89b4fa"
                            font.pixelSize: Style.Typography.searchIcon
                            font.family: Style.Typography.mono
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            Text {
                                id: appSearchLabel

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                text: appSearchText
                                color: theme.fg || "#cdd6f4"
                                font.pixelSize: Style.Typography.bodyLarge
                                font.family: Style.Typography.mono
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                anchors.left: appSearchLabel.left
                                anchors.leftMargin: Math.min(appSearchLabel.contentWidth, appSearchLabel.width)
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1.5
                                height: 17
                                radius: 1
                                color: theme.accent || "#89b4fa"

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: launcher.showing && launcher.mode === "apps"

                                    NumberAnimation {
                                        to: 0
                                        duration: 530
                                        easing.type: Easing.InOutSine
                                    }

                                    NumberAnimation {
                                        to: 1
                                        duration: 530
                                        easing.type: Easing.InOutSine
                                    }

                                }

                            }

                        }

                        Text {
                            visible: appSearchText !== ""
                            text: "✕"
                            color: Qt.alpha(theme.muted || "#585b70", 0.5)
                            font.pixelSize: Style.Typography.closeIcon

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    appSearchText = "";
                                    appList.filter("");
                                }
                            }

                        }

                    }

                }

                Row {
                    Layout.fillWidth: true

                    Text {
                        text: appList.filteredApps.length + " apps"
                        color: Qt.alpha(theme.muted || "#585b70", 0.62)
                        font.pixelSize: Style.Typography.componentSubtitle
                        font.family: Style.Typography.mono
                    }

                    Item {
                        width: 1
                        height: 1
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "↑↓  ↵ open  ⌫/esc back"
                        color: Qt.alpha(theme.muted || "#585b70", 0.42)
                        font.pixelSize: Style.Typography.componentSubtitle
                        font.family: Style.Typography.mono
                    }

                }

                AppList {
                    id: appList

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    theme: launcher.theme
                    onLaunched: launcher.showing = false
                }

            }

            transform: Translate {
                y: launcher.showing ? 0 : 20

                Behavior on y {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on width {
                NumberAnimation {
                    duration: 170
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on height {
                NumberAnimation {
                    duration: 170
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    Timer {
        id: focusTimer

        interval: 50
        onTriggered: focusScope.forceActiveFocus()
    }

}
