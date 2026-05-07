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
    property var theme: ({})
    property string namespaceName: "process-overlay"
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string notice: ""
    property string listTitle: "Processes"
    property string valueKey: "cpu"
    property color accent: theme.accent || "#89b4fa"
    property var processes: []
    property string emptyText: "no data"
    property bool showPids: false

    signal closeRequested()
    signal refreshRequested()
    signal pidCopied(var proc)
    signal killRequested(var proc)

    readonly property color cBg: theme.bg || "#1e1e2e"
    readonly property color cFg: theme.fg || "#cdd6f4"
    readonly property color cMuted: theme.muted || "#585b70"
    readonly property color cDim: theme.dim || "#45475a"
    readonly property color cRed: theme.red || "#f38ba8"
    readonly property color cYellow: theme.yellow || "#f9e2af"

    function overlayPx(value) {
        return Math.round(value * Math.max(1.0, overlayScale))
    }

    WlrLayershell {
        visible: root.showing
        color: "transparent"
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        margins {
            top: !root.barOnBottom ? root.overlayBarOffset : 0
            bottom: root.barOnBottom ? root.overlayBarOffset : 0
        }
        layer: WlrLayer.Top
        keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        namespace: root.namespaceName + "-dismiss"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.closeRequested()
        }
    }

    WlrLayershell {
        visible: root.showing
        color: "transparent"
        implicitWidth: root.overlayPx(260)
        implicitHeight: root.overlayPx(408)
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
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        namespace: root.namespaceName

        Rectangle {
            width: root.overlayPx(260)
            height: root.overlayPx(408)
            radius: 12
            color: root.cBg
            border.color: Qt.alpha(root.cDim, 0.8)
            border.width: 1
            clip: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {}
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
                        font.pixelSize: root.overlayPx(18)
                        font.family: "JetBrainsMono Nerd Font"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: root.title
                            color: root.cFg
                            font.pixelSize: root.overlayPx(12)
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.subtitle
                            color: root.cMuted
                            font.pixelSize: root.overlayPx(10)
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }

                    Text {
                        visible: root.notice !== ""
                        text: root.notice
                        color: root.accent
                        font.pixelSize: root.overlayPx(9)
                        font.family: "JetBrainsMono Nerd Font Propo"
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
                            font.pixelSize: root.overlayPx(13)
                            font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            MouseArea {
                                id: refreshHover
                                anchors.fill: parent
                                anchors.margins: -7
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.refreshRequested()
                            }
                        }

                        Text {
                            text: "󰅖"
                            color: closeHover.containsMouse ? root.cRed : root.cMuted
                            font.pixelSize: root.overlayPx(13)
                            font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            MouseArea {
                                id: closeHover
                                anchors.fill: parent
                                anchors.margins: -7
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.closeRequested()
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
                        font.pixelSize: root.overlayPx(12)
                        font.family: "JetBrainsMono Nerd Font Propo"
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
                            font.pixelSize: root.overlayPx(10)
                            font.family: "JetBrainsMono Nerd Font Propo"
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: root.overlayPx(6)
                    model: root.processes.slice(0, 10)

                    delegate: Rectangle {
                        required property var modelData

                        width: ListView.view.width
                        height: root.overlayPx(34)
                        radius: 8
                        color: rowHover.hovered ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(1, 1, 1, 0.022)
                        border.color: Qt.rgba(1, 1, 1, 0.045)
                        border.width: 1

                        HoverHandler { id: rowHover }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: false
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pidCopied(modelData)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: modelData.name || "process"
                                color: root.cFg
                                font.pixelSize: root.overlayPx(12)
                                font.family: "JetBrainsMono Nerd Font Propo"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Number(modelData[root.valueKey] || 0).toFixed(1) + "%"
                                color: Number(modelData[root.valueKey] || 0) >= 30
                                    ? root.cRed
                                    : Number(modelData[root.valueKey] || 0) >= 10
                                        ? root.cYellow
                                        : root.accent
                                font.pixelSize: root.overlayPx(12)
                                font.family: "JetBrainsMono Nerd Font Propo"
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: root.overlayPx(48)
                            }

                            Text {
                                visible: root.showPids
                                text: String(modelData.pid || "")
                                color: root.cMuted
                                font.pixelSize: root.overlayPx(10)
                                font.family: "JetBrainsMono Nerd Font Propo"
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: root.showPids ? root.overlayPx(44) : 0
                            }

                            Text {
                                text: "󰆴"
                                color: killHover.containsMouse ? root.cRed : root.cMuted
                                font.pixelSize: root.overlayPx(13)
                                font.family: "JetBrainsMono Nerd Font"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea {
                                    id: killHover
                                    anchors.fill: parent
                                    anchors.margins: -7
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.killRequested(modelData)
                                }
                            }
                        }
                    }
                }

                Item {
                    visible: root.processes.length === 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: root.emptyText
                        color: root.cMuted
                        font.pixelSize: root.overlayPx(12)
                        font.family: "JetBrainsMono Nerd Font Propo"
                        opacity: 0.65
                    }
                }
            }
        }
    }
}
