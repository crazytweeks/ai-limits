import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import org.kde.kirigami as Kirigami

import "demo.js" as Demo

// Showcase of panel styles and 4-stop color themes on blurred Next wallpaper.
Shot {
    id: shot

    readonly property real now: Date.now()
    readonly property string data3: Demo.tileProviders(now)
    readonly property string data6: Demo.allProviders(now)

    component Tile: ColumnLayout {
        id: tile
        default property alias content: strip.data
        property string caption
        spacing: 8
        Layout.alignment: Qt.AlignTop

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.max(strip.implicitWidth + 24, 150)
            implicitHeight: 44
            radius: 8
            color: Kirigami.Theme.backgroundColor
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
            border.width: 1

            RowLayout {
                id: strip
                anchors.centerIn: parent
                spacing: 10
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 220
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: tile.caption
            color: "white"
            font.family: Kirigami.Theme.defaultFont.family
            font.pixelSize: 12
        }
    }

    Item {
        id: scene
        width: grid.implicitWidth + 64
        height: grid.implicitHeight + 64
        clip: true

        Image {
            id: wallpaper
            anchors.fill: parent
            source: "file:///usr/share/wallpapers/Next/contents/" + (shot.dark ? "images_dark" : "images") + "/5120x2880.png"
            sourceSize.width: 1920
            fillMode: Image.PreserveAspectCrop
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wallpaper
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            brightness: shot.dark ? -0.25 : -0.1
        }

        GridLayout {
            id: grid
            anchors.centerIn: parent
            columns: 3
            columnSpacing: 24
            rowSpacing: 28

            Tile {
                caption: "Dual Rings: concentric 5-hour & weekly limits with plan badges"
                Instance { payload: shot.data3; config: ({ panelStyle: "dual_rings", gaugeLabel: "percent", panelLabelMode: "plan" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
            }
            Tile {
                caption: "Thermometer Bars: rounded pill bars for every window"
                Instance { payload: shot.data3; config: ({ panelStyle: "bars", panelLabelMode: "plan" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
            }
            Tile {
                caption: "Single Gauge: time to reset or percentage inside"
                Instance { payload: shot.data3; config: ({ panelStyle: "gauge", gaugeLabel: "time", panelLabelMode: "glyph" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
            }
            Tile {
                caption: "Glow Chips & Glyph Rings: all 6 AI providers at a glance"
                Instance { payload: shot.data6; config: ({ panelStyle: "glow" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
                Instance { payload: shot.data6; config: ({ panelStyle: "rings" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
            }
            Tile {
                caption: "Capsule Strip & Severity Dots: ultra-compact panel footprints"
                Instance { payload: shot.data6; config: ({ panelStyle: "capsule" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
                Instance { payload: shot.data6; config: ({ panelStyle: "dots" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
            }
            Tile {
                caption: "4-Stop Gradient Themes: Sky Blue, Emerald & Amethyst"
                Instance { payload: shot.data3; config: ({ panelStyle: "bars", panelLabelMode: "none", normalColor: "#3DAEE9", midColor: "#56C8D8" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
                Instance { payload: shot.data3; config: ({ panelStyle: "dual_rings", panelLabelMode: "none", normalColor: "#27AE60", midColor: "#78C850" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
                Instance { payload: shot.data3; config: ({ panelStyle: "dual_rings", panelLabelMode: "none", normalColor: "#9B59B6", midColor: "#D3689F" }); Layout.preferredWidth: implicitWidth; Layout.preferredHeight: implicitHeight }
            }
        }
    }
}
