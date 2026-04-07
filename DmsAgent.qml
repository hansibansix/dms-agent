import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "dmsAgent"

    IpcHandler {
        function toggle(): string {
            agentPanel.toggle();
            return agentPanel.isVisible ? "opened" : "closed";
        }
        target: "dmsAgent"
    }

    onPluginDataChanged: {
        if (!pluginData) return;
        AgentService.claudeModel = pluginData.claudeModel || "haiku";
        AgentService.maxTokens = parseInt(pluginData.maxTokens) || 1024;
        AgentService.extendedThinking = pluginData.extendedThinking === true;
        if (pluginData.systemPrompt) AgentService.systemPrompt = pluginData.systemPrompt;
    }

    PanelWindow {
        id: agentPanel

        property bool isVisible: false

        function show() {
            visible = true; isVisible = true; AgentService.popoutVisible = true;
            animScale = 1.0; animOpacity = 1.0;
        }
        function hide() {
            isVisible = false; AgentService.popoutVisible = false;
            animScale = 0.92; animOpacity = 0.0;
        }
        function toggle() { if (isVisible) hide(); else show(); }

        property real animScale: 0.92
        property real animOpacity: 0.0

        visible: isVisible || hideAnim.running || scaleAnim.running
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        color: "transparent"

        anchors.bottom: true

        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.namespace: "dms:agent"
        WlrLayershell.exclusiveZone: 0
        WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.margins.bottom: 44

        implicitWidth: 660
        implicitHeight: 740

        Item {
            id: animContainer
            anchors.fill: parent
            anchors.margins: 10
            scale: agentPanel.animScale
            opacity: agentPanel.animOpacity
            transformOrigin: Item.Bottom

            DmsAgentChat {
                id: agentChat
                anchors.fill: parent
                onEscapePressed: agentPanel.hide()
            }
        }

        Behavior on animScale {
            NumberAnimation { id: scaleAnim; duration: 250; easing.type: Easing.OutCubic }
        }

        Behavior on animOpacity {
            NumberAnimation {
                id: hideAnim; duration: 200; easing.type: Easing.OutCubic
                onRunningChanged: { if (!running && !agentPanel.isVisible) agentPanel.visible = false; }
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon {
                name: AgentService.busy ? "hourglass_top" : "smart_toy"
                color: AgentService.busy ? "#FF9800" : Theme.primary
                size: root.iconSize; anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: AgentService.busy ? "Working..." : "Agent"
                color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 2
            DankIcon {
                name: AgentService.busy ? "hourglass_top" : "smart_toy"
                color: AgentService.busy ? "#FF9800" : Theme.primary
                size: root.iconSize; anchors.horizontalCenter: parent.horizontalCenter
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: AgentService.busy ? "..." : "AI"
                color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall
            }
        }
    }

    pillClickAction: function() {
        agentPanel.toggle();
    }
}
