import "../../style" as Style
import QtQuick

Item {
    id: root

    property string label: ""
    property real value: 0
    property color accent: "#89b4fa"
    property color trackColor: "#45475a"
    property color textColor: "#cdd6f4"
    property bool interactive: false

    signal clicked()

    implicitWidth: row.implicitWidth
    implicitHeight: 28
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    MouseArea {
        id: ma

        anchors.fill: parent
        anchors.margins: -6
        acceptedButtons: root.interactive ? Qt.LeftButton : Qt.NoButton
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: label
            color: textColor
            font.pixelSize: Style.Typography.componentSubtitle
            font.family: Style.Typography.text
            opacity: 0.5
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(value) + "%"
            color: accent
            font.pixelSize: Style.Typography.componentSubtitle
            font.family: Style.Typography.text
        }

    }

}
