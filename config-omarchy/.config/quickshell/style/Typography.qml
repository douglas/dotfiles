pragma Singleton

import QtQuick
import Quickshell

QtObject {
    readonly property real scale: Math.max(0.75, Math.min(1.75, Number(Quickshell.env("QS_FONT_SCALE") || 1.0)))

    function px(value) {
        return Math.round(value * scale)
    }

    function scaledPx(value, multiplier) {
        const localScale = Number(multiplier || 1.0)
        return px(value * (isNaN(localScale) ? 1.0 : localScale))
    }

    readonly property int nano: px(7)
    readonly property int micro: px(8)
    readonly property int caption: px(9)
    readonly property int label: px(10)
    readonly property int bodySmall: px(11)
    readonly property int body: px(12)
    readonly property int bodyLarge: px(13)
    readonly property int titleSmall: px(14)
    readonly property int title: px(15)
    readonly property int heading: px(18)
    readonly property int headingLarge: px(19)
    readonly property int display: px(20)
    readonly property int displayLarge: px(22)
    readonly property int displayXl: px(24)
    readonly property int display2Xl: px(28)
    readonly property int display3Xl: px(30)
    readonly property int display4Xl: px(34)
    readonly property int display5Xl: px(48)
    readonly property int display6Xl: px(72)

    readonly property int iconSmall: px(13)
    readonly property int icon: px(16)
    readonly property int iconLarge: px(20)

    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string monoPropo: "JetBrainsMono Nerd Font Propo"
    readonly property string text: "JetBrains Mono"

    function scaledNano(multiplier) { return scaledPx(7, multiplier) }
    function scaledMicro(multiplier) { return scaledPx(8, multiplier) }
    function scaledCaption(multiplier) { return scaledPx(9, multiplier) }
    function scaledLabel(multiplier) { return scaledPx(10, multiplier) }
    function scaledBodySmall(multiplier) { return scaledPx(11, multiplier) }
    function scaledBody(multiplier) { return scaledPx(12, multiplier) }
    function scaledBodyLarge(multiplier) { return scaledPx(13, multiplier) }
    function scaledTitleSmall(multiplier) { return scaledPx(14, multiplier) }
    function scaledTitle(multiplier) { return scaledPx(15, multiplier) }
    function scaledHeading(multiplier) { return scaledPx(18, multiplier) }
    function scaledHeadingLarge(multiplier) { return scaledPx(19, multiplier) }
    function scaledDisplay(multiplier) { return scaledPx(20, multiplier) }
    function scaledDisplayLarge(multiplier) { return scaledPx(22, multiplier) }
    function scaledDisplayXl(multiplier) { return scaledPx(24, multiplier) }
    function scaledDisplay2Xl(multiplier) { return scaledPx(28, multiplier) }
    function scaledDisplay3Xl(multiplier) { return scaledPx(30, multiplier) }
    function scaledDisplay4Xl(multiplier) { return scaledPx(34, multiplier) }
    function scaledDisplay5Xl(multiplier) { return scaledPx(48, multiplier) }
    function scaledDisplay6Xl(multiplier) { return scaledPx(72, multiplier) }
}
