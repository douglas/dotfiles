import "../../style" as Style
import QtQuick
import Quickshell
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
    readonly property bool use24h: settings ? settings.clockUse24h : true
    readonly property real popupScale: Math.max(1, overlayScale)

    function overlayPx(value) {
        return Math.round(value * popupScale);
    }

    function updateTime() {
        const now = new Date();
        let h = now.getHours();
        const min = String(now.getMinutes()).padStart(2, "0");
        if (use24h) {
            timeText.text = String(h).padStart(2, "0") + ":" + min;
            ampmText.text = "";
        } else {
            ampmText.text = h >= 12 ? "PM" : "AM";
            h = h % 12 || 12;
            timeText.text = String(h).padStart(2, "0") + ":" + min;
        }
        dateText.text = Qt.formatDate(now, "ddd, d MMM");
    }

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    implicitWidth: clockRow.implicitWidth
    implicitHeight: 28
    Component.onCompleted: updateTime()
    onUse24hChanged: updateTime()

    Timer {
        interval: 15000
        running: !root.quietMode
        repeat: true
        onTriggered: updateTime()
    }

    // ── Clock row ─────────────────────────────────
    Row {
        id: clockRow

        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                id: timeText

                anchors.verticalCenter: parent.verticalCenter
                color: theme.fg || "#cdd6f4"
                font.pixelSize: Style.Typography.barText
                font.family: Style.Typography.mono
                font.weight: Font.Medium
            }

            Text {
                id: ampmText

                visible: !root.use24h
                anchors.verticalCenter: parent.verticalCenter
                color: theme.accent || "#89b4fa"
                font.pixelSize: Style.Typography.componentMeta
                font.family: Style.Typography.mono
                font.weight: Font.Medium
                bottomPadding: 1
            }

        }

        Rectangle {
            width: 1
            height: 10
            color: theme.dim || "#45475a"
            opacity: 0.5
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: dateText

            anchors.verticalCenter: parent.verticalCenter
            color: theme.fg || "#cdd6f4"
            font.pixelSize: Style.Typography.componentSubtitle
            font.family: Style.Typography.mono
        }

    }

    GoogleCalendar {
        id: agendaCalendar

        showTrigger: false
        barWindow: root.barWindow
        barOnBottom: root.barOnBottom
        overlayBarOffset: root.overlayBarOffset
        overlayScale: root.overlayScale
        quietMode: root.quietMode
        settings: root.settings
        theme: root.theme
    }

    MouseArea {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, dateText.x + dateText.width)
        height: parent.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: agendaCalendar.showing = !agendaCalendar.showing
    }

}
