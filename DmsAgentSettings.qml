import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dmsAgent"

    ColumnLayout {
        width: parent.width
        spacing: Theme.spacingM

        StyledText {
            text: "DMS Agent Settings"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledRect {
            Layout.fillWidth: true
            height: settingsCol.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            ColumnLayout {
                id: settingsCol
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                StyledText {
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
                    text: "System Prompt"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    Layout.topMargin: Theme.spacingS
                }

                StringSetting {
                    settingKey: "systemPrompt"
                    label: "System Prompt"
                    description: "Custom instructions (leave empty for default)"
                    placeholder: "You are a helpful desktop assistant..."
                    defaultValue: ""
                }
            }
        }
    }
}
