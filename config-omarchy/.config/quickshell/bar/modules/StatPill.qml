import "../../style" as Style
import QtQuick

Item {
    id: root

    property string label: ""
    property string icon: ""
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

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Style.Typography.rightClusterIcon
            height: Style.Typography.rightClusterIcon

            Text {
                anchors.centerIn: parent
                text: root.icon !== "" ? root.icon : root.label
                color: textColor
                font.pixelSize: root.icon !== "" ? Math.max(1, Style.Typography.rightClusterIcon - 2) : Style.Typography.componentSubtitle
                font.family: root.icon !== "" ? Style.Typography.mono : Style.Typography.text
                font.weight: Font.Normal
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: 0.5
            }
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
