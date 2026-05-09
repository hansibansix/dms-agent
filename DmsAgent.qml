import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "dmsAgent"

    onPluginDataChanged: {
        if (!pluginData) return;
        AgentService.claudeModel = pluginData.claudeModel || "haiku";
        AgentService.maxTokens = parseInt(pluginData.maxTokens) || 1024;
        AgentService.extendedThinking = pluginData.extendedThinking === true;
        AgentService.fontFamily = pluginData.fontFamily || "";
        AgentService.fontSize = parseInt(pluginData.fontSize) || 13;
        if (pluginData.systemPrompt) AgentService.systemPrompt = pluginData.systemPrompt;
    }

    // Fullscreen transparent layer that catches clicks anywhere outside the
    // agent panel and dismisses the popup. Sits on the same Top layer; the
    // agentPanel is declared after it so it's mapped on top, meaning clicks
    // INSIDE the panel area still reach the panel and only OUTSIDE clicks
    // land on this surface's MouseArea.
    PanelWindow {
        id: dimmer
        screen: agentPanel.screen
        visible: agentPanel.isVisible
        color: "transparent"

        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true

        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.namespace: "dms:agent:bg"
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: agentPanel.hide()
        }
    }

    PanelWindow {
        id: agentPanel

        readonly property string myScreenName: root.parentScreen ? root.parentScreen.name : ""
        readonly property bool isVisible: myScreenName !== "" && AgentService.activeScreenName === myScreenName

        function show() { if (myScreenName) AgentService.activeScreenName = myScreenName; }
        function hide() { if (AgentService.activeScreenName === myScreenName) AgentService.activeScreenName = ""; }
        function toggle() { isVisible ? hide() : show(); }

        property real animScale: 0.92
        property real animOpacity: 0.0

        onIsVisibleChanged: {
            animScale = isVisible ? 1.0 : 0.92;
            animOpacity = isVisible ? 1.0 : 0.0;
        }

        visible: isVisible || hideAnim.running || scaleAnim.running
        screen: root.parentScreen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
        color: "transparent"

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "dms:agent"
        WlrLayershell.exclusiveZone: 0
        WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        implicitWidth: 900
        implicitHeight: 950

        Item {
            id: animContainer
            anchors.fill: parent
            anchors.margins: 10
            scale: agentPanel.animScale
            opacity: agentPanel.animOpacity
            transformOrigin: Item.Center

            ElevationShadow {
                anchors.fill: parent
                level: Theme.elevationLevel3
                targetRadius: 20
                targetColor: Theme.withAlpha(Theme.surfaceContainer, 0.95)
                borderColor: Theme.outlineVariant
                borderWidth: 1
            }

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
            NumberAnimation { id: hideAnim; duration: 200; easing.type: Easing.OutCubic }
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
