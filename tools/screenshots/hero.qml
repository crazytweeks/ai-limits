import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import "demo.js" as Demo

// A Plasma 6 desktop corner: the 6-provider widget in the panel with its
// Claudemeter popup open above it.
Shot {
    id: shot

    readonly property real now: Date.now()

    Item {
        id: scene
        width: 980
        height: 760
        clip: true

        Image {
            anchors.fill: parent
            source: "file:///usr/share/wallpapers/Next/contents/" + (shot.dark ? "images_dark" : "images") + "/5120x2880.png"
            sourceSize.width: 2560
            fillMode: Image.PreserveAspectCrop
            horizontalAlignment: Image.AlignRight
            smooth: true
        }

        Panel {
            id: panel
            x: -24
            width: scene.width + 24 - 10
            y: scene.height - height - 10

            Kirigami.Icon { source: "start-here-kde"; Layout.preferredWidth: 30; Layout.preferredHeight: 30; Layout.leftMargin: 28 }
            Repeater {
                model: ["system-file-manager", "internet-web-browser", "utilities-terminal", "kate"]
                Kirigami.Icon { source: modelData; Layout.preferredWidth: 30; Layout.preferredHeight: 30; Layout.leftMargin: 6 }
            }
            Item { Layout.fillWidth: true }

            Item {
                id: mainApplet
                Layout.preferredWidth: appInst.implicitWidth + 10
                Layout.preferredHeight: 38
                Layout.leftMargin: 4

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                }
                Instance {
                    id: appInst
                    anchors.centerIn: parent
                    width: implicitWidth
                    height: implicitHeight
                    config: ({ panelStyle: "dual_rings", gaugeLabel: "percent", panelLabelMode: "plan" })
                    payload: Demo.allProviders(shot.now)
                }
            }

            Repeater {
                model: ["klipper-symbolic", "network-wireless-100", "audio-volume-high", "battery-100"]
                Kirigami.Icon { source: modelData; Layout.preferredWidth: 22; Layout.preferredHeight: 22; Layout.leftMargin: 6 }
            }

            ColumnLayout {
                Layout.leftMargin: 12
                Layout.rightMargin: 6
                spacing: 0
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "14:32"
                    color: Kirigami.Theme.textColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pixelSize: 15
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "20/10/2026"
                    color: Kirigami.Theme.textColor
                    font.family: Kirigami.Theme.defaultFont.family
                    font.pixelSize: 11
                }
            }
        }

        PopupFrame {
            id: popup
            width: implicitWidth
            height: implicitHeight
            y: panel.y - height - 8
            x: {
                panel.width; mainApplet.x
                var centre = mainApplet.mapToItem(scene, mainApplet.width / 2, 0).x
                return Math.min(scene.width - width - 16, Math.max(16, centre - width / 2))
            }
            config: ({ popupStyle: "claudemeter", showPace: true, useGradient: true })
            payload: Demo.heroPopup(shot.now)
        }
    }
}
