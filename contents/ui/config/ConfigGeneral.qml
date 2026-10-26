import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQC

KCM.SimpleKCM {
    id: configGeneral

    property alias cfg_pollInterval: pollIntervalSpinBox.value
    property alias cfg_warningThreshold: warningSpinBox.value
    property alias cfg_criticalThreshold: criticalSpinBox.value
    property string cfg_panelStyle
    property string cfg_gaugeLabel
    property string cfg_panelLabelMode
    property string cfg_colorTheme
    property string cfg_popupStyle
    property alias cfg_showPace: showPaceBox.checked
    property string cfg_timeFormat
    property alias cfg_showClaude: showClaudeBox.checked
    property alias cfg_showCodex: showCodexBox.checked
    property alias cfg_showOpencode: showOpencodeBox.checked
    property alias cfg_showZai: showZaiBox.checked
    property alias cfg_showAntigravity: showAntigravityBox.checked
    property alias cfg_showCommandcode: showCommandcodeBox.checked
    property alias cfg_useGradient: useGradientBox.checked
    property string cfg_normalColor
    property string cfg_midColor
    property string cfg_warningColor
    property string cfg_criticalColor

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: pollIntervalSpinBox
            Kirigami.FormData.label: "Poll interval (seconds):"
            from: 60
            to: 3600
            stepSize: 60
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.disabledTextColor
            text: "Shared by every Usage Limits widget and the ai-limits command. All of them read one cached snapshot, so they always show the same data."
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Panel appearance"
        }

        QQC2.ComboBox {
            id: panelStyleBox
            Kirigami.FormData.label: "Panel style:"
            textRole: "label"
            valueRole: "value"
            model: [
                { label: "Dual Rings (Claudemeter) — outer + inner limit rings", value: "dual_rings" },
                { label: "Gauge (Claudemeter) — single ring with time or %", value: "gauge" },
                { label: "Thermometer Bars (Claudemeter) — pill bars per window", value: "bars" },
                { label: "Glyph Rings — circular gauge with provider letter", value: "rings" },
                { label: "Glow — chip brightness = usage", value: "glow" },
                { label: "Capsule — one segmented strip", value: "capsule" },
                { label: "Dots — severity dots (smallest)", value: "dots" },
                { label: "Letters and percentages", value: "text" },
                { label: "Single worst usage pill", value: "worst" }
            ]
            onActivated: configGeneral.cfg_panelStyle = currentValue
            Component.onCompleted: {
                var found = currentIndex
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === configGeneral.cfg_panelStyle) {
                        found = i
                        break
                    }
                }
                currentIndex = found
            }
        }

        QQC2.ComboBox {
            id: gaugeLabelBox
            Kirigami.FormData.label: "Gauge center text:"
            visible: configGeneral.cfg_panelStyle === "dual_rings" || configGeneral.cfg_panelStyle === "gauge"
            textRole: "label"
            valueRole: "value"
            model: [
                { label: "Percentage — \"38%\"", value: "percent" },
                { label: "Time remaining — \"1h 53m\"", value: "time" },
                { label: "Provider glyph — \"C / X / G\"", value: "glyph" },
                { label: "No center text", value: "none" }
            ]
            onActivated: configGeneral.cfg_gaugeLabel = currentValue
            Component.onCompleted: {
                var found = currentIndex
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === configGeneral.cfg_gaugeLabel) {
                        found = i
                        break
                    }
                }
                currentIndex = found
            }
        }

        QQC2.ComboBox {
            id: panelLabelModeBox
            Kirigami.FormData.label: "Side label:"
            visible: configGeneral.cfg_panelStyle === "dual_rings"
                  || configGeneral.cfg_panelStyle === "gauge"
                  || configGeneral.cfg_panelStyle === "bars"
            textRole: "label"
            valueRole: "value"
            model: [
                { label: "Plan / tier badge — \"PRO / MAX / PLUS\"", value: "plan" },
                { label: "Provider letter — \"C / X / G\"", value: "glyph" },
                { label: "Short name — \"Claude / Codex\"", value: "name" },
                { label: "None", value: "none" }
            ]
            onActivated: configGeneral.cfg_panelLabelMode = currentValue
            Component.onCompleted: {
                var found = currentIndex
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === configGeneral.cfg_panelLabelMode) {
                        found = i
                        break
                    }
                }
                currentIndex = found
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Expanded popup"
        }

        QQC2.ComboBox {
            id: popupStyleBox
            Kirigami.FormData.label: "Popup layout:"
            textRole: "label"
            valueRole: "value"
            model: [
                { label: "Claudemeter — segmented pace bars & extra usage", value: "claudemeter" },
                { label: "Cards — one soft panel per provider", value: "cards" },
                { label: "Compact — dense list with thin bars", value: "compact" },
                { label: "Grid — small tiles in two columns", value: "grid" }
            ]
            onActivated: configGeneral.cfg_popupStyle = currentValue
            Component.onCompleted: {
                var found = currentIndex
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === configGeneral.cfg_popupStyle) {
                        found = i
                        break
                    }
                }
                currentIndex = found
            }
        }

        QQC2.CheckBox {
            id: showPaceBox
            Kirigami.FormData.label: "Pace indicator:"
            text: "Show pace segments, caret marker, and \"Ahead of pace\""
            visible: configGeneral.cfg_popupStyle === "claudemeter"
        }

        QQC2.ComboBox {
            id: timeFormatBox
            Kirigami.FormData.label: "Updated time:"
            textRole: "label"
            valueRole: "value"
            model: [
                { label: "24-hour clock — \"14:32:05\"", value: "24h" },
                { label: "12-hour clock — \"2:32 pm\"", value: "12h" },
                { label: "Relative — \"Refreshed 2m ago\"", value: "ago" }
            ]
            onActivated: configGeneral.cfg_timeFormat = currentValue
            Component.onCompleted: {
                var found = currentIndex
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === configGeneral.cfg_timeFormat) {
                        found = i
                        break
                    }
                }
                currentIndex = found
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Color theme"
        }

        QQC2.ComboBox {
            id: colorThemeBox
            Kirigami.FormData.label: "Theme:"
            textRole: "label"
            valueRole: "value"
            model: [
                { label: "Claudemeter Warm (terracotta → amber → gold → crimson)", value: "warm", normal: "#D77757", mid: "#DF9B65", warning: "#E5C07B", critical: "#E06C75" },
                { label: "Claudemeter Sky Blue (sky → cyan → gold → crimson)", value: "sky", normal: "#3DAEE9", mid: "#56C8D8", warning: "#E5C07B", critical: "#E06C75" },
                { label: "Claudemeter Emerald (emerald → lime → gold → crimson)", value: "emerald", normal: "#27AE60", mid: "#78C850", warning: "#E5C07B", critical: "#E06C75" },
                { label: "Claudemeter Amethyst (purple → rose → gold → crimson)", value: "amethyst", normal: "#9B59B6", mid: "#D3689F", warning: "#E5C07B", critical: "#E06C75" },
                { label: "Sunset (peach → coral → rose → deep red)", value: "sunset", normal: "#F5A97F", mid: "#EE867A", warning: "#E06C75", critical: "#C94A5A" },
                { label: "Nord (frost blue → green → yellow → red)", value: "nord", normal: "#88C0D0", mid: "#A3BE8C", warning: "#EBCB8B", critical: "#BF616A" },
                { label: "Mono (grayscale ramp)", value: "mono", normal: "#8E929B", mid: "#B0B4BE", warning: "#D0D3DC", critical: "#F0F2F8" },
                { label: "Custom (colors below)", value: "custom", normal: "", mid: "", warning: "", critical: "" }
            ]
            onActivated: {
                configGeneral.cfg_colorTheme = currentValue
                var entry = model[currentIndex]
                if (entry && entry.normal) configGeneral.cfg_normalColor = entry.normal
                if (entry && entry.mid) configGeneral.cfg_midColor = entry.mid
                if (entry && entry.warning) configGeneral.cfg_warningColor = entry.warning
                if (entry && entry.critical) configGeneral.cfg_criticalColor = entry.critical
            }
            Component.onCompleted: {
                var found = currentIndex
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === configGeneral.cfg_colorTheme) {
                        found = i
                        break
                    }
                }
                currentIndex = found
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Picking a theme fills the colors below; adjust them freely afterwards."
            opacity: 0.5
            wrapMode: Text.WordWrap
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Providers"
        }

        QQC2.CheckBox {
            id: showClaudeBox
            Kirigami.FormData.label: "Claude:"
            text: "Show Claude usage"
        }

        QQC2.CheckBox {
            id: showCodexBox
            Kirigami.FormData.label: "Codex:"
            text: "Show Codex (ChatGPT plan) usage"
        }

        QQC2.CheckBox {
            id: showOpencodeBox
            Kirigami.FormData.label: "OpenCode Go:"
            text: "Show OpenCode Go usage"
        }

        QQC2.CheckBox {
            id: showZaiBox
            Kirigami.FormData.label: "Z.ai:"
            text: "Show Z.ai (GLM Coding Plan) usage"
        }

        QQC2.CheckBox {
            id: showAntigravityBox
            Kirigami.FormData.label: "Antigravity:"
            text: "Show Google Antigravity usage"
        }

        QQC2.CheckBox {
            id: showCommandcodeBox
            Kirigami.FormData.label: "Command Code:"
            text: "Show Command Code credits and limits"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Thresholds"
        }

        QQC2.SpinBox {
            id: warningSpinBox
            Kirigami.FormData.label: "Warning threshold (%):"
            from: 10
            to: criticalSpinBox.value
            stepSize: 5
        }

        QQC2.SpinBox {
            id: criticalSpinBox
            Kirigami.FormData.label: "Critical threshold (%):"
            from: warningSpinBox.value
            to: 100
            stepSize: 5
        }

        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Beyond the critical threshold the bar uses the theme's negative color."
            opacity: 0.5
            wrapMode: Text.WordWrap
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Colors"
        }

        QQC2.CheckBox {
            id: useGradientBox
            Kirigami.FormData.label: "Gradient:"
            text: "Smooth gradient across usage levels and bar fills"
        }

        Rectangle {
            Kirigami.FormData.label: "Preview:"
            implicitWidth: Kirigami.Units.gridUnit * 14
            implicitHeight: Kirigami.Units.smallSpacing * 3
            radius: height / 2
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: configGeneral.cfg_normalColor || "#D77757" }
                GradientStop { position: 0.38; color: configGeneral.cfg_midColor || "#DF9B65" }
                GradientStop { position: 0.75; color: configGeneral.cfg_warningColor || "#E5C07B" }
                GradientStop { position: 1.0; color: configGeneral.cfg_criticalColor || "#E06C75" }
            }
        }

        KQC.ColorButton {
            Kirigami.FormData.label: "Low color (0%):"
            color: configGeneral.cfg_normalColor || "#D77757"
            onColorChanged: {
                if (String(color) !== configGeneral.cfg_normalColor) {
                    configGeneral.cfg_normalColor = String(color)
                    configGeneral.cfg_colorTheme = "custom"
                }
            }
        }

        KQC.ColorButton {
            Kirigami.FormData.label: "Medium color (~40%):"
            color: configGeneral.cfg_midColor || "#DF9B65"
            onColorChanged: {
                if (String(color) !== configGeneral.cfg_midColor) {
                    configGeneral.cfg_midColor = String(color)
                    configGeneral.cfg_colorTheme = "custom"
                }
            }
        }

        KQC.ColorButton {
            Kirigami.FormData.label: "Warning color:"
            color: configGeneral.cfg_warningColor || "#E5C07B"
            onColorChanged: {
                if (String(color) !== configGeneral.cfg_warningColor) {
                    configGeneral.cfg_warningColor = String(color)
                    configGeneral.cfg_colorTheme = "custom"
                }
            }
        }

        KQC.ColorButton {
            Kirigami.FormData.label: "Critical color:"
            color: configGeneral.cfg_criticalColor || "#E06C75"
            onColorChanged: {
                if (String(color) !== configGeneral.cfg_criticalColor) {
                    configGeneral.cfg_criticalColor = String(color)
                    configGeneral.cfg_colorTheme = "custom"
                }
            }
        }
    }
}
