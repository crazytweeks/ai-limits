import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.quickcharts as Charts

MouseArea {
    id: compact

    // Styles:
    // "dual_rings" — concentric outer + inner gauge rings per provider
    // "gauge"      — single gauge ring with time/percent/glyph
    // "bars"       — vertical pill thermometer bars
    // "rings"      — circular gauge with provider letter
    // "glow"       — brightness chips
    // "dots"       — severity dots
    // "capsule"    — single segmented strip
    // "text"       — letters + percentages
    // "worst"      — single worst usage pill
    readonly property string style: root.panelStyle
    readonly property bool hasData: root.limitRows.length > 0
    readonly property int chipSize: Math.max(14, Math.min(24, compact.height - 8))
    readonly property int gaugeSize: Math.max(20, Math.min(34, compact.height - 2))
    readonly property real pad: Kirigami.Units.smallSpacing * 1.5
    readonly property bool isDark: Kirigami.Theme.backgroundColor.hslLightness < 0.5
    readonly property color trackColor: isDark ? "#2A2D30" : "#EEF0F1"

    function glyph(p) {
        return root.providerGlyph(p)
    }

    function glyphForId(providerId, providerName) {
        return root.providerGlyphForId(providerId, providerName)
    }

    function sideLabel(p) {
        var mode = root.panelLabelMode
        if (mode === "none") return ""
        if (mode === "plan") return root.providerPlanBadge(p)
        if (mode === "name") return root.providerShortName(p)
        return root.providerGlyph(p)
    }

    function worstOf(provider) {
        var windows = root.toArray(provider.windows)
        var worst = 0
        for (var i = 0; i < windows.length; i++) {
            var value = windows[i].percent || 0
            if (value > worst) worst = value
        }
        return worst
    }

    // Picks [outerUtil, innerUtil] for dual-ring gauges so providers with 3+
    // windows (OpenCode Go, Antigravity, Command Code) always show their
    // active 5h limit on the outer ring and their fullest longer limit on the
    // inner ring.
    function ringPairOf(provider) {
        var windows = root.toArray(provider.windows)
        if (windows.length === 0) return [0, 0]
        if (windows.length === 1) return [windows[0].percent || 0, 0]
        if (windows.length === 2) return [windows[0].percent || 0, windows[1].percent || 0]
        var shortBest = -1
        var longBest = 0
        for (var i = 0; i < windows.length; i++) {
            var w = windows[i]
            var p = w.percent || 0
            var id = String(w.id || "")
            var lbl = String(w.label || "")
            if (id === "five_hour" || id === "rolling" || /5h/i.test(lbl)) {
                if (p > shortBest) shortBest = p
            } else {
                if (p > longBest) longBest = p
            }
        }
        if (shortBest < 0) shortBest = windows[0].percent || 0
        return [shortBest, longBest]
    }

    function primaryResetOf(provider) {
        var windows = root.toArray(provider.windows)
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].resetsAt) return windows[i].resetsAt
        }
        return ""
    }

    onClicked: root.expanded = !root.expanded
    hoverEnabled: true

    Layout.minimumWidth: (loader.item ? loader.item.implicitWidth : Kirigami.Units.gridUnit) + compact.pad * 2
    Layout.minimumHeight: Kirigami.Units.gridUnit
    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight

    Kirigami.Icon {
        visible: root.hasError && (!loader.item || !loader.item.showsData)
        anchors.centerIn: parent
        width: Kirigami.Units.iconSizes.small
        height: width
        source: "data-warning"
        color: Kirigami.Theme.negativeTextColor
    }

    Loader {
        id: loader
        anchors.centerIn: parent
        sourceComponent: {
            if (compact.style === "dual_rings") return dualRingsStyle
            if (compact.style === "gauge") return gaugeStyle
            if (compact.style === "rings") return ringsStyle
            if (compact.style === "glow") return glowStyle
            if (compact.style === "dots") return dotsStyle
            if (compact.style === "capsule") return capsuleStyle
            if (compact.style === "text") return textStyle
            if (compact.style === "worst") return worstStyle
            return barsStyle
        }
    }

    // === Style: Thermometer Bars ===============================
    Component {
        id: barsStyle
        Item {
            readonly property bool showsData: true
            readonly property real barHeight: Math.max(14, compact.height * 0.76)
            readonly property int barThickness: Math.max(4, Math.round(barHeight / 4.5))
            implicitWidth: barRow.implicitWidth
            implicitHeight: barHeight

            Row {
                id: barRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 2

                Repeater {
                    model: root.visibleProviders

                    Row {
                        id: providerGroup
                        required property var modelData
                        readonly property var provider: modelData
                        readonly property bool isOk: provider.state === "ok"
                        readonly property var windows: isOk ? root.toArray(provider.windows) : []
                        readonly property string badgeText: compact.sideLabel(provider)

                        spacing: Kirigami.Units.smallSpacing * 0.8
                        anchors.verticalCenter: parent.verticalCenter

                        QQC2.Label {
                            visible: providerGroup.badgeText !== ""
                            text: providerGroup.badgeText
                            font.pixelSize: Math.max(8, Math.round(compact.height * 0.30))
                            opacity: 0.65
                            color: Kirigami.Theme.textColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            id: innerBars
                            spacing: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: providerGroup.windows

                                Rectangle {
                                    required property var modelData
                                    readonly property var win: modelData
                                    readonly property real util: win ? (win.percent || 0) : 0

                                    width: barsStyleItem ? barsStyleItem.barThickness : 5
                                    property var barsStyleItem: innerBars.parent.parent.parent
                                    height: barsStyleItem ? barsStyleItem.barHeight : 20
                                    radius: width / 2
                                    color: Kirigami.Theme.backgroundColor
                                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                                    border.width: 1

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: parent.height * Math.min(Math.max(parent.util, 0) / 100, 1.0)
                                        radius: parent.radius
                                        color: root.usageColor(parent.util)
                                        gradient: Gradient {
                                            orientation: Gradient.Vertical
                                            GradientStop {
                                                position: 0.0
                                                color: root.usageColor(parent.util)
                                            }
                                            GradientStop {
                                                position: 1.0
                                                color: root.useGradient ? root.normalColor : root.usageColor(parent.util)
                                            }
                                        }

                                        Behavior on height {
                                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }
                            }
                        }

                        Kirigami.Icon {
                            visible: providerGroup.windows.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            source: providerGroup.isOk ? "view-refresh" : "data-warning"
                            color: providerGroup.isOk ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.negativeTextColor
                        }
                    }
                }
            }
        }
    }

    // === Style: Dual Rings (Outer + Inner Concentric Gauge) =====
    Component {
        id: dualRingsStyle
        Item {
            readonly property bool showsData: compact.hasData
            implicitWidth: dualRow.implicitWidth
            implicitHeight: compact.gaugeSize

            Row {
                id: dualRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 1.8

                Repeater {
                    model: root.visibleProviders

                    Row {
                        id: dualGroup
                        required property var modelData
                        readonly property var provider: modelData
                        readonly property bool isOk: provider.state === "ok"
                        readonly property var windows: isOk ? root.toArray(provider.windows) : []
                        readonly property var pair: isOk ? compact.ringPairOf(provider) : [0, 0]
                        readonly property real outerUtil: pair[0]
                        readonly property real innerUtil: pair[1]
                        readonly property bool hasInner: windows.length > 1
                        readonly property real worstUtil: isOk ? compact.worstOf(provider) : 0
                        readonly property real displayUtil: outerUtil >= 1 ? outerUtil : worstUtil
                        readonly property string badgeText: compact.sideLabel(provider)

                        spacing: Kirigami.Units.smallSpacing * 0.7
                        anchors.verticalCenter: parent.verticalCenter

                        QQC2.Label {
                            visible: dualGroup.badgeText !== ""
                            text: dualGroup.badgeText
                            font.pixelSize: Math.max(8, Math.round(compact.height * 0.28))
                            opacity: 0.65
                            color: Kirigami.Theme.textColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            id: gaugeBox
                            width: compact.gaugeSize
                            height: compact.gaugeSize
                            anchors.verticalCenter: parent.verticalCenter

                            readonly property real ringThickness: Math.max(2.0, width * 0.095)
                            readonly property real innerInset: ringThickness + 1.2
                            readonly property bool showInner: dualGroup.isOk && dualGroup.hasInner && width >= ringThickness * 6

                            // Outer background track
                            Charts.PieChart {
                                anchors.fill: parent
                                visible: dualGroup.isOk
                                fromAngle: -180
                                toAngle: 180
                                smoothEnds: true
                                thickness: gaugeBox.ringThickness
                                range { from: 0; to: 100; automatic: false }
                                valueSources: Charts.SingleValueSource { value: 100 }
                                colorSource: Charts.SingleValueSource { value: compact.trackColor }
                            }

                            // Outer foreground arc
                            Charts.PieChart {
                                anchors.fill: parent
                                visible: dualGroup.isOk
                                fromAngle: -180
                                toAngle: 180
                                smoothEnds: true
                                thickness: gaugeBox.ringThickness
                                range { from: 0; to: 100; automatic: false }
                                valueSources: Charts.SingleValueSource { value: dualGroup.outerUtil }
                                colorSource: Charts.SingleValueSource { value: root.usageColor(dualGroup.outerUtil) }
                            }

                            // Inner background track
                            Charts.PieChart {
                                anchors.fill: parent
                                anchors.margins: gaugeBox.innerInset
                                visible: gaugeBox.showInner
                                fromAngle: -180
                                toAngle: 180
                                smoothEnds: true
                                thickness: Math.max(1.8, gaugeBox.ringThickness * 0.82)
                                range { from: 0; to: 100; automatic: false }
                                valueSources: Charts.SingleValueSource { value: 100 }
                                colorSource: Charts.SingleValueSource { value: compact.trackColor }
                            }

                            // Inner foreground arc
                            Charts.PieChart {
                                anchors.fill: parent
                                anchors.margins: gaugeBox.innerInset
                                visible: gaugeBox.showInner
                                fromAngle: -180
                                toAngle: 180
                                smoothEnds: true
                                thickness: Math.max(1.8, gaugeBox.ringThickness * 0.82)
                                range { from: 0; to: 100; automatic: false }
                                valueSources: Charts.SingleValueSource { value: dualGroup.innerUtil }
                                colorSource: Charts.SingleValueSource { value: root.usageColor(dualGroup.innerUtil) }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: dualGroup.isOk && root.gaugeLabel !== "none"
                                text: {
                                    var mode = root.gaugeLabel
                                    if (mode === "glyph") return compact.glyph(dualGroup.provider)
                                    if (mode === "time") {
                                        var t = root.formatResetTime(compact.primaryResetOf(dualGroup.provider))
                                        return (t && t !== "expired") ? t : (Math.round(dualGroup.displayUtil) + "%")
                                    }
                                    return Math.round(dualGroup.displayUtil) + "%"
                                }
                                color: Kirigami.Theme.textColor
                                font.pixelSize: Math.max(6, Math.round(parent.width * 0.21))
                                font.bold: root.gaugeLabel === "glyph"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Kirigami.Icon {
                                visible: !dualGroup.isOk
                                anchors.centerIn: parent
                                width: parent.width * 0.7
                                height: width
                                source: "data-warning"
                                color: Kirigami.Theme.negativeTextColor
                            }
                        }
                    }
                }
            }
        }
    }

    // === Style: Single Gauge ====================================
    Component {
        id: gaugeStyle
        Item {
            readonly property bool showsData: compact.hasData
            implicitWidth: singleGaugeRow.implicitWidth
            implicitHeight: compact.gaugeSize

            Row {
                id: singleGaugeRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 1.8

                Repeater {
                    model: root.visibleProviders

                    Row {
                        id: singleGroup
                        required property var modelData
                        readonly property var provider: modelData
                        readonly property bool isOk: provider.state === "ok"
                        readonly property real util: isOk ? compact.worstOf(provider) : 0
                        readonly property string badgeText: compact.sideLabel(provider)

                        spacing: Kirigami.Units.smallSpacing * 0.7
                        anchors.verticalCenter: parent.verticalCenter

                        QQC2.Label {
                            visible: singleGroup.badgeText !== ""
                            text: singleGroup.badgeText
                            font.pixelSize: Math.max(8, Math.round(compact.height * 0.30))
                            opacity: 0.65
                            color: Kirigami.Theme.textColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            width: compact.gaugeSize
                            height: compact.gaugeSize
                            anchors.verticalCenter: parent.verticalCenter

                            readonly property real ringThickness: Math.max(2.6, Math.round(width * 0.14))

                            Charts.PieChart {
                                anchors.fill: parent
                                visible: singleGroup.isOk
                                fromAngle: -180
                                toAngle: 180
                                smoothEnds: true
                                thickness: parent.ringThickness
                                range { from: 0; to: 100; automatic: false }
                                valueSources: Charts.SingleValueSource { value: 100 }
                                colorSource: Charts.SingleValueSource { value: compact.trackColor }
                            }

                            Charts.PieChart {
                                anchors.fill: parent
                                visible: singleGroup.isOk
                                fromAngle: -180
                                toAngle: 180
                                smoothEnds: true
                                thickness: parent.ringThickness
                                range { from: 0; to: 100; automatic: false }
                                valueSources: Charts.SingleValueSource { value: singleGroup.util }
                                colorSource: Charts.SingleValueSource { value: root.usageColor(singleGroup.util) }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: singleGroup.isOk && root.gaugeLabel !== "none"
                                text: {
                                    var mode = root.gaugeLabel
                                    if (mode === "glyph") return compact.glyph(singleGroup.provider)
                                    if (mode === "time") {
                                        var t = root.formatResetTime(compact.primaryResetOf(singleGroup.provider))
                                        return (t && t !== "expired") ? t : (Math.round(singleGroup.util) + "%")
                                    }
                                    return Math.round(singleGroup.util) + "%"
                                }
                                color: Kirigami.Theme.textColor
                                font.pixelSize: Math.max(6, Math.round(parent.width * (root.gaugeLabel === "time" ? 0.18 : 0.23)))
                                font.bold: root.gaugeLabel === "glyph"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Kirigami.Icon {
                                visible: !singleGroup.isOk
                                anchors.centerIn: parent
                                width: parent.width * 0.7
                                height: width
                                source: "data-warning"
                                color: Kirigami.Theme.negativeTextColor
                            }
                        }
                    }
                }
            }
        }
    }

    // === Style: rings — circular gauge with provider glyph ==================
    Component {
        id: ringsStyle
        Item {
            readonly property bool showsData: compact.hasData
            readonly property int ringSize: compact.chipSize
            implicitWidth: ringRow.implicitWidth
            implicitHeight: ringSize

            Row {
                id: ringRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 1.2

                Repeater {
                    model: root.visibleProviders

                    Item {
                        id: ringCell
                        required property var modelData
                        readonly property var provider: modelData
                        readonly property bool isOk: provider.state === "ok"
                        readonly property real util: isOk ? compact.worstOf(provider) : 0
                        readonly property real size: compact.chipSize

                        width: size
                        height: size

                        Charts.PieChart {
                            anchors.fill: parent
                            visible: ringCell.isOk
                            fromAngle: -180
                            toAngle: 180
                            smoothEnds: true
                            thickness: Math.max(2.2, Math.round(ringCell.size * 0.13))
                            range { from: 0; to: 100; automatic: false }
                            valueSources: Charts.SingleValueSource { value: 100 }
                            colorSource: Charts.SingleValueSource { value: compact.trackColor }
                        }

                        Charts.PieChart {
                            anchors.fill: parent
                            visible: ringCell.isOk
                            fromAngle: -180
                            toAngle: 180
                            smoothEnds: true
                            thickness: Math.max(2.2, Math.round(ringCell.size * 0.13))
                            range { from: 0; to: 100; automatic: false }
                            valueSources: Charts.SingleValueSource { value: ringCell.util }
                            colorSource: Charts.SingleValueSource { value: root.usageColor(ringCell.util) }
                        }

                        QQC2.Label {
                            visible: ringCell.isOk
                            anchors.centerIn: parent
                            text: compact.glyph(ringCell.provider)
                            color: root.usageColor(ringCell.util)
                            font.pixelSize: ringCell.size * 0.42
                            font.bold: true
                        }

                        Kirigami.Icon {
                            visible: !ringCell.isOk
                            anchors.centerIn: parent
                            width: ringCell.size * 0.7
                            height: width
                            source: "data-warning"
                            color: Kirigami.Theme.negativeTextColor
                        }
                    }
                }
            }
        }
    }

    // === Style: glow — chip whose brightness equals usage ===================
    Component {
        id: glowStyle
        Item {
            readonly property bool showsData: compact.hasData
            implicitWidth: glowRow.implicitWidth
            implicitHeight: compact.chipSize

            Row {
                id: glowRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 0.8

                Repeater {
                    model: root.visibleProviders

                    Rectangle {
                        id: glowCell
                        required property var modelData
                        readonly property var provider: modelData
                        readonly property bool isOk: provider.state === "ok"
                        readonly property real util: isOk ? compact.worstOf(provider) : 0
                        readonly property real intensity: isOk ? (0.14 + 0.86 * Math.min(1, Math.max(0, util) / 100)) : 0.0

                        width: compact.chipSize
                        height: compact.chipSize
                        radius: height * 0.32
                        color: isOk
                            ? Qt.alpha(root.usageColor(util), intensity)
                            : Qt.rgba(0.5, 0.5, 0.5, 0.15)

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: compact.glyph(glowCell.provider)
                            color: glowCell.isOk
                                ? (glowCell.intensity > 0.75 ? "#241408" : Kirigami.Theme.textColor)
                                : Kirigami.Theme.negativeTextColor
                            font.pixelSize: glowCell.height * 0.5
                            font.bold: true
                        }
                    }
                }
            }
        }
    }

    // === Style: severity dots ===============================================
    Component {
        id: dotsStyle
        Item {
            readonly property bool showsData: compact.hasData
            implicitWidth: dotsRow.implicitWidth
            implicitHeight: Kirigami.Units.iconSizes.small

            Row {
                id: dotsRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 1.2

                Repeater {
                    model: root.visibleProviders

                    Rectangle {
                        required property var modelData
                        readonly property var provider: modelData
                        readonly property bool isOk: provider.state === "ok"
                        readonly property real util: isOk ? compact.worstOf(provider) : 0

                        width: Kirigami.Units.iconSizes.small
                        height: width
                        radius: width * 0.32
                        color: isOk
                            ? root.usageColor(util)
                            : Kirigami.Theme.disabledTextColor
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.25)
                    }
                }
            }
        }
    }

    // === Style: capsule — one strip, one slot per provider ==================
    Component {
        id: capsuleStyle
        Item {
            readonly property bool showsData: compact.hasData
            readonly property real capsuleWidth: Kirigami.Units.gridUnit * 7
            readonly property real capsuleHeight: Math.max(10, Math.min(16, compact.height * 0.5))
            implicitWidth: capsuleWidth
            implicitHeight: capsuleHeight

            Rectangle {
                id: capsuleBg
                anchors.centerIn: parent
                width: parent.capsuleWidth
                height: parent.capsuleHeight
                radius: height / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
                clip: true

                Row {
                    id: capsuleRow
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: root.visibleProviders

                        Item {
                            id: capsuleCell
                            required property var modelData
                            readonly property var provider: modelData
                            readonly property bool isOk: provider.state === "ok"
                            readonly property real util: isOk ? compact.worstOf(provider) : 0

                            width: capsuleBg.visible ? (capsuleBg.width / Math.max(1, root.visibleProviders.length)) : 0
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Math.min(height / 2, 6)
                                color: capsuleCell.isOk
                                    ? Qt.alpha(root.usageColor(capsuleCell.util), 0.22)
                                    : "transparent"
                                visible: capsuleCell.isOk
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: 1
                                width: (parent.width - 2) * Math.min(100, Math.max(0, capsuleCell.util)) / 100
                                radius: height / 2
                                color: capsuleCell.isOk ? root.usageColor(capsuleCell.util) : "transparent"
                                visible: capsuleCell.isOk && capsuleCell.util > 0
                            }
                        }
                    }
                }
            }
        }
    }

    // === Style: letters and percentages =====================================
    Component {
        id: textStyle
        Row {
            readonly property bool showsData: compact.hasData
            spacing: Kirigami.Units.smallSpacing * 1.5
            leftPadding: 0

            Repeater {
                model: root.limitRows

                QQC2.Label {
                    required property var modelData
                    readonly property var win: modelData

                    text: compact.glyphForId(win.providerId, win.provider) + " " + Math.round(win.util) + "%"
                    color: root.usageColor(win.util)
                    font.bold: win.util >= root.warningThreshold
                    font.pointSize: Qt.application.font.pointSize * 0.85
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // === Style: single pill for the worst usage overall =====================
    Component {
        id: worstStyle
        Rectangle {
            readonly property bool showsData: compact.hasData
            implicitWidth: badgeRow.implicitWidth + Kirigami.Units.smallSpacing * 3
            implicitHeight: compact.height * 0.78
            radius: height / 2
            color: Qt.alpha(root.usageColor(root.worstUtil), 0.18)

            Row {
                id: badgeRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Math.min(100, Math.max(0, root.worstUtil))) + "%"
                    font.pointSize: Qt.application.font.pointSize * 0.85
                    font.bold: root.worstUtil >= root.warningThreshold
                }
            }
        }
    }
}
