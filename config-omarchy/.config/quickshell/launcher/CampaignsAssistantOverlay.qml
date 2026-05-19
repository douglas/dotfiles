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
    property string questionText: ""
    property string transcriptText: ""
    property string statusText: ""
    property string errorText: ""
    property bool loadingCapture: false
    property bool loadingAsk: false
    property real dragStartCardX: 0
    property real dragStartCardY: 0
    property real cardX: 0
    property real cardY: 0
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string helperPath: homeDir + "/.config/quickshell/scripts/neosh-campaigns-assistant"
    readonly property bool hasSelection: selectedText.trim().length > 0

    function t(key, fallback) {
        return theme[key] || fallback;
    }

    function clamp(value, low, high) {
        return Math.max(low, Math.min(high, value));
    }

    function placeCentered() {
        const widthPx = card.width * panelScale;
        const heightPx = card.height * panelScale;
        cardX = Math.round(clamp((root.width - widthPx) / 2, 16, Math.max(16, root.width - widthPx - 16)));
        cardY = Math.round(clamp((root.height - heightPx) / 2, 16, Math.max(16, root.height - heightPx - 16)));
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

    function parseJson(raw, fallback) {
        try {
            return JSON.parse(raw || "{}");
        } catch (e) {
            return fallback;
        }
    }

    function historyToText(messages) {
        if (!messages || messages.length === 0)
            return "Ask about a Slack thread, code snippet, domain concept, or coworker question.";

        let parts = [];
        for (let i = 0; i < messages.length; i++) {
            const msg = messages[i] || {
            };
            const label = msg.role === "assistant" ? "Campaigns Assistant" : "You";
            parts.push(label + ":\n" + (msg.text || "").trim());
        }
        return parts.join("\n\n");
    }

    function open() {
        showing = true;
        errorText = "";
        statusText = "Capturing selected context...";
        loadingCapture = true;
        loadingAsk = false;
        if (cardX === 0 && cardY === 0)
            placeCentered();

        captureProc.stdout.buf = "";
        historyProc.stdout.buf = "";
        captureProc.running = false;
        historyProc.running = false;
        captureProc.running = true;
        historyProc.running = true;
        focusTimer.start();
    }

    function recapture() {
        selectedText = "";
        errorText = "";
        statusText = "Capturing selected context...";
        loadingCapture = true;
        captureProc.stdout.buf = "";
        captureProc.running = false;
        captureProc.running = true;
    }

    function sendQuestion() {
        const question = questionText.trim();
        if (question.length === 0) {
            errorText = "Ask a question first.";
            questionInput.forceActiveFocus();
            return ;
        }
        loadingAsk = true;
        errorText = "";
        statusText = "Asking Codex with Campaigns context...";
        askProc.stdout.buf = "";
        askProc.command = [helperPath, "ask", question];
        askProc.running = false;
        askProc.running = true;
    }

    function usePrompt(text) {
        questionText = text;
        questionInput.forceActiveFocus();
    }

    function copyLast() {
        copyProc.running = false;
        copyProc.running = true;
    }

    function clearChat() {
        clearProc.stdout.buf = "";
        clearProc.running = false;
        clearProc.running = true;
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
        onTriggered: questionInput.forceActiveFocus()
    }

    Process {
        id: captureProc

        command: [root.helperPath, "capture"]
        running: false
        onExited: {
            root.loadingCapture = false;
            const parsed = root.parseJson(captureProc.stdout.buf, {
                "ok": false,
                "text": ""
            });
            root.selectedText = parsed.text || "";
            root.statusText = root.hasSelection ? "Selection captured" : "No selection captured";
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
        id: historyProc

        command: [root.helperPath, "history"]
        running: false
        onExited: {
            const parsed = root.parseJson(historyProc.stdout.buf, {
                "ok": true,
                "messages": []
            });
            root.transcriptText = root.historyToText(parsed.messages || []);
            historyProc.stdout.buf = "";
        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                buf += data + "\n";
            }
        }

    }

    Process {
        id: askProc

        command: [root.helperPath, "ask", ""]
        running: false
        onExited: {
            root.loadingAsk = false;
            const parsed = root.parseJson(askProc.stdout.buf, {
                "ok": false,
                "error": "Campaigns assistant failed."
            });
            if (parsed.ok === true) {
                root.questionText = "";
                root.errorText = "";
                root.statusText = "Answer ready";
                root.transcriptText = root.historyToText(parsed.messages || []);
            } else {
                root.errorText = parsed.error || "Campaigns assistant failed.";
                root.statusText = "Ask failed";
                if (parsed.messages)
                    root.transcriptText = root.historyToText(parsed.messages);

            }
            askProc.stdout.buf = "";
        }

        stdout: SplitParser {
            property string buf: ""

            onRead: (data) => {
                buf += data + "\n";
            }
        }

    }

    Process {
        id: clearProc

        command: [root.helperPath, "clear"]
        running: false
        onExited: {
            const parsed = root.parseJson(clearProc.stdout.buf, {
                "messages": []
            });
            root.transcriptText = root.historyToText(parsed.messages || []);
            root.errorText = "";
            root.statusText = "Chat cleared";
            clearProc.stdout.buf = "";
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
        onExited: root.statusText = "Copied last answer"
    }

    FocusScope {
        id: focusScope

        anchors.fill: parent
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.showing = false;
                event.accepted = true;
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                root.sendQuestion();
                event.accepted = true;
            }
        }

        Rectangle {
            id: card

            width: 780
            height: 660
            x: root.cardX
            y: root.cardY
            transformOrigin: Item.TopLeft
            scale: root.panelScale
            radius: 14
            color: Qt.darker(root.t("bg", "#1e1e2e"), 1.04)
            border.color: Qt.alpha(root.t("accent", "#89b4fa"), 0.24)
            border.width: 1
            clip: true

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
                            text: "Campaigns Assistant"
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
                    Layout.preferredHeight: 84
                    radius: 10
                    color: Qt.alpha(root.t("dim", "#45475a"), 0.18)
                    border.color: Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                    border.width: 1
                    clip: true

                    Text {
                        anchors.fill: parent
                        anchors.margins: 10
                        text: root.loadingCapture ? "Capturing selected Slack or code context..." : (root.selectedText || "No selected context. Ask a Campaigns question directly or select Slack/code text and recapture.")
                        color: root.hasSelection ? root.t("fg", "#cdd6f4") : Qt.alpha(root.t("muted", "#585b70"), 0.72)
                        font.pixelSize: Style.Typography.componentBody
                        font.family: Style.Typography.text
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 4
                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    Repeater {
                        model: [{
                            "label": "Summarize Slack",
                            "prompt": "Summarize the selected Slack thread, explain the missing Campaigns context, and suggest the likely next reply."
                        }, {
                            "label": "Explain Code",
                            "prompt": "Explain the selected Campaigns code path, domain concepts, and related files."
                        }, {
                            "label": "Answer",
                            "prompt": "Answer this question using Campaigns source code ~/work/campaigns and use Glean and Slack MCP servers to gather company context as needed."
                        }]

                        Rectangle {
                            width: quickText.implicitWidth + 18
                            height: 30
                            radius: 9
                            color: Qt.alpha(root.t("dim", "#45475a"), 0.24)
                            border.color: Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                            border.width: 1

                            Text {
                                id: quickText

                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.t("fg", "#cdd6f4")
                                font.pixelSize: Style.Typography.componentSubtitle
                                font.family: Style.Typography.monoPropo
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.usePrompt(modelData.prompt)
                            }

                        }

                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: recaptureText.implicitWidth + 18
                        height: 30
                        radius: 9
                        color: Qt.alpha(root.t("dim", "#45475a"), 0.24)
                        border.color: Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                        border.width: 1

                        Text {
                            id: recaptureText

                            anchors.centerIn: parent
                            text: "Recapture"
                            color: root.t("fg", "#cdd6f4")
                            font.pixelSize: Style.Typography.componentSubtitle
                            font.family: Style.Typography.monoPropo
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.recapture()
                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: Qt.alpha(root.t("dim", "#45475a"), 0.16)
                    border.color: root.errorText.length > 0 ? Qt.alpha(root.t("red", "#f38ba8"), 0.42) : Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                    border.width: 1
                    clip: true

                    TextArea {
                        anchors.fill: parent
                        anchors.margins: 9
                        readOnly: true
                        wrapMode: TextArea.Wrap
                        text: root.errorText.length > 0 ? root.errorText + "\n\n" + root.transcriptText : root.transcriptText
                        color: root.errorText.length > 0 ? root.t("red", "#f38ba8") : root.t("fg", "#cdd6f4")
                        selectedTextColor: root.t("bg", "#1e1e2e")
                        selectionColor: root.t("accent", "#89b4fa")
                        font.pixelSize: Style.Typography.componentBody
                        font.family: Style.Typography.text

                        background: Item {
                        }

                    }

                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 82
                    radius: 10
                    color: Qt.alpha(root.t("dim", "#45475a"), 0.24)
                    border.color: Qt.alpha(root.t("accent", "#89b4fa"), 0.28)
                    border.width: 1
                    clip: true

                    TextArea {
                        id: questionInput

                        anchors.fill: parent
                        anchors.margins: 9
                        text: root.questionText
                        color: root.t("fg", "#cdd6f4")
                        selectedTextColor: root.t("bg", "#1e1e2e")
                        selectionColor: root.t("accent", "#89b4fa")
                        font.pixelSize: Style.Typography.componentBody
                        font.family: Style.Typography.text
                        wrapMode: TextArea.Wrap
                        onTextChanged: root.questionText = text
                        Keys.onPressed: (event) => {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                                root.sendQuestion();
                                event.accepted = true;
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            visible: questionInput.text.length === 0
                            text: "Ask about Campaigns, selected Slack text, or selected code..."
                            color: Qt.alpha(root.t("muted", "#585b70"), 0.56)
                            font.pixelSize: Style.Typography.componentBody
                            font.family: Style.Typography.text
                        }

                        background: Item {
                        }

                    }

                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Ctrl+Enter sends. The assistant runs read-only in ~/work/campaigns."
                        color: Qt.alpha(root.t("muted", "#585b70"), 0.72)
                        font.pixelSize: Style.Typography.componentMeta
                        font.family: Style.Typography.text
                        elide: Text.ElideRight
                    }

                    Repeater {
                        model: [{
                            "label": "Clear",
                            "action": "clear"
                        }, {
                            "label": "Copy",
                            "action": "copy"
                        }, {
                            "label": "Send",
                            "action": "send"
                        }]

                        Rectangle {
                            width: footerText.implicitWidth + 22
                            height: 32
                            radius: 9
                            color: modelData.action === "send" ? Qt.alpha(root.t("accent", "#89b4fa"), 0.22) : Qt.alpha(root.t("dim", "#45475a"), 0.24)
                            border.color: modelData.action === "send" ? Qt.alpha(root.t("accent", "#89b4fa"), 0.55) : Qt.alpha(root.t("fg", "#cdd6f4"), 0.08)
                            border.width: 1

                            Text {
                                id: footerText

                                anchors.centerIn: parent
                                text: modelData.action === "send" && root.loadingAsk ? "Asking..." : modelData.label
                                color: root.t("fg", "#cdd6f4")
                                font.pixelSize: Style.Typography.componentSubtitle
                                font.family: Style.Typography.monoPropo
                                font.weight: modelData.action === "send" ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.action === "send")
                                        root.sendQuestion();
                                    else if (modelData.action === "copy")
                                        root.copyLast();
                                    else
                                        root.clearChat();
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
                    target: null
                    onActiveChanged: {
                        if (active)
                            root.beginDrag();

                    }
                    onTranslationChanged: {
                        if (active)
                            root.updateDrag(translation);

                    }
                }

            }

        }

    }

}
