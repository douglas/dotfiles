import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: root

    property bool showing: false
    property var theme: ({})
    property real uiScale: 1.0
    property var images: []
    property int selectedIdx: 0
    readonly property var selectedImage: images.length > 0
        ? images[Math.max(0, Math.min(selectedIdx, images.length - 1))]
        : ({})

    readonly property string scanScript: '
fd -H -L -t f \
  -e jpg -e jpeg -e png -e webp -e gif -e bmp -e heic -e avif \
  . "$HOME/Pictures" \
  -x stat -c "%Y|%n" 2>/dev/null | sort -t "|" -k 1,1nr | awk "NR <= 10"
'

    title: "Quickshell Pictures"
    color: "transparent"
    visible: showing
    implicitWidth: 980
    implicitHeight: 600
    minimumSize: Qt.size(720, 420)
    maximumSize: Qt.size(1200, 820)

    function shellQuote(s) {
        if (s === undefined || s === null)
            return "''"
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function fileUrl(path) {
        return path && path !== "" ? "file://" + encodeURI(path) : ""
    }

    function dragMimeData(path) {
        const url = fileUrl(path)
        return {
            "text/plain": path || "",
            "text/uri-list": url ? url + "\n" : ""
        }
    }

    function prepareDragImage(item, width, height) {
        item.grabToImage(function(result) {
            item.Drag.imageSource = result.url
        }, Qt.size(width, height))
    }

    function reload() {
        imageScanner.stdout.buf = []
        imageScanner.running = false
        imageScanner.running = true
    }

    function openImage(path) {
        if (!path || path === "")
            return
        Quickshell.execDetached(["bash", "-lc", "xdg-open " + shellQuote(path)])
        showing = false
    }

    function moveSelection(delta) {
        if (images.length === 0)
            return
        selectedIdx = Math.max(0, Math.min(selectedIdx + delta, images.length - 1))
        filmstrip.positionViewAtIndex(selectedIdx, ListView.Contain)
    }

    Process {
        id: imageScanner
        command: ["bash", "-lc", root.scanScript]
        running: false
        stdout: SplitParser {
            property var buf: []
            onRead: data => {
                const line = data.trim()
                const sep = line.indexOf("|")
                if (sep === -1)
                    return

                const path = line.substring(sep + 1)
                const nameParts = path.split("/")
                buf.push({
                    path: path,
                    name: nameParts[nameParts.length - 1],
                    source: root.fileUrl(path)
                })
            }
        }
        onExited: {
            root.images = imageScanner.stdout.buf.slice()
            root.selectedIdx = 0
            imageScanner.stdout.buf = []
        }
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                root.showing = false
                e.accepted = true
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                root.openImage(root.selectedImage.path)
                e.accepted = true
            } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down) {
                root.moveSelection(1)
                e.accepted = true
            } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up) {
                root.moveSelection(-1)
                e.accepted = true
            }
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 12
            color: theme.bg || "#1e1e2e"
            border.color: theme.dim || "#45475a"
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    spacing: 8

                    Text {
                        text: ""
                        color: theme.accent || "#89b4fa"
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        text: "Recent Pictures"
                        color: theme.fg || "#cdd6f4"
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Medium
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.images.length + " images"
                        color: Qt.alpha(theme.muted || "#585b70", 0.55)
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        text: "✕"
                        color: Qt.alpha(theme.muted || "#585b70", 0.7)
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showing = false
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.images.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: imageScanner.running ? "Loading pictures..." : "No images found in ~/Pictures"
                        color: Qt.alpha(theme.muted || "#585b70", 0.6)
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.images.length > 0
                    spacing: 12

                    Rectangle {
                        id: previewPane
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: Qt.alpha(theme.dim || "#45475a", 0.24)
                        border.width: 1
                        border.color: Qt.alpha(theme.dim || "#45475a", 0.65)
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                Item {
                                    id: selectedDragItem
                                    x: 0
                                    y: 0
                                    width: parent.width
                                    height: parent.height

                                    Drag.dragType: Drag.Automatic
                                    Drag.supportedActions: Qt.CopyAction
                                    Drag.proposedAction: Qt.CopyAction
                                    Drag.mimeData: root.dragMimeData(root.selectedImage.path)
                                    Drag.imageSource: root.selectedImage.source || ""
                                    Drag.imageSourceSize: Qt.size(220, 140)
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2
                                    Drag.active: selectedMouse.drag.active

                                    Drag.onDragFinished: {
                                        x = 0
                                        y = 0
                                        root.showing = false
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: theme.bg || "#1e1e2e"
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 1
                                            source: root.selectedImage.source || ""
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            cache: false
                                            smooth: true
                                        }
                                    }
                                }

                                MouseArea {
                                    id: selectedMouse
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.OpenHandCursor
                                    drag.target: selectedDragItem
                                    drag.threshold: 6
                                    onPressed: mouse => {
                                        root.prepareDragImage(selectedDragItem, 220, 140)
                                        mouse.accepted = true
                                    }
                                    onReleased: {
                                        selectedDragItem.x = 0
                                        selectedDragItem.y = 0
                                    }
                                    onCanceled: {
                                        selectedDragItem.x = 0
                                        selectedDragItem.y = 0
                                    }
                                    onDoubleClicked: root.openImage(root.selectedImage.path)
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: root.selectedImage.name || ""
                                    color: theme.fg || "#cdd6f4"
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideMiddle
                                }

                                Text {
                                    text: (root.selectedIdx + 1) + " / " + root.images.length
                                    color: Qt.alpha(theme.muted || "#585b70", 0.72)
                                    font.pixelSize: 9
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: stripPane
                        Layout.preferredWidth: 214
                        Layout.fillHeight: true
                        radius: 10
                        color: Qt.alpha(theme.dim || "#45475a", 0.18)
                        border.width: 1
                        border.color: Qt.alpha(theme.dim || "#45475a", 0.55)
                        clip: true

                        ListView {
                            id: filmstrip
                            anchors.fill: parent
                            anchors.margins: 8
                            model: root.images
                            spacing: 8
                            clip: true

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                width: 2
                            }

                            delegate: Item {
                                id: delegateItem
                                width: filmstrip.width
                                height: 86

                                property var imageData: root.images[index] || {}
                                property bool selected: index === root.selectedIdx
                                property bool hovered: false

                                Item {
                                    id: thumb
                                    x: 0
                                    y: 0
                                    width: parent.width
                                    height: parent.height

                                    Drag.dragType: Drag.Automatic
                                    Drag.supportedActions: Qt.CopyAction
                                    Drag.proposedAction: Qt.CopyAction
                                    Drag.mimeData: root.dragMimeData(delegateItem.imageData.path)
                                    Drag.imageSource: delegateItem.imageData.source || ""
                                    Drag.imageSourceSize: Qt.size(160, 90)
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2
                                    Drag.active: thumbnailMouse.drag.active

                                    Drag.onDragFinished: {
                                        x = 0
                                        y = 0
                                        root.showing = false
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: selected
                                            ? Qt.alpha(theme.accent || "#89b4fa", 0.17)
                                            : Qt.alpha(theme.dim || "#45475a", hovered ? 0.34 : 0.22)
                                        border.width: selected ? 2 : 1
                                        border.color: selected
                                            ? (theme.accent || "#89b4fa")
                                            : Qt.alpha(theme.dim || "#45475a", 0.62)
                                        clip: true

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 8

                                            Rectangle {
                                                Layout.preferredWidth: 82
                                                Layout.fillHeight: true
                                                radius: 6
                                                color: theme.bg || "#1e1e2e"
                                                clip: true

                                                Image {
                                                    anchors.fill: parent
                                                    source: delegateItem.imageData.source || ""
                                                    fillMode: Image.PreserveAspectCrop
                                                    asynchronous: true
                                                    cache: false
                                                    smooth: true
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                spacing: 3

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: delegateItem.imageData.name || ""
                                                    color: selected
                                                        ? (theme.accent || "#89b4fa")
                                                        : (theme.fg || "#cdd6f4")
                                                    font.pixelSize: 9
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    elide: Text.ElideMiddle
                                                    maximumLineCount: 2
                                                    wrapMode: Text.WrapAnywhere
                                                }

                                                Item { Layout.fillHeight: true }

                                                Text {
                                                    text: "#" + (index + 1)
                                                    color: Qt.alpha(theme.muted || "#585b70", 0.62)
                                                    font.pixelSize: 8
                                                    font.family: "JetBrainsMono Nerd Font"
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: thumbnailMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor
                                    drag.target: thumb
                                    drag.threshold: 6
                                    onEntered: delegateItem.hovered = true
                                    onExited: delegateItem.hovered = false
                                    onPressed: mouse => {
                                        root.selectedIdx = index
                                        root.prepareDragImage(thumb, 160, 90)
                                        mouse.accepted = true
                                    }
                                    onReleased: {
                                        thumb.x = 0
                                        thumb.y = 0
                                    }
                                    onCanceled: {
                                        thumb.x = 0
                                        thumb.y = 0
                                    }
                                    onClicked: mouse => {
                                        root.selectedIdx = index
                                        mouse.accepted = true
                                    }
                                    onDoubleClicked: root.openImage(delegateItem.imageData.path)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    onShowingChanged: {
        if (showing) {
            root.reload()
            focusTimer.start()
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: focusScope.forceActiveFocus()
    }
}
