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

        // Image {
        //         source: songIndex >= 0
        //             ? "image://albumart/" + songIndex
        //             : "/img/albumart.jpg"
        //     width: 10; height: 10
        //     fillMode: Image.PreserveAspectFit
        // }
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


// import QtQuick 2.15
// import QtQuick.Controls 2.15
// import QtQuick.Layouts 1.3

// Item {
//     // Use the ListView’s width if available, else 0
//     width: ListView.view ? ListView.view.width : 0
//     height: 60

//     property int songIndex: -1
//     signal clicked()

//     MouseArea {
//         anchors.fill: parent
//         onClicked: clicked()
//     }

//     RowLayout {
//         anchors.fill: parent
//         Layout.margins: 10
//         spacing: 10
//         Layout.alignment: Qt.AlignVCenter

//         // Album thumb
//         Image {
//             id: thumb
//             width: 40; height: 40
//             fillMode: Image.PreserveAspectFit
//             Layout.alignment: Qt.AlignVCenter

//             asynchronous: true
//             cache: false

//             source: songIndex >= 0
//                     ? "image://albumart/" + songIndex
//                     : ":/img/albumart.jpg"

//             onStatusChanged: {
//                 if (status === Image.Error)
//                     thumb.source = ":/img/albumart.jpg"
//             }
//         }

//         // Title & artist
//         ColumnLayout {
//             spacing: 4
//             Layout.fillWidth: true
//             Layout.alignment: Qt.AlignVCenter

//             Text {
//                 text: model.title
//                 elide: Text.ElideRight
//             }
//             Text {
//                 text: model.artist
//                 font.pixelSize: 12
//                 color: "#666"
//             }
//         }

//         // Duration formatted mm:ss
//         Label {
//             text: {
//                 var totalSec = Math.floor(model.duration / 1000);
//                 var m = Math.floor(totalSec / 60);
//                 var s = totalSec % 60;
//                 return m + ":" + (s < 10 ? "0" + s : s);
//             }
//             Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
//         }
//     }
// }
