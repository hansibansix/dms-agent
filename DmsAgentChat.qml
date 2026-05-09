import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import "markdown2html.js" as Md

Item {
    id: chatRoot

    signal escapePressed()

    function copyCodeBlock(rawMarkdown, index) {
        const code = Md.extractCodeBlock(rawMarkdown, index);
        if (!code) return;
        Quickshell.execDetached(["wl-copy", code]);
        if (typeof ToastService !== "undefined" && ToastService.showInfo)
            ToastService.showInfo("Copied", "Code copied to clipboard");
    }

    // --- Input Card (anchored to bottom) ---
    Rectangle {
        id: inputCard
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: inputCol.height
        radius: 20; color: Theme.surfaceContainer
        border.width: 1; border.color: Theme.outlineVariant
        z: 10

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowBlur: 0.8
            shadowVerticalOffset: -2; shadowColor: Theme.withAlpha(Theme.shadow || "#000000", 0.4)
        }

        ColumnLayout {
            id: inputCol; width: parent.width; spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(44, inputField.contentHeight + 24)

                TextEdit {
                    id: inputField
                    anchors.fill: parent
                    anchors.leftMargin: 18; anchors.rightMargin: 18
                    anchors.topMargin: 12; anchors.bottomMargin: 12
                    color: Theme.surfaceText; font.pixelSize: 14
                    wrapMode: TextEdit.Wrap; clip: true

                    Text {
                        visible: !inputField.text && !inputField.activeFocus
                        text: "Message..."
                        color: Theme.surfaceVariantText; font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Keys.onPressed: function(event) {
                        // 1) Dropdown navigation takes priority.
                        if (modelDropdown.visible) {
                            const n = modelDropdown.itemCount;
                            if (event.key === Qt.Key_Up)   { modelDropdown.currentIndex = (modelDropdown.currentIndex - 1 + n) % n; event.accepted = true; return; }
                            if (event.key === Qt.Key_Down) { modelDropdown.currentIndex = (modelDropdown.currentIndex + 1) % n;     event.accepted = true; return; }
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { modelDropdown.applySelection(); event.accepted = true; return; }
                            if (event.key === Qt.Key_Escape) { modelDropdown.visible = false; event.accepted = true; return; }
                        }
                        if (historyDropdown.visible) {
                            const m = historyList.count;
                            if (m > 0) {
                                if (event.key === Qt.Key_Up)   { historyList.currentIndex = (historyList.currentIndex - 1 + m) % m; historyList.positionViewAtIndex(historyList.currentIndex, ListView.Contain); event.accepted = true; return; }
                                if (event.key === Qt.Key_Down) { historyList.currentIndex = (historyList.currentIndex + 1) % m;     historyList.positionViewAtIndex(historyList.currentIndex, ListView.Contain); event.accepted = true; return; }
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { historyDropdown.applySelection(); event.accepted = true; return; }
                            }
                            if (event.key === Qt.Key_Escape) { historyDropdown.visible = false; event.accepted = true; return; }
                        }
                        // 2) Ctrl shortcuts.
                        if (event.modifiers & Qt.ControlModifier) {
                            switch (event.key) {
                            case Qt.Key_N: AgentService.clearMessages(); messageModel.clear(); event.accepted = true; return;
                            case Qt.Key_R: historyDropdown.toggle(); event.accepted = true; return;
                            case Qt.Key_M: modelDropdown.toggle();   event.accepted = true; return;
                            case Qt.Key_T: AgentService.extendedThinking = !AgentService.extendedThinking; event.accepted = true; return;
                            }
                        }
                        // 3) Send / newline on Enter.
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                event.accepted = false; // let TextEdit insert newline
                            } else {
                                sendCurrentMessage();
                                event.accepted = true;
                            }
                            return;
                        }
                        // 4) Esc cascade (cancel busy → close panel).
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            if (AgentService.busy) { AgentService.cancelRequest(); return; }
                            chatRoot.escapePressed();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.leftMargin: 14; Layout.rightMargin: 14
                height: 1; color: Theme.withAlpha(Theme.outlineVariant, 0.3)
            }

            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 40

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 4

                    // Model dropdown
                    Rectangle {
                        width: modelRow.implicitWidth + 16; height: 26; radius: 13
                        color: modelDropArea.containsMouse || modelDropdown.visible ? Theme.withAlpha(Theme.surfaceVariant, 0.3) : "transparent"

                        Row {
                            id: modelRow; anchors.centerIn: parent; spacing: 4
                            Text { text: AgentService.claudeModel; font.pixelSize: 11; color: Theme.surfaceVariantText; anchors.verticalCenter: parent.verticalCenter }
                            DankIcon { name: modelDropdown.visible ? "expand_less" : "expand_more"; color: Theme.surfaceVariantText; size: 14; anchors.verticalCenter: parent.verticalCenter }
                        }

                        MouseArea { id: modelDropArea; anchors.fill: parent; hoverEnabled: true; onClicked: modelDropdown.toggle() }
                    }

                    // Think
                    Rectangle {
                        width: thinkRow.implicitWidth + 14; height: 26; radius: 13
                        color: AgentService.extendedThinking ? Theme.withAlpha(Theme.primary, 0.15) : (thinkArea.containsMouse ? Theme.withAlpha(Theme.surfaceVariant, 0.3) : "transparent")
                        Row {
                            id: thinkRow; anchors.centerIn: parent; spacing: 4
                            DankIcon { name: "psychology"; color: AgentService.extendedThinking ? Theme.primary : Theme.surfaceVariantText; size: 14; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Think"; font.pixelSize: 11; color: AgentService.extendedThinking ? Theme.primary : Theme.surfaceVariantText; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: thinkArea; anchors.fill: parent; hoverEnabled: true; onClicked: AgentService.extendedThinking = !AgentService.extendedThinking }
                    }

                    // New chat
                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: newChatArea.containsMouse ? Theme.withAlpha(Theme.surfaceVariant, 0.3) : "transparent"
                        DankIcon { anchors.centerIn: parent; name: "add"; color: Theme.surfaceVariantText; size: 16 }
                        MouseArea { id: newChatArea; anchors.fill: parent; hoverEnabled: true; onClicked: { AgentService.clearMessages(); messageModel.clear(); } }
                    }

                    // History
                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: historyArea.containsMouse || historyDropdown.visible ? Theme.withAlpha(Theme.surfaceVariant, 0.3) : "transparent"
                        DankIcon { anchors.centerIn: parent; name: "history"; color: Theme.surfaceVariantText; size: 16 }
                        MouseArea { id: historyArea; anchors.fill: parent; hoverEnabled: true; onClicked: historyDropdown.toggle() }
                    }

                    Item { Layout.fillWidth: true }

                    // Cost
                    Text {
                        visible: AgentService.lastCost !== ""; text: AgentService.lastCost
                        font.pixelSize: 9; color: Theme.withAlpha(Theme.surfaceVariantText, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Send / Status
                    Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: AgentService.busy

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            anchors.verticalCenter: parent.verticalCenter; color: Theme.primary
                            SequentialAnimation on opacity {
                                running: AgentService.busy; loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            text: AgentService.statusText
                            color: Theme.surfaceVariantText; font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 22; height: 22; radius: 11
                            anchors.verticalCenter: parent.verticalCenter
                            color: cancelArea.containsMouse ? Theme.withAlpha(Theme.error || "#EF4444", 0.15) : "transparent"
                            DankIcon { anchors.centerIn: parent; name: "close"; color: Theme.surfaceVariantText; size: 14 }
                            MouseArea { id: cancelArea; anchors.fill: parent; hoverEnabled: true; onClicked: AgentService.cancelRequest() }
                        }
                    }

                    Rectangle {
                        visible: !AgentService.busy
                        width: 32; height: 32; radius: 16
                        color: canSend ? Theme.primary : Theme.withAlpha(Theme.surfaceVariant, 0.2)
                        property bool canSend: inputField.text.trim().length > 0
                        DankIcon { anchors.centerIn: parent; name: "arrow_upward"; color: parent.canSend ? Theme.primaryText : Theme.surfaceVariantText; size: 18 }
                        MouseArea { anchors.fill: parent; onClicked: if (parent.canSend) sendCurrentMessage() }
                    }
                }
            }
        }
    }

    // --- Model Dropdown (outside input card, z on top) ---
    Rectangle {
        id: modelDropdown; visible: false
        anchors.bottom: inputCard.top; anchors.bottomMargin: 6
        anchors.left: inputCard.left; anchors.leftMargin: 8
        width: 130; height: modelCol.height + 8; radius: 12
        color: Theme.surfaceContainerHighest; border.width: 1; border.color: Theme.outlineVariant
        z: 20

        readonly property var models: [
            { id: "haiku",  label: "Haiku",  desc: "Fast" },
            { id: "sonnet", label: "Sonnet", desc: "Balanced" },
            { id: "opus",   label: "Opus",   desc: "Best" }
        ]
        readonly property int itemCount: models.length
        property int currentIndex: 0

        function toggle() {
            if (!visible) {
                const i = models.findIndex(m => m.id === AgentService.claudeModel);
                currentIndex = i >= 0 ? i : 0;
            }
            visible = !visible;
        }
        function applySelection() {
            if (currentIndex < 0 || currentIndex >= models.length) return;
            AgentService.claudeModel = models[currentIndex].id;
            visible = false;
        }

        Column {
            id: modelCol; anchors.top: parent.top; anchors.topMargin: 4
            anchors.left: parent.left; anchors.right: parent.right
            Repeater {
                model: modelDropdown.models
                Rectangle {
                    width: modelCol.width; height: 32; radius: 8
                    color: (optArea.containsMouse || index === modelDropdown.currentIndex) ? Theme.withAlpha(Theme.surfaceVariant, 0.4) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 6
                        Text { text: modelData.label; font.pixelSize: 12; font.weight: AgentService.claudeModel === modelData.id ? Font.Bold : Font.Normal; color: AgentService.claudeModel === modelData.id ? Theme.surfaceText : Theme.surfaceVariantText }
                        Text { text: modelData.desc; font.pixelSize: 10; color: Theme.withAlpha(Theme.surfaceVariantText, 0.5) }
                        Item { Layout.fillWidth: true }
                        DankIcon { visible: AgentService.claudeModel === modelData.id; name: "check"; color: Theme.primary; size: 14 }
                    }
                    MouseArea {
                        id: optArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: modelDropdown.currentIndex = index
                        onClicked: { modelDropdown.currentIndex = index; modelDropdown.applySelection(); }
                    }
                }
            }
        }
    }

    // --- History Dropdown (outside input card, z on top) ---
    function formatRelativeTime(timestamp) {
        if (!timestamp) return ""
        const diff = Date.now() - timestamp
        const sec = Math.floor(diff / 1000)
        if (sec < 60) return "just now"
        const min = Math.floor(sec / 60)
        if (min < 60) return min + "m ago"
        const hr = Math.floor(min / 60)
        if (hr < 24) return hr + "h ago"
        const day = Math.floor(hr / 24)
        if (day < 7) return day + "d ago"
        if (day < 30) return Math.floor(day / 7) + "w ago"
        return new Date(timestamp).toLocaleDateString(undefined, { month: "short", day: "numeric" })
    }

    Rectangle {
        id: historyDropdown
        visible: false
        anchors.bottom: inputCard.top; anchors.bottomMargin: 8
        anchors.left: parent.left; anchors.leftMargin: 8
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.top: parent.top; anchors.topMargin: 16
        radius: 16
        clip: true
        color: Theme.surfaceContainerHigh
        border.width: 1
        border.color: Theme.withAlpha(Theme.outlineVariant, 0.6)
        z: 20

        function toggle() {
            if (!visible) {
                AgentService.loadHistory();
                historyList.currentIndex = 0;
            }
            visible = !visible;
        }
        function applySelection() {
            const idx = historyList.currentIndex;
            if (idx < 0 || idx >= AgentService.history.length) return;
            messageModel.clear();
            AgentService.resumeSession(AgentService.history[idx].id);
            visible = false;
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            // Header
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    DankIcon {
                        name: "history"
                        color: Theme.surfaceVariantText
                        size: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Conversations"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    visible: AgentService.history.length > 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: AgentService.history.length + (AgentService.history.length === 1 ? " session" : " sessions")
                    font.pixelSize: 10
                    color: Theme.surfaceVariantText
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.withAlpha(Theme.outlineVariant, 0.4)
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: AgentService.history.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    DankIcon {
                        name: "forum"
                        size: 36
                        color: Theme.withAlpha(Theme.surfaceVariantText, 0.5)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "No conversations yet"
                        color: Theme.surfaceVariantText
                        font.pixelSize: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "Past chats will appear here"
                        color: Theme.withAlpha(Theme.surfaceVariantText, 0.6)
                        font.pixelSize: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // List
            ListView {
                id: historyList
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: AgentService.history.length > 0
                clip: true
                spacing: 2
                model: AgentService.history
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: histItem
                    width: historyList.width
                    height: 48
                    radius: 10
                    readonly property bool isActive: AgentService.sessionId === modelData.id
                    readonly property bool isFocused: index === historyList.currentIndex
                    color: isFocused
                        ? Theme.withAlpha(Theme.primary, 0.20)
                        : (hArea.containsMouse
                            ? Theme.withAlpha(Theme.surfaceVariant, 0.35)
                            : (isActive ? Theme.withAlpha(Theme.primary, 0.08) : "transparent"))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    // Left-edge focus indicator for keyboard navigation
                    Rectangle {
                        visible: histItem.isFocused
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: parent.height - 14
                        radius: 1.5
                        color: Theme.primary
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        DankIcon {
                            name: histItem.isActive ? "chat" : "chat_bubble_outline"
                            color: histItem.isActive ? Theme.primary : Theme.surfaceVariantText
                            size: 16
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: modelData.title || "Untitled"
                                font.pixelSize: 12
                                font.weight: histItem.isActive ? Font.Medium : Font.Normal
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                            }
                            Text {
                                text: formatRelativeTime(modelData.date)
                                font.pixelSize: 10
                                color: Theme.surfaceVariantText
                            }
                        }

                        DankIcon {
                            visible: histItem.isActive
                            name: "check_circle"
                            color: Theme.primary
                            size: 14
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: hArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: historyList.currentIndex = index
                        onClicked: {
                            historyList.currentIndex = index
                            messageModel.clear()
                            AgentService.resumeSession(modelData.id)
                            historyDropdown.visible = false
                        }
                    }
                }
            }
        }
    }


    // --- Messages container (fills space above input) ---
    Flickable {
        id: messageFlick
        anchors.top: parent.top
        anchors.bottom: inputCard.top
        anchors.topMargin: 16
        anchors.bottomMargin: 12
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: 8; anchors.rightMargin: 8
        clip: true
        contentHeight: messageColumn.height
        contentWidth: width

        // Auto-scroll to bottom
        function scrollToEnd() {
            if (contentHeight > height)
                contentY = contentHeight - height;
        }

        Column {
            id: messageColumn
            width: parent.width
            spacing: 10

            // Spacer pushes messages to bottom
            Item {
                width: 1
                height: Math.max(0, messageFlick.height - messagesContent.height)
            }

            // Actual messages
            Column {
                id: messagesContent
                width: parent.width
                spacing: 10

                Repeater {
                    model: ListModel { id: messageModel }

                    Loader {
                        width: messagesContent.width
                        sourceComponent: {
                            if (model.msgRole === "tool_status") return toolComp;
                            if (model.msgRole === "user") return userComp;
                            if (model.msgRole === "assistant") return assistantComp;
                            return null;
                        }
                        property string content: model.msgContent || ""
                    }
                }
            }
        }

        onContentHeightChanged: { Qt.callLater(scrollToEnd); }
    }

    // --- Bubbles (no shadows to avoid clipping artifacts) ---
    Component {
        id: toolComp
        Item {
            height: toolBubble.height
            Rectangle {
                id: toolBubble; anchors.left: parent.left
                width: Math.min(parent.width * 0.85, toolIcon.width + toolText.implicitWidth + 30)
                height: 28; radius: 14
                color: Theme.surface; border.width: 1; border.color: Theme.outlineVariant

                DankIcon {
                    id: toolIcon; name: "build"; color: "#FF9800"; size: 13
                    anchors.left: parent.left; anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: toolText; text: content; color: Theme.surfaceVariantText
                    font.pixelSize: 11; font.family: "monospace"
                    elide: Text.ElideRight
                    anchors.left: toolIcon.right; anchors.leftMargin: 6
                    anchors.right: parent.right; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component {
        id: userComp
        Item {
            height: uRect.height
            Rectangle {
                id: uRect; anchors.right: parent.right
                width: Math.min(parent.width * 0.8, uTxt.implicitWidth + 28)
                height: uTxt.implicitHeight + 20; radius: 16; color: Theme.primary
                Text {
                    id: uTxt
                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    text: content
                    wrapMode: Text.Wrap
                    color: Theme.primaryText
                    font.family: AgentService.fontFamily || Qt.application.font.family
                    font.pixelSize: AgentService.fontSize
                    lineHeight: 1.3
                }
            }
        }
    }

    Component {
        id: assistantComp
        Item {
            height: aRect.height
            Rectangle {
                id: aRect; anchors.left: parent.left
                width: Math.min(parent.width * 0.85, aTxt.implicitWidth + 28)
                height: aTxt.implicitHeight + 20; radius: 16
                color: Theme.surfaceContainerHigh
                border.width: 1; border.color: Theme.withAlpha(Theme.outlineVariant, 0.5)
                TextEdit {
                    id: aTxt
                    anchors.fill: parent
                    anchors.margins: 10
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    text: Md.markdownToHtml(content, {
                        codeBg: Theme.surfaceContainerHighest,
                        codeBorder: Theme.withAlpha(Theme.primary, 0.22),
                        codeDivider: Theme.withAlpha(Theme.outlineVariant, 0.4),
                        inlineCodeBg: Theme.surfaceContainerHighest,
                        blockquoteBg: Theme.withAlpha(Theme.surfaceContainerHighest, 0.4),
                        blockquoteBorder: Theme.outline,
                        codeFont: "monospace",
                        codeLabelColor: Theme.surfaceVariantText,
                        syntax: {
                            comment: "#7E8285",
                            string:  "#A8E0A0",
                            number:  "#C198F6",
                            keyword: "#FF7BAC",
                            builtin: "#7DCFFF"
                        }
                    })
                    textFormat: TextEdit.RichText
                    wrapMode: TextEdit.Wrap
                    color: Theme.surfaceText
                    font.family: AgentService.fontFamily || Qt.application.font.family
                    font.pixelSize: AgentService.fontSize
                    readOnly: true
                    selectByMouse: true
                    selectByKeyboard: true
                    persistentSelection: true
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.primaryText
                    onLinkActivated: link => {
                        if (link.indexOf("dmsagent-copy:") === 0) {
                            const idx = parseInt(link.substring("dmsagent-copy:".length))
                            chatRoot.copyCodeBlock(content, idx)
                        } else {
                            Qt.openUrlExternally(link)
                        }
                    }
                }
            }
        }
    }

    function sendCurrentMessage() {
        var text = inputField.text.trim();
        if (!text || AgentService.busy) return;
        inputField.text = "";
        AgentService.sendMessage(text);
    }

    function loadMessages() {
        var msgs = AgentService.messages;
        for (var i = 0; i < msgs.length; i++) {
            var m = msgs[i];
            if (m.role === "tool" || m.role === "tool_result") continue;
            messageModel.append({ msgRole: m.role, msgContent: m.content || "", msgTimestamp: m.timestamp || 0 });
        }
    }

    Component.onCompleted: { loadMessages(); inputField.forceActiveFocus(); }

    Connections {
        target: AgentService

        function onMessageAdded(message) {
            if (message.role === "tool" || message.role === "tool_result") return;
            messageModel.append({ msgRole: message.role, msgContent: message.content, msgTimestamp: message.timestamp });
        }
    }
}
