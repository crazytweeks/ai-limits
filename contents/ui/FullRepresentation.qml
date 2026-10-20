import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

Item {
    id: full

    readonly property string popupStyle: root.popupStyle
    readonly property bool isClaudemeter: popupStyle === "claudemeter"
    readonly property bool showTopToolbar: !isClaudemeter || root.visibleProviders.length === 0

    // Popup sizing: width fixed, height bounded so the dialog never leaves
    // the screen — everything inside scrolls.
    readonly property real scrollCap: Kirigami.Units.gridUnit * 27.5
    readonly property real contentNeeded: content.implicitHeight + Kirigami.Units.smallSpacing * 2
    implicitWidth: isClaudemeter ? Kirigami.Units.gridUnit * 21 : Kirigami.Units.gridUnit * 25
    implicitHeight: (showTopToolbar ? header.implicitHeight : 0)
                    + (root.hasError ? errorLabel.implicitHeight : 0)
                    + Math.min(contentNeeded, scrollCap)
                    + footer.implicitHeight
                    + Kirigami.Units.smallSpacing * 4

    function barHeight() {
        return Math.max(Kirigami.Units.gridUnit * 0.28, 6)
    }

    /**
     * Compact inline usage row used by Cards, Compact, and Grid popup layouts.
     */
    component UsageRow: RowLayout {
        required property var win

        spacing: Kirigami.Units.smallSpacing * 1.2

        QQC2.Label {
            text: win.label
            font.pointSize: Qt.application.font.pointSize * 0.92
            elide: Text.ElideRight
            Layout.maximumWidth: Kirigami.Units.gridUnit * 5.5
        }

        QQC2.Label {
            visible: win.resetsAt !== ""
            text: root.formatResetTime(win.resetsAt)
            opacity: 0.55
            font.pointSize: Qt.application.font.pointSize * 0.85
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.minimumWidth: Kirigami.Units.gridUnit * 2
            implicitHeight: full.barHeight()
            radius: height / 2
            color: Qt.alpha(Kirigami.Theme.textColor, 0.10)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.min(100, Math.max(0, win.percent)) / 100
                radius: parent.radius
                color: root.usageColor(win.percent)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: root.useGradient ? root.normalColor : root.usageColor(win.percent)
                    }
                    GradientStop {
                        position: 0.5
                        color: root.useGradient ? root.usageColor((win.percent || 0) * 0.5) : root.usageColor(win.percent)
                    }
                    GradientStop {
                        position: 1.0
                        color: root.usageColor(win.percent)
                    }
                }
                Behavior on width { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
            }
        }

        QQC2.Label {
            text: Math.round(win.percent) + "%"
            font.pointSize: Qt.application.font.pointSize * 0.92
            font.bold: win.percent >= root.warningThreshold
            color: root.usageColor(win.percent)
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
        }
    }

    /** Round initials chip used as the provider mark in Cards/Compact styles. */
    component ProviderMark: Rectangle {
        id: mark
        required property var provider
        readonly property real worst: root.providerWorst(provider)
        width: Kirigami.Units.iconSizes.small
        height: width
        radius: height * 0.32
        color: provider.state === "ok"
            ? Qt.alpha(root.usageColor(worst), 0.22)
            : Qt.alpha(Kirigami.Theme.negativeTextColor, 0.18)

        QQC2.Label {
            anchors.centerIn: parent
            text: root.providerGlyph(parent.provider)
            color: parent.provider.state === "ok"
                ? root.usageColor(parent.worst)
                : Kirigami.Theme.negativeTextColor
            font.bold: true
            font.pixelSize: parent.height * 0.45
        }
    }

    ColumnLayout {
        id: header
        visible: full.showTopToolbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            QQC2.Label {
                visible: root.loading && !root.hasError
                text: "Loading…"
                opacity: 0.6
            }

            QQC2.ToolButton {
                display: QQC2.AbstractButton.IconOnly
                icon.name: "view-refresh"
                enabled: !root.fetchInFlight
                onClicked: root.requestFetch("manual")

                QQC2.ToolTip.text: "Refresh now"
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.longDuration
            }
        }
    }

    QQC2.Label {
        id: errorLabel
        anchors.top: full.showTopToolbar ? header.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        Layout.fillWidth: true
        visible: root.hasError
        text: root.errorMessage
        color: Kirigami.Theme.negativeTextColor
        wrapMode: Text.WordWrap
    }

    QQC2.ScrollView {
        id: scroller
        anchors.top: root.hasError ? errorLabel.bottom : (full.showTopToolbar ? header.bottom : parent.top)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footer.top
        anchors.topMargin: full.showTopToolbar ? Kirigami.Units.smallSpacing : 0
        clip: true

        ColumnLayout {
            id: content
            width: scroller.width
                   - (scroller.QQC2.ScrollBar.vertical.visible
                      ? scroller.QQC2.ScrollBar.vertical.width : 0)
            spacing: Kirigami.Units.smallSpacing * 1.4

            Loader {
                Layout.fillWidth: true
                sourceComponent: {
                    if (full.popupStyle === "claudemeter") return claudemeterList
                    if (full.popupStyle === "compact") return compactList
                    if (full.popupStyle === "grid") return gridStyle
                    return cardList
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                visible: !root.hasError && !root.loading && root.limitRows.length === 0
                text: {
                    var any = root.providers.length > 0
                    return any ? "No active usage data. Enable providers in settings or sign in via their CLIs."
                               : "No usage data yet. Wait for the first fetch."
                }
                opacity: 0.6
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }
        }
    }

    // Ticks so the relative "… ago" time stays current while open.
    property bool tick: false
    Timer {
        interval: 15000
        running: full.visible
        repeat: true
        onTriggered: full.tick = !full.tick
    }

    QQC2.Label {
        id: footer
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.smallSpacing
        visible: !root.hasError && !root.loading
        font: Kirigami.Theme.smallFont
        color: Kirigami.Theme.disabledTextColor
        text: {
            var t = root.lastUpdated
            var mode = root.timeFormat
            if (mode === "ago" || tick === undefined) {
                var diff = Math.max(0, (Date.now() - t.getTime()) / 1000)
                if (diff < 60) return "Refreshed " + Math.floor(diff) + "s ago"
                if (diff < 3600) return "Refreshed " + Math.floor(diff / 60) + "m ago"
                return "Refreshed " + Math.floor(diff / 3600) + "h ago"
            }
            return "Updated " + Qt.formatTime(t, mode === "12h" ? "h:mm ap" : "hh:mm:ss")
        }
    }

    // === Style: claudemeter — segmented pace bars, caret markers & extra usage ===

    Component {
        id: claudemeterList
        ColumnLayout {
            width: parent ? parent.width : 0
            spacing: Kirigami.Units.smallSpacing * 1.4

            Repeater {
                model: root.visibleProviders

                ColumnLayout {
                    id: cmSection
                    required property var modelData
                    required property int index
                    readonly property var provider: modelData
                    readonly property bool isOk: provider.state === "ok"
                    readonly property var rawWindows: isOk ? root.toArray(provider.windows) : []
                    readonly property var extra: (isOk && provider.extraUsage) ? provider.extraUsage : null
                    readonly property bool hasExtra: extra !== null && (extra.enabled === true || provider.id === "claude")
                    readonly property var grant: (isOk && provider.resetGrant) ? provider.resetGrant : null
                    readonly property var displayWindows: {
                        var list = []
                        for (var i = 0; i < rawWindows.length; i++) {
                            if (hasExtra && rawWindows[i].id === "credits") continue
                            list.push(rawWindows[i])
                        }
                        return list
                    }

                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    Layout.rightMargin: Kirigami.Units.smallSpacing * 1.5
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Separator {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing * 0.5
                        Layout.bottomMargin: Kirigami.Units.smallSpacing * 0.5
                        visible: cmSection.index > 0
                    }

                    // Header row ("Claude Code Usage - PRO   [↻]")
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: cmSection.index === 0 ? Kirigami.Units.smallSpacing * 0.5 : 0
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Heading {
                            text: root.providerHeaderTitle(cmSection.provider)
                            level: 4
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            visible: cmSection.provider.cached === true
                            text: "cached"
                            font: Kirigami.Theme.smallFont
                            color: Kirigami.Theme.disabledTextColor
                        }

                        QQC2.ToolButton {
                            visible: cmSection.index === 0
                            icon.name: "view-refresh"
                            onClicked: root.requestFetch("manual")
                            QQC2.ToolTip.text: "Refresh"
                            QQC2.ToolTip.visible: hovered
                            enabled: !root.fetchInFlight
                            implicitHeight: Kirigami.Units.gridUnit * 1.5
                            implicitWidth: Kirigami.Units.gridUnit * 1.5
                        }
                    }

                    // Notice / error detail
                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: cmSection.isOk && cmSection.provider.notice !== undefined && cmSection.provider.notice !== ""
                        text: cmSection.provider.notice || ""
                        font: Kirigami.Theme.smallFont
                        color: Kirigami.Theme.neutralTextColor
                        wrapMode: Text.WordWrap
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: !cmSection.isOk && cmSection.provider.detail !== ""
                        text: cmSection.provider.detail
                        font: Kirigami.Theme.smallFont
                        color: Kirigami.Theme.negativeTextColor
                        wrapMode: Text.WordWrap
                    }

                    // Segmented pace bars
                    Repeater {
                        model: cmSection.displayWindows

                        UsageBar {
                            required property var modelData
                            Layout.fillWidth: true
                            label: root.windowFullLabel(modelData)
                            percentage: modelData.percent || 0
                            barColor: root.usageColor(modelData.percent || 0)
                            resetTime: root.formatResetTime(modelData.resetsAt)
                            segments: root.windowSegments(modelData)
                            pace: root.paceFraction(modelData.resetsAt, root.windowDurationMs(modelData))
                        }
                    }

                    // Limit reset block (when present on Claude account)
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: cmSection.grant !== null
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Separator { Layout.fillWidth: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "chronometer-reset"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            }
                            QQC2.Label {
                                text: "Limit reset"
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            QQC2.Label {
                                text: cmSection.grant ? (cmSection.grant.resetsLeft + " of " + cmSection.grant.resetsTotal + " left") : ""
                                font: Kirigami.Theme.smallFont
                                color: Kirigami.Theme.disabledTextColor
                            }
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            visible: cmSection.grant !== null && cmSection.grant.endsAt !== ""
                            text: cmSection.grant && cmSection.grant.endsAt
                                ? ("Refills 5-hour and weekly limits · use by " + Qt.formatDate(new Date(cmSection.grant.endsAt), "MMM d"))
                                : "Refills 5-hour and weekly limits"
                            font: Kirigami.Theme.smallFont
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Extra Usage Limit / Monthly Credits block (cyan bar, like claudemeter)
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: cmSection.hasExtra
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Separator { Layout.fillWidth: true }

                        RowLayout {
                            Layout.fillWidth: true
                            QQC2.Label {
                                text: cmSection.extra ? cmSection.extra.label : "Extra Usage Limit"
                                font: Kirigami.Theme.smallFont
                                Layout.fillWidth: true
                            }
                            QQC2.Label {
                                text: cmSection.extra ? cmSection.extra.status : ""
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                color: (cmSection.extra && cmSection.extra.enabled)
                                    ? Kirigami.Theme.positiveTextColor
                                    : Kirigami.Theme.disabledTextColor
                            }
                        }

                        QQC2.Label {
                            visible: cmSection.extra !== null && cmSection.extra.enabled === true
                            text: cmSection.extra ? cmSection.extra.amount : ""
                            font.bold: true
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.activeTextColor
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.smallSpacing * 3
                            radius: height / 2
                            color: Kirigami.Theme.backgroundColor
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                            border.width: 1
                            visible: cmSection.extra !== null && cmSection.extra.enabled === true && (cmSection.extra.percent || 0) > 0

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.min((cmSection.extra ? cmSection.extra.percent : 0) / 100, 1.0)
                                radius: parent.radius
                                color: Kirigami.Theme.activeTextColor

                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // === Style: cards — one soft panel per provider =========================

    Component {
        id: cardList
        ColumnLayout {
            width: parent ? parent.width : 0
            spacing: Kirigami.Units.smallSpacing * 1.6

            Repeater {
                model: root.visibleProviders

                ColumnLayout {
                    id: card
                    required property var modelData
                    readonly property var provider: modelData
                    readonly property bool isOk: provider.state === "ok"
                    readonly property var windows: isOk ? root.toArray(provider.windows) : []

                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing * 1.3

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: cardInner.implicitHeight + Kirigami.Units.smallSpacing * 3
                        radius: Kirigami.Units.smallSpacing * 1.5
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.05)
                        border.width: 1
                        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

                        ColumnLayout {
                            id: cardInner
                            x: Kirigami.Units.smallSpacing * 1.5
                            y: Kirigami.Units.smallSpacing * 1.5
                            width: parent.width - Kirigami.Units.smallSpacing * 3
                            spacing: Kirigami.Units.smallSpacing * 1.1

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing * 1.2

                                ProviderMark {
                                    provider: card.provider
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: root.providerRowLabel(card.provider)
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    visible: card.provider.detail !== ""
                                    text: card.provider.detail
                                    opacity: 0.55
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: Kirigami.Units.gridUnit * 8
                                }

                                QQC2.Label {
                                    visible: card.provider.cached === true
                                    text: "cached"
                                    font.italic: true
                                    opacity: 0.55
                                }
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                visible: card.isOk && card.provider.notice !== undefined && card.provider.notice !== ""
                                text: card.provider.notice || ""
                                color: Kirigami.Theme.neutralTextColor
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                visible: !card.isOk && card.provider.detail !== ""
                                text: card.provider.detail
                                color: Kirigami.Theme.negativeTextColor
                                opacity: 0.7
                                wrapMode: Text.WordWrap
                            }

                            Repeater {
                                model: card.windows

                                UsageRow {
                                    required property var modelData
                                    win: modelData
                                }
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                visible: card.isOk && card.windows.length === 0
                                text: "No usage windows reported"
                                opacity: 0.5
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    // === Style: compact — dense list, no boxes ==============================

    Component {
        id: compactList
        ColumnLayout {
            width: parent ? parent.width : 0
            spacing: Kirigami.Units.smallSpacing * 1.6

            Repeater {
                model: root.visibleProviders

                ColumnLayout {
                    id: group
                    required property var modelData
                    required property int index
                    readonly property var provider: modelData
                    readonly property bool isOk: provider.state === "ok"
                    readonly property var windows: isOk ? root.toArray(provider.windows) : []

                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing * 0.9

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.08)
                        visible: group.index > 0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing * 1.2

                        ProviderMark {
                            provider: group.provider
                            Layout.alignment: Qt.AlignVCenter
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.providerRowLabel(group.provider)
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            visible: group.provider.detail !== ""
                                    && group.provider.state === "ok"
                            text: group.provider.detail
                            opacity: 0.55
                            font.pointSize: Qt.application.font.pointSize * 0.85
                            elide: Text.ElideRight
                            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
                        }

                        Kirigami.Icon {
                            visible: !group.isOk
                            source: "data-warning"
                            color: Kirigami.Theme.negativeTextColor
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                        }

                        QQC2.Label {
                            visible: !group.isOk
                            text: group.provider.detail
                            color: Kirigami.Theme.negativeTextColor
                            opacity: 0.7
                            elide: Text.ElideRight
                            Layout.maximumWidth: Kirigami.Units.gridUnit * 12
                        }
                    }

                    Repeater {
                        model: group.windows

                        UsageRow {
                            required property var modelData
                            win: modelData
                        }
                    }

                    QQC2.Label {
                        visible: group.isOk && group.windows.length === 0
                        text: "No usage windows reported"
                        opacity: 0.5
                        font.pointSize: Qt.application.font.pointSize * 0.85
                    }
                }
            }
        }
    }

    // === Style: grid — small provider tiles in two columns ==================

    Component {
        id: gridStyle
        ColumnLayout {
            width: parent ? parent.width : 0
            spacing: Kirigami.Units.smallSpacing

            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.visibleProviders

                    ColumnLayout {
                        id: tile
                        required property var modelData
                        readonly property var provider: modelData
                        readonly property bool isOk: provider.state === "ok"
                        readonly property var windows: isOk ? root.toArray(provider.windows) : []

                        width: (parent.width - Kirigami.Units.smallSpacing) / 2
                        height: tile.implicitHeight
                        spacing: Kirigami.Units.smallSpacing * 0.8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: tileInner.implicitHeight + Kirigami.Units.smallSpacing * 2
                            radius: Kirigami.Units.smallSpacing * 1.5
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.05)
                            border.width: 1
                            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

                            ColumnLayout {
                                id: tileInner
                                x: Kirigami.Units.smallSpacing
                                y: Kirigami.Units.smallSpacing
                                width: parent.width - Kirigami.Units.smallSpacing * 2
                                spacing: Kirigami.Units.smallSpacing * 0.7

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.smallSpacing

                                    QQC2.Label {
                                        text: root.providerGlyph(tile.provider)
                                        font.bold: true
                                        color: tile.isOk ? Kirigami.Theme.disabledTextColor
                                                     : Kirigami.Theme.negativeTextColor
                                    }

                                    QQC2.Label {
                                        Layout.fillWidth: true
                                        text: root.providerRowLabel(tile.provider)
                                        font.bold: true
                                        font.pointSize: Qt.application.font.pointSize * 0.92
                                        elide: Text.ElideRight
                                    }

                                    Kirigami.Icon {
                                        visible: !tile.isOk
                                        source: "data-warning"
                                        color: Kirigami.Theme.negativeTextColor
                                        implicitWidth: Kirigami.Units.iconSizes.small
                                        implicitHeight: Kirigami.Units.iconSizes.small
                                    }
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    visible: tile.isOk && tile.provider.detail !== ""
                                    text: tile.provider.detail
                                    opacity: 0.55
                                    font.pointSize: Qt.application.font.pointSize * 0.78
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    visible: !tile.isOk
                                    text: tile.provider.detail
                                    color: Kirigami.Theme.negativeTextColor
                                    opacity: 0.7
                                    elide: Text.ElideRight
                                }

                                Repeater {
                                    model: tile.windows

                                    UsageRow {
                                        required property var modelData
                                        win: modelData
                                    }
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    visible: tile.isOk && tile.windows.length === 0
                                    text: "No windows"
                                    opacity: 0.5
                                    font.pointSize: Qt.application.font.pointSize * 0.78
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
