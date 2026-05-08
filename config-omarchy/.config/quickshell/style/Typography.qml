import QtQuick
import Quickshell
pragma Singleton

QtObject {
    readonly property real scale: Math.max(0.75, Math.min(1.75, Number(Quickshell.env("QS_FONT_SCALE") || 1)))
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
    readonly property int barIcon: icon
    readonly property int rightClusterIcon: trayBody
    readonly property int headerIcon: actionIcon
    readonly property int listIcon: icon
    readonly property int dockIcon: iconLarge
    readonly property int actionIcon: iconLarge
    readonly property int closeIcon: iconLarge
    readonly property int searchIcon: actionIcon
    readonly property int checkIcon: iconSmall
    readonly property int breadcrumbIcon: iconSmall
    readonly property int terminalIcon: listIcon
    readonly property int tileIcon: display
    readonly property int placeholderIcon: displayXl
    readonly property int previewIcon: display3Xl
    readonly property int largePreviewIcon: display6Xl
    readonly property int componentTitle: titleSmall
    readonly property int componentSubtitle: body
    readonly property int componentBody: body
    readonly property int componentMeta: bodySmall
    readonly property int barText: bodyLarge
    readonly property int dialogTitle: titleSmall
    readonly property int launcherTitle: titleSmall
    readonly property int launcherInputText: bodyLarge
    readonly property int launcherItemTitle: bodyLarge
    readonly property int launcherItemBody: body
    readonly property int recentTitle: titleSmall
    readonly property int recentBody: body
    readonly property int recentHeaderIcon: actionIcon
    readonly property int recentActionIcon: actionIcon
    readonly property int recentCloseIcon: closeIcon
    readonly property int recentPreviewIcon: previewIcon
    readonly property int recentLargePreviewIcon: largePreviewIcon
    readonly property int recentMeta: body
    readonly property int recentSettingsValue: settingsPreview
    readonly property int settingsTitle: display
    readonly property int settingsSectionTitle: heading
    readonly property int settingsPageTitle: title
    readonly property int settingsBody: body
    readonly property int settingsPreview: bodyLarge
    readonly property int widgetDisplay: display4Xl
    readonly property int clockDisplay: display5Xl
    readonly property int pomodoroDisplay: display4Xl
    readonly property int taskTitle: bodyLarge
    readonly property int statValue: display
    readonly property int trayBody: body
    readonly property int osdTitle: title
    readonly property int osdBody: body
    readonly property int notificationBody: body
    readonly property int toggleIcon: heading
    readonly property int controlTitle: bodyLarge
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string monoPropo: "JetBrainsMono Nerd Font Propo"
    readonly property string text: "JetBrains Mono"

    function px(value) {
        return Math.round(value * scale);
    }

    function scaledPx(value, multiplier) {
        const localScale = Number(multiplier || 1);
        return px(value * (isNaN(localScale) ? 1 : localScale));
    }

    function scaledNano(multiplier) {
        return scaledPx(7, multiplier);
    }

    function scaledMicro(multiplier) {
        return scaledPx(8, multiplier);
    }

    function scaledCaption(multiplier) {
        return scaledPx(9, multiplier);
    }

    function scaledLabel(multiplier) {
        return scaledPx(10, multiplier);
    }

    function scaledBodySmall(multiplier) {
        return scaledPx(11, multiplier);
    }

    function scaledBody(multiplier) {
        return scaledPx(12, multiplier);
    }

    function scaledBodyLarge(multiplier) {
        return scaledPx(13, multiplier);
    }

    function scaledTitleSmall(multiplier) {
        return scaledPx(14, multiplier);
    }

    function scaledTitle(multiplier) {
        return scaledPx(15, multiplier);
    }

    function scaledHeading(multiplier) {
        return scaledPx(18, multiplier);
    }

    function scaledHeadingLarge(multiplier) {
        return scaledPx(19, multiplier);
    }

    function scaledDisplay(multiplier) {
        return scaledPx(20, multiplier);
    }

    function scaledDisplayLarge(multiplier) {
        return scaledPx(22, multiplier);
    }

    function scaledDisplayXl(multiplier) {
        return scaledPx(24, multiplier);
    }

    function scaledDisplay2Xl(multiplier) {
        return scaledPx(28, multiplier);
    }

    function scaledDisplay3Xl(multiplier) {
        return scaledPx(30, multiplier);
    }

    function scaledDisplay4Xl(multiplier) {
        return scaledPx(34, multiplier);
    }

    function scaledDisplay5Xl(multiplier) {
        return scaledPx(48, multiplier);
    }

    function scaledDisplay6Xl(multiplier) {
        return scaledPx(72, multiplier);
    }

    function scaledActionIcon(multiplier) {
        return scaledPx(20, multiplier);
    }

    function scaledHeaderIcon(multiplier) {
        return scaledActionIcon(multiplier);
    }

    function scaledCloseIcon(multiplier) {
        return scaledActionIcon(multiplier);
    }

    function scaledListIcon(multiplier) {
        return scaledPx(16, multiplier);
    }

    function scaledTileIcon(multiplier) {
        return scaledPx(20, multiplier);
    }

    function scaledPreviewIcon(multiplier) {
        return scaledPx(30, multiplier);
    }

    function scaledNavigationIcon(multiplier) {
        return scaledTitle(multiplier);
    }

    function scaledCalendarIcon(multiplier) {
        return scaledListIcon(multiplier);
    }

    function scaledCalendarHeaderIcon(multiplier) {
        return scaledCalendarIcon(multiplier);
    }

    function scaledCalendarNavigationIcon(multiplier) {
        return scaledCalendarIcon(multiplier);
    }

    function scaledComponentSubtitle(multiplier) {
        return scaledBody(multiplier);
    }

    function scaledComponentBody(multiplier) {
        return scaledBody(multiplier);
    }

    function scaledComponentMeta(multiplier) {
        return scaledBodySmall(multiplier);
    }

    function customIcon(value) {
        return px(value);
    }

    function customPreview(value) {
        return px(value);
    }

}
