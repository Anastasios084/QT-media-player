import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Item {
    width: parent.width; height: 60
    property int songIndex: -1
    signal clicked()
    MouseArea { anchors.fill: parent; onClicked: clicked() }

    RowLayout {
        Layout.fillWidth: true
        Layout.margins: 10
        spacing: 10

        Image {
            source: ":/qml/img/albumart.jpg";
            width: 40; height: 40
            fillMode: Image.PreserveAspectFit
        }
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            Text { text: model.title; elide: Text.ElideRight }
            Text { text: model.artist; font.pixelSize: 12; color: "#666" }
        }
        Label {
            text: formatDuration(model.duration)
            Layout.alignment: Qt.AlignRight
        }
    }
}
