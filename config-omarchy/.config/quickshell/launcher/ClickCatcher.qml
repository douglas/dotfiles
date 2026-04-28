import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool active: false
    property int topInset: 0
    property int bottomInset: 0

    signal clicked

    anchors { left: true; right: true; top: true; bottom: true }
    margins { top: root.topInset; bottom: root.bottomInset }
    color:         "transparent"
    exclusiveZone: -1
    visible:       active
    WlrLayershell.layer: WlrLayer.Top

    MouseArea {
        anchors.fill: parent
        onClicked:    root.clicked()
    }
}
