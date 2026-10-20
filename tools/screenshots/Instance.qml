import QtQuick
import QtQuick.Layouts

import "defaults.js" as Defaults

// One widget instance with its own `plasmoid` stub and `root`, so a scene can
// hold several with different settings and data.
Item {
    id: instance

    property var config: ({})
    property string payload: ""
    property bool full: false
    property int thickness: 36
    property string updatedAt: "14:32:05"

    implicitWidth: !loader.item ? 0 : full ? loader.item.implicitWidth : loader.item.Layout.preferredWidth
    implicitHeight: !loader.item ? 0 : full ? loader.item.implicitHeight : thickness

    QtObject {
        id: plasmoid
        property var configuration: Object.assign({}, Defaults.defaults, instance.config)
        property int formFactor: 2
    }

    Root { id: root }

    Loader {
        id: loader
        anchors.fill: parent
        source: Defaults.uiDir + (instance.full ? "FullRepresentation.qml" : "CompactRepresentation.qml")
    }

    Component.onCompleted: {
        root.parseUsageData(instance.payload)
        var parts = instance.updatedAt.split(":")
        var stamp = new Date()
        stamp.setHours(+parts[0], +parts[1], +parts[2])
        root.lastUpdated = stamp
    }
}
