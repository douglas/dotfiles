import "../style" as Style
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool showing: false
    property var theme: ({
    })
    property real uiScale: 1
    property real panelScale: Math.max(1, uiScale)
    property string selectedText: ""
    property string selectionSource: ""
    property var actions: []
    property var selectedAction: null
    property string instructionText: ""
    property string resultText: ""
    property string errorText: ""
    property string statusText: ""
    property bool loadingCapture: false
    property bool loadingRun: false
    property bool metaHeld: false
    property real dragStartCardX: 0
    property real dragStartCardY: 0
    property real cardX: 0
    property real cardY: 0
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string helperPath: homeDir + "/.config/quickshell/scripts/neosh-text-actions"
    readonly property bool needsInstruction: selectedAction && selectedAction.requiresInstruction === true
    readonly property bool hasSelection: selectedText.trim().length > 0
    readonly property bool hasResult: resultText.trim().length > 0

    function t(key, fallback) {
        return theme[key] || fallback;
    }

    function clamp(value, low, high) {
        return Math.max(low, Math.min(high, value));
    }

    function placeNearCursor(cursor) {
        const widthPx = card.width * panelScale;
        const heightPx = card.height * panelScale;
        const targetX = cursor && typeof cursor.x === "number" ? cursor.x + 18 : (root.width - widthPx) / 2;
        const targetY = cursor && typeof cursor.y === "number" ? cursor.y + 18 : (root.height - heightPx) / 2;
        cardX = Math.round(clamp(targetX, 16, Math.max(16, root.width - widthPx - 16)));
        cardY = Math.round(clamp(targetY, 16, Math.max(16, root.height - heightPx - 16)));
    }

    function isMetaKey(event) {
        return event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R;
    }

    function beginDrag() {
        dragStartCardX = cardX;
        dragStartCardY = cardY;
    }

    function updateDrag(translation) {
        const widthPx = card.width * panelScale;
        const heightPx = card.height * panelScale;
        cardX = Math.round(clamp(dragStartCardX + translation.x / panelScale, 16, Math.max(16, root.width - widthPx - 16)));
        cardY = Math.round(clamp(dragStartCardY + translation.y / panelScale, 16, Math.max(16, root.height - heightPx - 16)));
    }

    function endDrag() {
    }

    function open() {
        showing = true;
        selectedText = "";
        selectionSource = "";
        selectedAction = null;
        instructionText = "";
        resultText = "";
        errorText = "";
        statusText = "Capturing selection...";
        loadingCapture = true;
        loadingRun = false;
        actionsProc.stdout.buf = "";
        captureProc.stdout.buf = "";
        actionsProc.running = false;
        captureProc.running = false;
        actionsProc.running = true;
        captureProc.running = true;
        focusTimer.start();
    }

    function actionById(id) {
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].id === id)
                return actions[i];

        }
        return null;
    }

    function chooseAction(action) {
        if (!action)
            return ;

        selectedAction = action;
        errorText = "";
        resultText = "";
        if (action.requiresInstruction === true) {
            instructionText = "";
            Qt.callLater(function() {
                instructionInput.forceActiveFocus();
            });
            return ;
        }
        runSelected();
    }

    function runSelected() {
        if (!selectedAction || !hasSelection)
            return ;

        if (needsInstruction && instructionText.trim().length === 0) {
            errorText = selectedAction.placeholder || "Add an instruction for this action.";
            instructionInput.forceActiveFocus();
            return ;
        }
        loadingRun = true;
        resultText = "";
        errorText = "";
        statusText = "Running " + (selectedAction.label || selectedAction.id) + " with Codex...";
        runProc.stdout.buf = "";
        runProc.command = [helperPath, "run-action", selectedAction.id || "", instructionText];
        runProc.running = false;
        runProc.running = true;
    }

    function parseJson(raw, fallback) {
        try {
            return JSON.parse(raw || "{}");
        } catch (e) {
            return fallback;
        }
    }

    function copyResult() {
        copyProc.running = false;
        copyProc.running = true;
    }

    function pasteResult() {
        pasteProc.running = false;
        pasteProc.running = true;
        showing = false;
    }

    color: "transparent"
    exclusiveZone: 0
    visible: showing
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    onShowingChanged: {
        if (showing)
            focusTimer.start();

    }

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    Timer {
        id: focusTimer

        interval: 50
        onTriggered: focusScope.forceActiveFocus()
    }

    Process {
        id: actionsProc

        command: [root.helperPath, "actions"]
        running: false
        onExited: {
            const parsed = root.parseJson(actionsProc.stdout.buf, {
                "ok": false,
                "actions": []
            });
            root.actions = parsed.actions || [];
            actionsProc.stdout.buf = "";
        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                buf += data + "\n";
            }
        }

    }

    Process {
        id: captureProc

        command: [root.helperPath, "capture"]
        running: false
        onExited: {
            root.loadingCapture = false;
            const parsed = root.parseJson(captureProc.stdout.buf, {
                "ok": false,
                "text": "",
                "cursor": null
            });
            root.selectedText = parsed.text || "";
            root.selectionSource = parsed.source || "";
            root.placeNearCursor(parsed.cursor);
            root.statusText = root.hasSelection ? "Select an action" : "No selected text found";
            if (!root.hasSelection)
                root.errorText = "Select text in any app, then press the shortcut again.";

            captureProc.stdout.buf = "";
        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                buf += data + "\n";
            }
        }

    }

    Process {
        id: runProc

        command: [root.helperPath, "run-action", "improve", ""]
        running: false
        onExited: {
            root.loadingRun = false;
            const parsed = root.parseJson(runProc.stdout.buf, {
                "ok": false,
                "error": "Text action failed."
            });
            if (parsed.ok === true) {
                root.resultText = parsed.text || "";
                root.errorText = "";
                root.statusText = "Result ready";
            } else {
                root.resultText = "";
                root.errorText = parsed.error || "Text action failed.";
                root.statusText = "Action failed";
            }
            runProc.stdout.buf = "";
        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                buf += data + "\n";
            }
        }

    }

    Process {
        id: copyProc

        command: [root.helperPath, "copy-last"]
        running: false
        onExited: root.statusText = "Copied"
    }

    Process {
        id: pasteProc

        command: [root.helperPath, "paste-last"]
        running: false
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                if (root.instructionText.length > 0 && root.needsInstruction)
                    root.instructionText = "";
                else
                    root.showing = false;
                event.accepted = true;
            } else if (root.isMetaKey(event)) {
                root.metaHeld = true;
                event.accepted = true;
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.needsInstruction) {
                root.runSelected();
                event.accepted = true;
            } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                const idx = event.key - Qt.Key_1;
                if (idx < root.actions.length)
                    root.chooseAction(root.actions[idx]);

                event.accepted = true;
            }
        }
        Keys.onReleased: (event) => {
            if (root.isMetaKey(event)) {
                root.metaHeld = false;
                root.endDrag();
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.showing = false
        }

        Rectangle {
            id: card

            width: 620
            height: root.hasResult ? 520 : 430
            x: root.cardX
            y: root.cardY
            transformOrigin: Item.TopLeft
            scale: root.panelScale
            radius: 14
            color: Qt.darker(root.t("bg", "#1e1e2e"), 1.04)
            border.color: Qt.alpha(root.t("accent", "#89b4fa"), 0.24)
            border.width: 1
            clip: true
            opacity: root.showing ? 1 : 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "󰚩"
                        color: root.t("accent", "#89b4fa")
                        font.pixelSize: Style.Typography.headerIcon
                        font.family: Style.Typography.mono
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Text Actions"
                            color: root.t("fg", "#cdd6f4")
                            font.pixelSize: Style.Typography.componentTitle
                            font.family: Style.Typography.monoPropo
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.statusText
                            color: Qt.alpha(root.t("muted", "#585b70"), 0.78)
                            font.pixelSize: Style.Typography.componentMeta
                            font.family: Style.Typography.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                    }

                    Rectangle {
                        width: closeText.implicitWidth + 14
                        height: 26
                        radius: 8
                        color: Qt.alpha(root.t("dim", "#45475a"), 0.28)
                        border.color: Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                        border.width: 1

                        Text {
                            id: closeText

                            anchors.centerIn: parent
                            text: "✕"
                            color: Qt.alpha(root.t("fg", "#cdd6f4"), 0.78)
                            font.pixelSize: Style.Typography.closeIcon
                            font.family: Style.Typography.mono
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showing = false
                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 86
                    radius: 10
                    color: Qt.alpha(root.t("dim", "#45475a"), 0.2)
                    border.color: Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                    border.width: 1
                    clip: true

                    Text {
                        anchors.fill: parent
                        anchors.margins: 10
                        text: root.loadingCapture ? "Capturing selected text..." : (root.selectedText || "No selected text")
                        color: root.hasSelection ? root.t("fg", "#cdd6f4") : Qt.alpha(root.t("muted", "#585b70"), 0.68)
                        font.pixelSize: Style.Typography.componentBody
                        font.family: Style.Typography.text
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 4
                    }

                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 7
                    columnSpacing: 7
                    visible: !root.loadingCapture && root.hasSelection

                    Repeater {
                        model: root.actions

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: 9
                            color: root.selectedAction && root.selectedAction.id === modelData.id ? Qt.alpha(root.t("accent", "#89b4fa"), 0.2) : Qt.alpha(root.t("dim", "#45475a"), 0.22)
                            border.color: root.selectedAction && root.selectedAction.id === modelData.id ? Qt.alpha(root.t("accent", "#89b4fa"), 0.6) : Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: modelData.icon || "󰘦"
                                    color: root.t("accent", "#89b4fa")
                                    font.pixelSize: Style.Typography.listIcon
                                    font.family: Style.Typography.mono
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (index + 1) + " " + (modelData.label || modelData.id)
                                    color: root.t("fg", "#cdd6f4")
                                    font.pixelSize: Style.Typography.componentSubtitle
                                    font.family: Style.Typography.monoPropo
                                    elide: Text.ElideRight
                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.chooseAction(modelData)
                            }

                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.needsInstruction ? 42 : 0
                    visible: root.needsInstruction
                    radius: 9
                    color: Qt.alpha(root.t("dim", "#45475a"), 0.28)
                    border.color: Qt.alpha(root.t("accent", "#89b4fa"), 0.32)
                    border.width: 1
                    clip: true

                    TextInput {
                        id: instructionInput

                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.instructionText
                        color: root.t("fg", "#cdd6f4")
                        selectedTextColor: root.t("bg", "#1e1e2e")
                        selectionColor: root.t("accent", "#89b4fa")
                        font.pixelSize: Style.Typography.componentSubtitle
                        font.family: Style.Typography.text
                        clip: true
                        onTextChanged: root.instructionText = text
                        Keys.onReturnPressed: root.runSelected()
                        Keys.onEnterPressed: root.runSelected()

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: instructionInput.text.length === 0
                            text: root.selectedAction ? (root.selectedAction.placeholder || "Instruction") : "Instruction"
                            color: Qt.alpha(root.t("muted", "#585b70"), 0.56)
                            font.pixelSize: Style.Typography.componentSubtitle
                            font.family: Style.Typography.text
                        }

                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.needsInstruction
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: runText.implicitWidth + 22
                        height: 30
                        radius: 9
                        color: Qt.alpha(root.t("accent", "#89b4fa"), 0.22)
                        border.color: Qt.alpha(root.t("accent", "#89b4fa"), 0.55)
                        border.width: 1

                        Text {
                            id: runText

                            anchors.centerIn: parent
                            text: root.loadingRun ? "Running..." : "Run"
                            color: root.t("fg", "#cdd6f4")
                            font.pixelSize: Style.Typography.componentSubtitle
                            font.family: Style.Typography.monoPropo
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.runSelected()
                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.hasResult || root.errorText.length > 0 || root.loadingRun
                    radius: 10
                    color: Qt.alpha(root.t("dim", "#45475a"), 0.18)
                    border.color: root.errorText.length > 0 ? Qt.alpha(root.t("red", "#f38ba8"), 0.42) : Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                    border.width: 1
                    clip: true

                    TextArea {
                        anchors.fill: parent
                        anchors.margins: 9
                        readOnly: true
                        wrapMode: TextArea.Wrap
                        text: root.loadingRun ? "Waiting for Codex..." : (root.errorText.length > 0 ? root.errorText : root.resultText)
                        color: root.errorText.length > 0 ? root.t("red", "#f38ba8") : root.t("fg", "#cdd6f4")
                        selectedTextColor: root.t("bg", "#1e1e2e")
                        selectionColor: root.t("accent", "#89b4fa")
                        font.pixelSize: Style.Typography.componentBody
                        font.family: Style.Typography.text

                        background: Item {
                        }

                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.hasResult
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: [{
                            "label": "Again",
                            "action": "again"
                        }, {
                            "label": "Copy",
                            "action": "copy"
                        }, {
                            "label": "Replace",
                            "action": "replace"
                        }]

                        Rectangle {
                            width: actionText.implicitWidth + 20
                            height: 30
                            radius: 9
                            color: modelData.action === "replace" ? Qt.alpha(root.t("accent", "#89b4fa"), 0.22) : Qt.alpha(root.t("dim", "#45475a"), 0.24)
                            border.color: modelData.action === "replace" ? Qt.alpha(root.t("accent", "#89b4fa"), 0.54) : Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                            border.width: 1

                            Text {
                                id: actionText

                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.t("fg", "#cdd6f4")
                                font.pixelSize: Style.Typography.componentSubtitle
                                font.family: Style.Typography.monoPropo
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.action === "again")
                                        root.runSelected();
                                    else if (modelData.action === "copy")
                                        root.copyResult();
                                    else
                                        root.pasteResult();
                                }
                            }

                        }

                    }

                }

            }

            Item {
                id: dragSurface

                x: 10
                y: 8
                width: Math.max(1, parent.width - 76)
                height: 54
                z: 20

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.SizeAllCursor
                }

                DragHandler {
                    id: cardDrag

                    target: null
                    onActiveChanged: {
                        if (active)
                            root.beginDrag();
                        else
                            root.endDrag();
                    }
                    onTranslationChanged: {
                        if (active)
                            root.updateDrag(translation);

                    }
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on height {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

}
