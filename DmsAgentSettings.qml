import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dmsAgent"

    readonly property string toggleCommand: "dms ipc call dmsAgent toggle"

    StyledText {
        width: parent.width
        text: "DMS Agent Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledRect {
        width: parent.width
        height: settingsCol.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: settingsCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                width: parent.width
                text: "Claude"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            StringSetting {
                settingKey: "claudeModel"
                label: "Model"
                description: "haiku (fast), sonnet (balanced), opus (best)"
                placeholder: "haiku"
                defaultValue: "haiku"
            }

            ToggleSetting {
                settingKey: "extendedThinking"
                label: "Extended Thinking"
                description: "Deeper reasoning, slower responses. Best with sonnet/opus."
                defaultValue: false
            }

            StringSetting {
                settingKey: "maxTokens"
                label: "Max Tokens"
                description: "Maximum response length"
                placeholder: "1024"
                defaultValue: "1024"
            }

            StyledText {
                width: parent.width
                text: "System Prompt"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
                topPadding: Theme.spacingS
            }

            StringSetting {
                settingKey: "systemPrompt"
                label: "System Prompt"
                description: "Custom instructions (leave empty for default)"
                placeholder: "You are a helpful desktop assistant..."
                defaultValue: ""
            }

            StyledText {
                width: parent.width
                text: "Appearance"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
                topPadding: Theme.spacingS
            }

            StringSetting {
                settingKey: "fontFamily"
                label: "Font"
                description: "Font family for chat text. Leave empty for system default."
                placeholder: "e.g. Inter, Roboto, sans-serif"
                defaultValue: ""
            }

            SliderSetting {
                settingKey: "fontSize"
                label: "Font Size"
                description: "Chat text size in pixels"
                defaultValue: 13
                minimum: 10
                maximum: 20
                unit: "px"
            }
        }
    }

    StyledText {
        width: parent.width
        text: "Keybind"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    StyledText {
        width: parent.width
        text: "Add this to your compositor config to toggle the agent:"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: keybindRow.implicitHeight + Theme.spacingM
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Row {
            id: keybindRow
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingS

            StyledText {
                id: keybindCommand
                text: root.toggleCommand
                font.pixelSize: Theme.fontSizeSmall
                font.family: "monospace"
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: keybindRow.width - keybindCommand.width - copyIcon.width - Theme.spacingS * 3
                height: 1
            }

            DankIcon {
                id: copyIcon
                name: "content_copy"
                size: Theme.iconSizeSmall
                color: copyMouse.containsMouse ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["sh", "-c", "echo -n '" + root.toggleCommand + "' | wl-copy"]);
                        ToastService.showInfo("Copied", "Command copied to clipboard");
                    }
                }
            }
        }
    }

    StyledText {
        width: parent.width
        text: "niri (~/.config/niri/config.kdl):"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        topPadding: Theme.spacingS
    }

    StyledText {
        width: parent.width
        text: "Mod+A { spawn \"sh\" \"-c\" \"" + root.toggleCommand + "\"; }"
        font.pixelSize: Theme.fontSizeSmall
        font.family: "monospace"
        color: Theme.surfaceText
        wrapMode: Text.Wrap
    }

    StyledText {
        width: parent.width
        text: "Hyprland:"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        topPadding: Theme.spacingS
    }

    StyledText {
        width: parent.width
        text: "bind = SUPER, A, exec, " + root.toggleCommand
        font.pixelSize: Theme.fontSizeSmall
        font.family: "monospace"
        color: Theme.surfaceText
        wrapMode: Text.Wrap
    }
}
