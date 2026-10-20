import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import org.kde.kirigami as Kirigami

import "demo.js" as Demo

// Side-by-side showcase of the popup layouts & themes on blurred wallpaper.
Shot {
    id: shot

    readonly property real now: Date.now()
    readonly property string dataHero: Demo.heroPopup(now)
    readonly property string dataAll: Demo.allProviders(now)

    component ColumnTile: ColumnLayout {
        id: ctile
        default property alias content: holder.data
        property string caption
        spacing: 12
        Layout.alignment: Qt.AlignTop

        Item {
            id: holder
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: ctile.caption
            color: "white"
            font.family: Kirigami.Theme.defaultFont.family
            font.pixelSize: 14
            font.bold: true
        }
    }

    Item {
        id: scene
        width: row.implicitWidth + 80
        height: row.implicitHeight + 80
        clip: true

        Image {
            id: wallpaper
            anchors.fill: parent
            source: "file:///usr/share/wallpapers/Next/contents/" + (shot.dark ? "images_dark" : "images") + "/5120x2880.png"
            sourceSize.width: 2560
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

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 28

            ColumnTile {
                caption: "Claudemeter (Warm Gradient)"
                PopupFrame {
                    width: implicitWidth
                    height: implicitHeight
                    config: ({ popupStyle: "claudemeter", showPace: true, useGradient: true })
                    payload: shot.dataHero
                }
            }

            ColumnTile {
                caption: "Cards (Sky Blue Theme)"
                PopupFrame {
                    width: implicitWidth
                    height: implicitHeight
                    config: ({ popupStyle: "cards", normalColor: "#3DAEE9", midColor: "#56C8D8", warningColor: "#E5C07B", criticalColor: "#E06C75" })
                    payload: shot.dataAll
                }
            }

            ColumnTile {
                caption: "Grid Tiles (Amethyst Theme)"
                PopupFrame {
                    width: implicitWidth
                    height: implicitHeight
                    config: ({ popupStyle: "grid", normalColor: "#9B59B6", midColor: "#D3689F", warningColor: "#E5C07B", criticalColor: "#E06C75" })
                    payload: shot.dataAll
                }
            }
        }
    }
}
