import "../style" as Style
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: root

    property bool showing: false
    property string mode: "pictures"
    property var theme: ({
    })
    property var settings: null
    property real uiScale: 1
    readonly property real overlayScale: Math.max(1, uiScale)
    property var files: []
    property var picturesFiles: []
    property var downloadsFiles: []
    property int selectedIdx: 0
    property bool settingsOpen: false
    readonly property var imageExtensions: ["jpg", "jpeg", "png", "webp", "gif", "bmp", "heic", "avif"]
    readonly property var profiles: ({
        "pictures": {
            "title": "Recent Pictures",
            "icon": "",
            "dir": "$HOME/Pictures",
            "extensions": root.imageExtensions,
            "recursive": true,
            "singular": "image",
            "plural": "images",
            "loadingText": "Loading pictures...",
            "emptyText": "No images found in ~/Pictures",
            "settingLabel": "Images to load"
        },
        "downloads": {
            "title": "Recent Downloads",
            "icon": "",
            "dir": "$HOME/Downloads",
            "extensions": [],
            "recursive": false,
            "singular": "file",
            "plural": "files",
            "loadingText": "Loading downloads...",
            "emptyText": "No files found in ~/Downloads",
            "settingLabel": "Files to load"
        }
    })
    readonly property var activeProfile: mode === "downloads" ? profiles.downloads : profiles.pictures
    readonly property int fileLimit: settings ? Math.max(1, Math.min(50, Math.round(mode === "downloads" ? settings.downloadsFileLimit : settings.picturesImageLimit))) : 10
    readonly property var selectedFile: files.length > 0 ? files[Math.max(0, Math.min(selectedIdx, files.length - 1))] : ({
    })

    function overlayPx(value) {
        return Math.round(value * overlayScale);
    }

    function shellQuote(s) {
        if (s === undefined || s === null)
            return "''";

        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function fileUrl(path) {
        if (!path || path === "")
            return "";

        return "file://" + String(path).split("/").map(part => encodeURIComponent(part)).join("/");
    }

    function extension(path) {
        const value = String(path || "");
        const idx = value.lastIndexOf(".");
        return idx >= 0 ? value.substring(idx + 1).toLowerCase() : "";
    }

    function isImagePath(path) {
        return imageExtensions.indexOf(extension(path)) !== -1;
    }

    function fileObject(path) {
        const nameParts = path.split("/");
        const ext = extension(path);
        const image = isImagePath(path);
        return {
            "path": path,
            "name": nameParts[nameParts.length - 1],
            "extension": ext,
            "isImage": image,
            "source": image ? fileUrl(path) : ""
        };
    }

    function fileFromScanLine(line) {
        const sep = line.indexOf("|");
        if (sep === -1)
            return null;

        return fileObject(line.substring(sep + 1));
    }

    function fileIcon(file) {
        const ext = file.extension || "";
        if (ext === "pdf")
            return "";

        if (["zip", "gz", "xz", "7z", "rar", "tar"].indexOf(ext) !== -1)
            return "";

        if (["mp4", "mkv", "mov", "webm"].indexOf(ext) !== -1)
            return "";

        if (["mp3", "flac", "wav", "ogg"].indexOf(ext) !== -1)
            return "";

        if (["txt", "md", "json", "csv", "log"].indexOf(ext) !== -1)
            return "";

        return "";
    }

    function dragMimeData(path) {
        const url = fileUrl(path);
        return url ? {
            "text/uri-list": url
        } : ({
        });
    }

    function prepareDragImage(item, width, height) {
        item.grabToImage(function(result) {
            item.Drag.imageSource = result.url;
        }, Qt.size(width, height));
    }

    function normalizeMode(requestedMode) {
        return requestedMode === "downloads" ? "downloads" : "pictures";
    }

    function cachedFiles(requestedMode) {
        return normalizeMode(requestedMode) === "downloads" ? downloadsFiles : picturesFiles;
    }

    function setCachedFiles(requestedMode, nextFiles) {
        if (normalizeMode(requestedMode) === "downloads")
            downloadsFiles = nextFiles;
        else
            picturesFiles = nextFiles;
    }

    function setMode(requestedMode) {
        const nextMode = normalizeMode(requestedMode);
        if (mode !== nextMode) {
            files = cachedFiles(nextMode).slice();
            selectedIdx = 0;
            fileScanner.stdout.buf = [];
        }
        mode = nextMode;
    }

    function profileForMode(requestedMode) {
        return normalizeMode(requestedMode) === "downloads" ? profiles.downloads : profiles.pictures;
    }

    function toggleMode(requestedMode) {
        const nextMode = normalizeMode(requestedMode);
        if (showing && mode === nextMode) {
            showing = false;
            return ;
        }
        if (showing) {
            setMode(nextMode);
            settingsOpen = false;
            reload();
            focusTimer.start();
            return ;
        }
        setMode(nextMode);
        showing = true;
    }

    function reload() {
        fileScanner.stdout.buf = [];
        refreshMode(mode);
    }

    function refreshMode(requestedMode) {
        fileScanner.scanMode = normalizeMode(requestedMode);
        fileScanner.running = false;
        fileScanner.running = true;
    }

    function extensionArgs(requestedMode) {
        let args = "";
        const extensions = profileForMode(requestedMode).extensions || [];
        for (let i = 0; i < extensions.length; i++) args += "-e " + extensions[i] + " "
        return args;
    }

    function scanScript(requestedMode) {
        const scanMode = normalizeMode(requestedMode);
        const profile = profileForMode(scanMode);
        const depthArg = profile.recursive ? "" : "--max-depth 1 ";
        return "fd -H -L -t f " + depthArg + extensionArgs(scanMode) + "-0 . \"" + profile.dir + "\" 2>/dev/null | " + "xargs -0 -r stat -c \"%Y|%n\" | sort -t \"|\" -k 1,1nr | head -n " + fileLimit;
    }

    function setFileLimit(value) {
        const next = Math.max(1, Math.min(50, Math.round(value)));
        if (settings) {
            if (mode === "downloads")
                settings.downloadsFileLimit = next;
            else
                settings.picturesImageLimit = next;
        }
        reload();
    }

    function openFile(path) {
        if (!path || path === "")
            return ;

        Quickshell.execDetached(["bash", "-lc", "xdg-open " + shellQuote(path)]);
        showing = false;
    }

    function copyImageMetadata(path) {
        if (!path || path === "")
            return ;

        Quickshell.execDetached(["bash", "-lc", "printf '%s' " + shellQuote(path) + " | wl-copy"]);
        showing = false;
    }

    function activateSelected() {
        if (mode === "pictures" && selectedFile.isImage === true) {
            settingsOpen = false;
            copyImageMetadata(selectedFile.path);
            return ;
        }
        openFile(selectedFile.path);
    }

    function moveSelection(delta) {
        if (files.length === 0)
            return ;

        selectedIdx = Math.max(0, Math.min(selectedIdx + delta, files.length - 1));
        filmstrip.positionViewAtIndex(selectedIdx, ListView.Contain);
    }

    title: "Quickshell Recent Files"
    color: "transparent"
    visible: showing
    implicitWidth: 980
    implicitHeight: 600
    minimumSize: Qt.size(720, 420)
    maximumSize: Qt.size(1200, 820)
    onShowingChanged: {
        if (showing) {
            root.settingsOpen = false;
            root.reload();
            focusTimer.start();
        }
    }

    Process {
        id: fileScanner

        property string scanMode: root.mode

        command: ["bash", "-lc", root.scanScript(fileScanner.scanMode)]
        running: false
        onExited: {
            const nextFiles = fileScanner.stdout.buf.slice();
            root.setCachedFiles(fileScanner.scanMode, nextFiles);
            if (fileScanner.scanMode === root.mode) {
                root.files = nextFiles;
                root.selectedIdx = 0;
            }
            fileScanner.stdout.buf = [];
        }

        stdout: SplitParser {
            property var buf: []

            onRead: (data) => {
                const line = data.trim();
                const file = root.fileFromScanLine(line);
                if (!file)
                    return ;

                buf.push(file);
            }
        }

    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: true
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_Escape) {
                root.showing = false;
                e.accepted = true;
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                root.activateSelected();
                e.accepted = true;
            } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down) {
                root.moveSelection(1);
                e.accepted = true;
            } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up) {
                root.moveSelection(-1);
                e.accepted = true;
            }
        }

        Rectangle {
            id: card

            anchors.fill: parent
            radius: 0
            color: theme.bg || "#1e1e2e"
            border.color: theme.dim || "#45475a"
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.overlayPx(14)
                spacing: root.overlayPx(10)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.overlayPx(26)
                    spacing: root.overlayPx(8)

                    Text {
                        text: root.activeProfile.icon
                        color: theme.accent || "#89b4fa"
                        font.pixelSize: Style.Typography.recentHeaderIcon
                        font.family: Style.Typography.mono
                    }

                    Text {
                        text: root.activeProfile.title
                        color: theme.fg || "#cdd6f4"
                        font.pixelSize: Style.Typography.recentTitle
                        font.family: Style.Typography.mono
                        font.weight: Font.Medium
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Row {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        spacing: root.overlayPx(2)

                        Rectangle {
                            width: root.overlayPx(20)
                            height: root.overlayPx(20)
                            radius: 0
                            color: root.settingsOpen ? Qt.alpha(theme.accent || "#89b4fa", 0.18) : "transparent"
                            border.width: root.settingsOpen ? 1 : 0
                            border.color: Qt.alpha(theme.accent || "#89b4fa", 0.45)

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: root.settingsOpen ? (theme.accent || "#89b4fa") : recentSettingsHover.containsMouse ? (theme.accent || "#89b4fa") : Qt.alpha(theme.muted || "#585b70", 0.75)
                                font.pixelSize: Style.Typography.recentActionIcon
                                font.family: Style.Typography.mono
                            }

                            MouseArea {
                                id: recentSettingsHover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.settingsOpen = !root.settingsOpen
                            }

                        }

                        Rectangle {
                            width: root.overlayPx(20)
                            height: root.overlayPx(20)
                            radius: 0
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: recentCloseHover.containsMouse ? (theme.red || "#f38ba8") : Qt.alpha(theme.muted || "#585b70", 0.7)
                                font.pixelSize: Style.Typography.recentCloseIcon
                                font.family: Style.Typography.mono
                            }

                            MouseArea {
                                id: recentCloseHover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showing = false
                            }

                        }
                    }

                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.files.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: fileScanner.running ? root.activeProfile.loadingText : root.activeProfile.emptyText
                        color: Qt.alpha(theme.muted || "#585b70", 0.6)
                        font.pixelSize: Style.Typography.recentBody
                        font.family: Style.Typography.mono
                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.files.length > 0
                    spacing: root.overlayPx(10)

                    Rectangle {
                        id: previewPane

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 0
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
                                    Drag.mimeData: root.dragMimeData(root.selectedFile.path)
                                    Drag.imageSource: root.selectedFile.source || ""
                                    Drag.imageSourceSize: Qt.size(220, 140)
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2
                                    Drag.active: selectedMouse.drag.active
                                    Drag.onDragFinished: {
                                        x = 0;
                                        y = 0;
                                        root.showing = false;
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 0
                                        color: theme.bg || "#1e1e2e"
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 1
                                            visible: root.selectedFile.isImage === true
                                            source: root.selectedFile.source || ""
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            cache: false
                                            smooth: true
                                        }

                                        Column {
                                            visible: root.selectedFile.isImage !== true
                                            anchors.centerIn: parent
                                            width: Math.min(parent.width - 48, 440)
                                            spacing: 12

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: root.fileIcon(root.selectedFile)
                                                color: theme.accent || "#89b4fa"
                                                font.pixelSize: Style.Typography.recentLargePreviewIcon
                                                font.family: Style.Typography.mono
                                            }

                                            Text {
                                                width: parent.width
                                                text: root.selectedFile.name || ""
                                                color: theme.fg || "#cdd6f4"
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideMiddle
                                                font.pixelSize: Style.Typography.recentTitle
                                                font.family: Style.Typography.mono
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                width: parent.width
                                                text: root.selectedFile.extension ? root.selectedFile.extension.toUpperCase() + " file" : "File"
                                                color: Qt.alpha(theme.muted || "#585b70", 0.72)
                                                horizontalAlignment: Text.AlignHCenter
                                                font.pixelSize: Style.Typography.recentBody
                                                font.family: Style.Typography.mono
                                            }

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
                                    onPressed: (mouse) => {
                                        root.prepareDragImage(selectedDragItem, 220, 140);
                                        mouse.accepted = true;
                                    }
                                    onReleased: {
                                        selectedDragItem.x = 0;
                                        selectedDragItem.y = 0;
                                    }
                                    onCanceled: {
                                        selectedDragItem.x = 0;
                                        selectedDragItem.y = 0;
                                    }
                                    onDoubleClicked: root.openFile(root.selectedFile.path)
                                }

                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: root.selectedFile.name || ""
                                    color: theme.fg || "#cdd6f4"
                                    font.pixelSize: Style.Typography.recentBody
                                    font.family: Style.Typography.mono
                                    elide: Text.ElideMiddle
                                }

                                Text {
                                    text: (root.selectedIdx + 1) + " / " + root.files.length
                                    color: Qt.alpha(theme.muted || "#585b70", 0.72)
                                    font.pixelSize: Style.Typography.recentBody
                                    font.family: Style.Typography.mono
                                }

                            }

                        }

                    }

                    Rectangle {
                        id: stripPane

                        Layout.preferredWidth: root.overlayPx(190)
                        Layout.fillHeight: true
                        radius: 0
                        color: Qt.alpha(theme.dim || "#45475a", 0.18)
                        border.width: 1
                        border.color: Qt.alpha(theme.dim || "#45475a", 0.55)
                        clip: true

                        ListView {
                            id: filmstrip

                            anchors.fill: parent
                            anchors.margins: root.overlayPx(6)
                            model: root.files
                            spacing: root.overlayPx(6)
                            clip: true

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                width: 2
                            }

                            delegate: Item {
                                id: delegateItem

                                property var fileData: root.files[index] || {
                                }
                                property bool selected: index === root.selectedIdx
                                property bool hovered: false

                                width: filmstrip.width
                                height: root.overlayPx(82)

                                Item {
                                    id: thumb

                                    x: 0
                                    y: 0
                                    width: parent.width
                                    height: parent.height
                                    Drag.dragType: Drag.Automatic
                                    Drag.supportedActions: Qt.CopyAction
                                    Drag.proposedAction: Qt.CopyAction
                                    Drag.mimeData: root.dragMimeData(delegateItem.fileData.path)
                                    Drag.imageSource: delegateItem.fileData.source || ""
                                    Drag.imageSourceSize: Qt.size(160, 90)
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2
                                    Drag.active: thumbnailMouse.drag.active
                                    Drag.onDragFinished: {
                                        x = 0;
                                        y = 0;
                                        root.showing = false;
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 0
                                        color: selected ? Qt.alpha(theme.accent || "#89b4fa", 0.17) : Qt.alpha(theme.dim || "#45475a", hovered ? 0.34 : 0.22)
                                        border.width: selected ? 2 : 1
                                        border.color: selected ? (theme.accent || "#89b4fa") : Qt.alpha(theme.dim || "#45475a", 0.62)
                                        clip: true

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: root.overlayPx(5)
                                            spacing: root.overlayPx(6)

                                            Rectangle {
                                                Layout.preferredWidth: root.overlayPx(72)
                                                Layout.fillHeight: true
                                                radius: 0
                                                color: theme.bg || "#1e1e2e"
                                                clip: true

                                                Image {
                                                    anchors.fill: parent
                                                    visible: delegateItem.fileData.isImage === true
                                                    source: delegateItem.fileData.source || ""
                                                    fillMode: Image.PreserveAspectCrop
                                                    asynchronous: true
                                                    cache: false
                                                    smooth: true
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    visible: delegateItem.fileData.isImage !== true
                                                    text: root.fileIcon(delegateItem.fileData)
                                                    color: theme.accent || "#89b4fa"
                                                    font.pixelSize: Style.Typography.recentPreviewIcon
                                                    font.family: Style.Typography.mono
                                                }

                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                spacing: root.overlayPx(2)

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: delegateItem.fileData.name || ""
                                                    color: selected ? (theme.accent || "#89b4fa") : (theme.fg || "#cdd6f4")
                                                    font.pixelSize: Style.Typography.recentBody
                                                    font.family: Style.Typography.mono
                                                    elide: Text.ElideMiddle
                                                    maximumLineCount: 2
                                                    wrapMode: Text.WrapAnywhere
                                                }

                                                Item {
                                                    Layout.fillHeight: true
                                                }

                                                Text {
                                                    text: "#" + (index + 1)
                                                    color: Qt.alpha(theme.muted || "#585b70", 0.62)
                                                    font.pixelSize: Style.Typography.recentMeta
                                                    font.family: Style.Typography.mono
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
                                    onPressed: (mouse) => {
                                        root.selectedIdx = index;
                                        root.prepareDragImage(thumb, 160, 90);
                                        mouse.accepted = true;
                                    }
                                    onReleased: {
                                        thumb.x = 0;
                                        thumb.y = 0;
                                    }
                                    onCanceled: {
                                        thumb.x = 0;
                                        thumb.y = 0;
                                    }
                                    onClicked: (mouse) => {
                                        root.selectedIdx = index;
                                        mouse.accepted = true;
                                    }
                                    onDoubleClicked: root.openFile(delegateItem.fileData.path)
                                }

                            }

                        }

                    }

                }

            }

            Rectangle {
                id: settingsPanel

                visible: root.settingsOpen
                z: 20
                width: root.overlayPx(236)
                height: root.overlayPx(86)
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: root.overlayPx(42)
                anchors.rightMargin: root.overlayPx(14)
                radius: 0
                color: theme.bg || "#1e1e2e"
                border.width: 1
                border.color: Qt.alpha(theme.accent || "#89b4fa", 0.42)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.overlayPx(12)
                    spacing: root.overlayPx(10)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.overlayPx(8)

                        Text {
                            Layout.fillWidth: true
                            text: root.activeProfile.settingLabel
                            color: theme.fg || "#cdd6f4"
                            font.pixelSize: Style.Typography.recentBody
                            font.family: Style.Typography.mono
                            font.weight: Font.Medium
                        }

                        Text {
                            text: root.fileLimit
                            color: theme.accent || "#89b4fa"
                            font.pixelSize: Style.Typography.recentSettingsValue
                            font.family: Style.Typography.mono
                            font.weight: Font.DemiBold
                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.overlayPx(8)

                        Repeater {
                            model: [{
                                "label": "-5",
                                "delta": -5
                            }, {
                                "label": "-1",
                                "delta": -1
                            }, {
                                "label": "+1",
                                "delta": 1
                            }, {
                                "label": "+5",
                                "delta": 5
                            }]

                            Rectangle {
                                Layout.fillWidth: true
                                height: root.overlayPx(32)
                                radius: 0
                                color: Qt.alpha(theme.dim || "#45475a", 0.34)
                                border.width: 1
                                border.color: Qt.alpha(theme.dim || "#45475a", 0.7)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: theme.fg || "#cdd6f4"
                                    font.pixelSize: Style.Typography.recentBody
                                    font.family: Style.Typography.mono
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setFileLimit(root.fileLimit + modelData.delta)
                                }

                            }

                        }

                    }

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
