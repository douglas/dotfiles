import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../style" as Style

Item {
    id: root

    property var service: null
    property var settings: null
    property var theme: ({})
    property real uiScale: 1.0

    function t(key, fallback) { return theme[key] || fallback }
    function px(value) { return Math.round(value * uiScale) }

    readonly property string osdPosition: settings?.osdPosition || "top-right"
    readonly property real reveal: service && service.showing ? 1 : 0
    readonly property bool mediaMode: service && service.mediaMode
    readonly property bool messageMode: service && service.messageMode
    readonly property bool meterMode: service && !mediaMode && !messageMode
    readonly property int panelWidth: px(mediaMode ? 410 : (messageMode ? 360 : 320))
    readonly property int panelHeight: px(mediaMode ? 126 : (messageMode ? 78 : 76))
    readonly property int topOffset: px(58)
    readonly property int edgeOffset: px(18)

    function toneColor() {
        if (!service) return t("accent", "#89b4fa")
        if (service.tone === "red") return t("red", "#f38ba8")
        if (service.tone === "green") return t("green", "#a6e3a1")
        if (service.tone === "highlight") return t("highlight", "#cba6f7")
        if (service.tone === "muted") return t("muted", "#585b70")
        return t("accent", "#89b4fa")
    }

    Component {
        id: osdChrome

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: root.px(18)
            color: root.t("bg", "#1e1e2e")
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            opacity: root.reveal
            y: (1 - root.reveal) * 4
            scale: 0.99 + (0.01 * root.reveal)
            clip: true

            Behavior on opacity {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }

            Behavior on y {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }

            Canvas {
                id: wave
                anchors.fill: parent
                visible: root.mediaMode
                opacity: 0.18

                Connections {
                    target: root.service
                    function onValueChanged() { wave.requestPaint() }
                    function onToneChanged() { wave.requestPaint() }
                    function onWaveChanged() { wave.requestPaint() }
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const w = width
                    const h = height
                    ctx.clearRect(0, 0, w, h)
                    if (!root.service)
                        return

                    const samples = root.service.wave || []
                    if (samples.length < 2)
                        return

                    const baseY = h * 0.72
                    const amp = h * 0.34
                    const step = w / Math.max(1, samples.length - 1)
                    const pts = []

                    for (let i = 0; i < samples.length; i++) {
                        const x = i * step
                        const y = baseY - Math.max(0, Math.min(1, samples[i])) * amp
                        pts.push({ x: x, y: y })
                    }

                    ctx.beginPath()
                    ctx.moveTo(0, h)
                    ctx.lineTo(pts[0].x, pts[0].y)

                    for (let i2 = 0; i2 < pts.length - 1; i2++) {
                        const p0 = pts[i2]
                        const p1 = pts[i2 + 1]
                        const cx = (p0.x + p1.x) * 0.5
                        const cy = (p0.y + p1.y) * 0.5
                        ctx.quadraticCurveTo(p0.x, p0.y, cx, cy)
                    }

                    const plast = pts[pts.length - 1]
                    ctx.lineTo(plast.x, plast.y)
                    ctx.lineTo(w, h)
                    ctx.closePath()
                    ctx.fillStyle = Qt.alpha(root.toneColor(), 0.18)
                    ctx.fill()

                    ctx.beginPath()
                    ctx.moveTo(pts[0].x, pts[0].y)
                    for (let i3 = 0; i3 < pts.length - 1; i3++) {
                        const a = pts[i3]
                        const b = pts[i3 + 1]
                        const mx = (a.x + b.x) * 0.5
                        const my = (a.y + b.y) * 0.5
                        ctx.quadraticCurveTo(a.x, a.y, mx, my)
                    }
                    ctx.lineTo(plast.x, plast.y)
                    ctx.lineWidth = 1
                    ctx.strokeStyle = Qt.alpha(root.toneColor(), 0.38)
                    ctx.stroke()
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 10
                enabled: root.messageMode
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (!root.service)
                        return

                    if (mouse.button === Qt.RightButton)
                        root.service.dismissMessage()
                    else
                        root.service.activateMessage()
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: root.px(14)
                anchors.rightMargin: root.px(14)
                anchors.topMargin: root.messageMode ? root.px(10) : root.px(11)
                anchors.bottomMargin: root.messageMode ? root.px(10) : root.px(11)
                spacing: root.messageMode ? root.px(6) : root.px(8)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.px(10)

                    Rectangle {
                        visible: root.mediaMode
                        Layout.preferredWidth: visible ? root.px(54) : 0
                        Layout.preferredHeight: visible ? root.px(54) : 0
                        radius: root.px(14)
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        clip: true

                        Image {
                            id: coverArt
                            anchors.fill: parent
                            source: root.service ? root.service.artUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            visible: status === Image.Ready && source !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !coverArt.visible
                            text: "󰎆"
                            color: root.toneColor()
                            font.pixelSize: Style.Typography.tileIcon
                            font.family: Style.Typography.mono
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.service && root.service.subtitle ? root.px(2) : 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.px(8)

                            Item {
                                Layout.preferredWidth: root.px(22)
                                Layout.preferredHeight: root.px(22)

                                IconImage {
                                    id: osdIconImage
                                    anchors.centerIn: parent
                                    width: root.px(20)
                                    height: root.px(20)
                                    implicitSize: root.px(20)
                                    source: root.service ? root.service.iconSource : ""
                                    asynchronous: true
                                    mipmap: true
                                    visible: source !== "" && status !== Image.Error
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.service ? root.service.icon : "󰕾"
                                    color: root.toneColor()
                                    font.pixelSize: Style.Typography.actionIcon
                                    font.family: Style.Typography.mono
                                    visible: !osdIconImage.visible
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.service ? root.service.title : "OSD"
                                color: root.t("fg", "#cdd6f4")
                                font.pixelSize: Style.Typography.osdTitle
                                font.weight: Font.DemiBold
                                font.family: Style.Typography.mono
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.service ? root.service.valueText : "0%"
                                visible: !root.messageMode
                                color: root.t("muted", "#585b70")
                                font.pixelSize: Style.Typography.osdBody
                                font.weight: Font.Medium
                                font.family: Style.Typography.mono
                            }
                        }

                        Text {
                            visible: root.service && root.service.subtitle !== ""
                            Layout.fillWidth: true
                            text: root.service ? root.service.subtitle : ""
                            color: root.t("muted", "#585b70")
                            font.pixelSize: Style.Typography.osdBody
                            font.family: Style.Typography.mono
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        RowLayout {
                            visible: root.mediaMode
                            Layout.fillWidth: true
                            spacing: root.px(8)

                            Rectangle {
                                Layout.preferredWidth: root.px(24)
                                Layout.preferredHeight: root.px(24)
                                radius: root.px(8)
                                color: prevMouse.containsMouse
                                    ? Qt.alpha(root.toneColor(), 0.20)
                                    : Qt.rgba(1, 1, 1, 0.06)
                                border.color: root.service && root.service.mediaCanGoPrevious
                                    ? Qt.alpha(root.toneColor(), 0.32)
                                    : Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                opacity: root.service && root.service.mediaCanGoPrevious ? 1 : 0.42

                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -1
                                    text: "󰒮"
                                    color: root.toneColor()
                                    font.pixelSize: Style.Typography.componentSubtitle
                                    font.family: Style.Typography.mono
                                }

                                MouseArea {
                                    id: prevMouse
                                    anchors.fill: parent
                                    enabled: root.service && root.service.mediaCanGoPrevious
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.service.mediaPrev()
                                }
                            }

                            Item {
                                id: mediaProgressWrap
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.px(24)

                                Rectangle {
                                    id: mediaProgressTrack
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: root.px(7)
                                    radius: root.px(4)
                                    color: Qt.rgba(1, 1, 1, 0.18)
                                    border.color: Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    clip: true

                                    Rectangle {
                                        width: parent.width * ((root.service ? root.service.value : 0) / 100)
                                        height: parent.height
                                        radius: root.px(4)
                                        color: root.toneColor()

                                        Behavior on width {
                                            enabled: !mediaProgressMouse.pressed
                                            NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: root.px(11)
                                    height: width
                                    radius: width / 2
                                    anchors.verticalCenter: mediaProgressTrack.verticalCenter
                                    x: Math.max(
                                        0,
                                        Math.min(
                                            parent.width - width,
                                            (parent.width * ((root.service ? root.service.value : 0) / 100)) - width / 2
                                        )
                                    )
                                    color: root.toneColor()
                                    border.color: root.t("bg", "#1e1e2e")
                                    border.width: 1
                                    visible: root.service && root.service.mediaCanSeek
                                }

                                MouseArea {
                                    id: mediaProgressMouse
                                    anchors.fill: parent
                                    enabled: root.service && root.service.mediaCanSeek
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    function seekAt(xPos) {
                                        if (!root.service || mediaProgressWrap.width <= 0)
                                            return

                                        root.service.mediaSeekToRatio(xPos / mediaProgressWrap.width)
                                    }

                                    onPressed: mouse => seekAt(mouse.x)
                                    onPositionChanged: mouse => {
                                        if (pressed)
                                            seekAt(mouse.x)
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: root.px(28)
                                Layout.preferredHeight: root.px(28)
                                radius: root.px(10)
                                color: playMouse.containsMouse
                                    ? Qt.alpha(root.toneColor(), 0.24)
                                    : Qt.alpha(root.toneColor(), 0.14)
                                border.color: Qt.alpha(root.toneColor(), 0.34)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -1
                                    text: root.service && root.service.icon === "󰐊" ? "󰐊" : "󰏤"
                                    color: root.toneColor()
                                    font.pixelSize: Style.Typography.componentSubtitle
                                    font.family: Style.Typography.mono
                                }

                                MouseArea {
                                    id: playMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.service.mediaPlayPause()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: root.px(24)
                                Layout.preferredHeight: root.px(24)
                                radius: root.px(8)
                                color: nextMouse.containsMouse
                                    ? Qt.alpha(root.toneColor(), 0.20)
                                    : Qt.rgba(1, 1, 1, 0.06)
                                border.color: root.service && root.service.mediaCanGoNext
                                    ? Qt.alpha(root.toneColor(), 0.32)
                                    : Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                opacity: root.service && root.service.mediaCanGoNext ? 1 : 0.42

                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -1
                                    text: "󰒭"
                                    color: root.toneColor()
                                    font.pixelSize: Style.Typography.componentSubtitle
                                    font.family: Style.Typography.mono
                                }

                                MouseArea {
                                    id: nextMouse
                                    anchors.fill: parent
                                    enabled: root.service && root.service.mediaCanGoNext
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.service.mediaNext()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: progressTrack
                    visible: root.meterMode
                    Layout.fillWidth: true
                    height: root.px(5)
                    radius: root.px(3)
                    color: Qt.rgba(1, 1, 1, 0.14)
                    clip: true

                    Rectangle {
                        width: parent.width * ((root.service ? root.service.value : 0) / 100)
                        height: parent.height
                        radius: 2
                        color: root.toneColor()

                        Behavior on width {
                            NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        visible: root.osdPosition === "top-left" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { top: true; left: true }
        margins { top: root.topOffset; left: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "top-center" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { top: true }
        margins { top: root.topOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "top-right" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { top: true; right: true }
        margins { top: root.topOffset; right: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "bottom-left" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { bottom: true; left: true }
        margins { bottom: root.edgeOffset; left: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "bottom-center" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { bottom: true }
        margins { bottom: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }

    PanelWindow {
        visible: root.osdPosition === "bottom-right" && (root.service && (root.service.showing || root.reveal > 0.001))
        implicitWidth: root.panelWidth
        implicitHeight: root.panelHeight
        anchors { bottom: true; right: true }
        margins { bottom: root.edgeOffset; right: root.edgeOffset }
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Loader { anchors.fill: parent; sourceComponent: osdChrome }
    }
}
