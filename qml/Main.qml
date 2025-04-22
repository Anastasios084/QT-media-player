import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Dialogs
import QtQml.Models 2.15
import MediaPlayer 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1200; height: 600
    title: "MediaPlayer"
    color: "#18230F"
    property bool seeking: false   // guard against binding loops in the progress slider

    // ---- JS helper -------------------------------------------------------
    function formatDuration(ms) {
        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        s %= 60
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    // ---- MODELS ----------------------------------------------------------
    SongFilterProxyModel {
        id: proxy
        sourceModel: songModel       // from C++
    }

    // ---- HEADER BAR ------------------------------------------------------
    header: ToolBar {
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10

            ToolButton {               // toggle playlist drawer
                text: "\u2630"        // ≡
                onClicked: playlistDrawer.open()
            }

            ToolButton {               // pick music folder
                text: "\ud83d\udcc1" // 📁
                onClicked: folderDialog.open()
            }

            TextField {
                id: searchField
                placeholderText: "Search…"
                Layout.fillWidth: true
                onTextChanged: proxy.filterString = text
            }

            ComboBox {
                model: ["Title", "Artist"]
                onCurrentIndexChanged: proxy.sort(0, Qt.AscendingOrder)
            }

            Button {                   // pick individual files (old behaviour)
                text: "Add Songs"
                onClicked: fileDialog.open()
            }
        }
    }

    // ---- FILE + FOLDER DIALOGS ------------------------------------------
    FileDialog {                      // add individual tracks
        id: fileDialog
        title: "Select Audio Files"
        nameFilters: ["Audio (*.mp3 *.m4a *.flac *.wav *.ogg)"]
        onAccepted: songModel.addSongs(selectedFiles)
    }

    FolderDialog {                      // add entire folder
        id: folderDialog
        title: "Select Music Folder"
        // selectFolder: true
        onAccepted: songModel.addFolder(folderDialog.selectedFolder)
    }

    // ---- PLAYLIST DRAWER -------------------------------------------------
    Drawer {
        id: playlistDrawer
        edge: Qt.LeftEdge
        width: 0.30 * parent.width
        height: root.height

        ListView {
            id: playlistView
            anchors.fill: parent
            clip: true
            model: proxy

            delegate: Item {
                width: parent.width
                height: 48
                property int srcRow: proxy.sourceIndex(index)

                Rectangle {            // highlight current track
                    anchors.fill: parent
                    color: player.currentIndex === srcRow ? "#33007acc" : "transparent"
                }

                Text {
                    text: model.title
                    color: "#ECF0F1"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    elide: Text.ElideRight
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        player.playIndex(srcRow)
                        playlistDrawer.close()
                    }
                }
            }
        }
    }

    // ---- MAIN CONTENT ----------------------------------------------------
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        // Album art
        Image {
            id: art
            width: 40; height: 40
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignHCenter
            source: player.currentIndex >= 0
                        ? "image://albumart/" + player.currentIndex + "?v=" + player.artVersion
                        : "qrc:/img/albumart.jpg"
            onStatusChanged: if (status === Image.Error)
                                 art.source = Qt.resolvedUrl("img/albumart.jpg")
            cache: false
        }

        // Title text
        Text {
            text: player.currentIndex >= 0 ? proxy.get(player.currentIndex).title : "No Song Loaded…"
            color: "#ECF0F1"
            font.pixelSize: 30
            Layout.alignment: Qt.AlignHCenter
        }

        // Seek slider
        Slider {
            id: progress
            Layout.fillWidth: true
            from: 0; to: player.duration
            value: seeking ? progress.value : player.position
            onPressedChanged: seeking = pressed
            onValueChanged: if (pressed) player.setPosition(value)
        }

        // Time stamps
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Text { text: formatDuration(player.position); color: "#ECF0F1" }
            Text { text: formatDuration(player.duration); color: "#ECF0F1" }
        }

        // Playback controls
        RowLayout {
            spacing: 20
            Layout.alignment: Qt.AlignHCenter
            Button { text: "⏮"; onClicked: player.previous() ;}
            Button {
                text: player.playing ? "⏸ Pause" : "▶ Play"
                onClicked: player.playing ? player.pause() : player.playIndex(player.currentIndex)
            }
            Button { text: "■ Stop"; onClicked: player.stop() }
            Button { text: "⏭"; onClicked: player.next() }
        }

                    // Volume slider
                    RowLayout {
                        spacing: 10
                        Layout.alignment: Qt.AlignHCenter

                        Label { text: "Volume" ; color: "#ECF0F1"}
                        Slider {
                            id: volumeSlider
                            from: 0; to: 100
                            property real sliderValue: player.volume
                            value: sliderValue
                            onValueChanged: {
                                sliderValue = value
                                player.volume = value
                            }
                        }
                    }
    }
}


// import QtQuick 2.15
// import QtQuick.Controls 2.15
// import QtQuick.Layouts 1.3
// import QtQuick.Dialogs
// import QtQml.Models 2.15
// import MediaPlayer 1.0
// // import Qt.labs.platform 1.1

// ApplicationWindow {
//     visible: true
//     width: 800; height: 600
//     title: "MediaPlayer"

//     // Used to guard against binding‐loop in the progress slider
//     property bool seeking: false

//     // Simple JS helper to format mm:ss
//     function formatDuration(ms) {
//         var s = Math.floor(ms / 1000)
//         var m = Math.floor(s / 60)
//         s %= 60
//         return m + ":" + (s < 10 ? "0" + s : s)
//     }

//     header: ToolBar {
//         RowLayout {
//             Layout.fillWidth: true
//             Layout.margins: 10
//             spacing: 10

//             TextField {
//                 id: searchField
//                 placeholderText: "Search..."
//                 Layout.fillWidth: true
//                 onTextChanged: proxy.filterString = text
//             }

//             ComboBox {
//                 model: ["Title","Artist"]
//                 onCurrentIndexChanged: proxy.sort(0, Qt.AscendingOrder)
//             }

//             Button { text: "Add Songs"; onClicked: fileDialog.open() }
//         }
//     }

//     FileDialog {
//         id: fileDialog
//         title: "Select Audio Files"
//         nameFilters: ["Audio (*.mp3 *.wav)"]
//         onAccepted: {
//             songModel.addSongs(selectedFiles)
//         }
//     }

//     // Our C++ proxy model
//     SongFilterProxyModel { id: proxy; sourceModel: songModel }

//     SplitView {
//         anchors.fill: parent
//         orientation: Qt.Horizontal

//         // // Song list (left pane)
//         // ListView {
//         //     id: listView
//         //     model: songModel
//         //     clip: true
//         //     Layout.minimumWidth: 200
//         //     Layout.fillWidth: true
//         //     Layout.fillHeight: true

//         //     delegate: SongDelegate {
//         //         songIndex: index
//         //         onClicked: {
//         //             listView.currentIndex = index
//         //             player.playIndex(index)
//         //         }
//         //     }

//         //     onCurrentIndexChanged: {
//         //         if (currentIndex >= 0)
//         //             player.playIndex(currentIndex)
//         //     }
//         // }

//         // Player area (right pane)
//         ColumnLayout {
//             Layout.fillWidth: true
//             Layout.fillHeight: true
//             anchors.centerIn: parent
//             Layout.margins: 20
//             spacing: 20

//             // Album art, centered
//             Image {
//                 id: art
//                 width: 40; height: 40
//                 fillMode: Image.PreserveAspectFit
//                 // Center this item in the ColumnLayout
//                 Layout.alignment: Qt.AlignHCenter

//                 source: player.currentIndex >= 0
//                             ? "image://albumart/" + player.currentIndex + "?v=" + player.artVersion // pretty hacky way to do it
//                             : "qrc:/img/albumart.jpg"
//                 onStatusChanged: {
//                     if (status === Image.Error)
//                         art.source = Qt.resolvedUrl("img/albumart.jpg")
//                 }
//                 cache: false
//             }

//             // Song title, centered
//             Text {
//                 text: player.currentIndex >= 0
//                       ? proxy.get(player.currentIndex).title
//                       : "No Song Loaded..."
//                 font.pixelSize: 30
//                 // Center this item in the ColumnLayout
//                 Layout.alignment: Qt.AlignHCenter
//             }

//             // Seek slider (now stretches full width)
//             Slider {
//                 id: progress
//                 from: 0; to: player.duration
//                 // Make slider fill the ColumnLayout width
//                 Layout.fillWidth: true

//                 // Two‑way bind
//                 value: seeking ? progress.value : player.position

//                 // Handle handle press/release
//                 onPressedChanged: {
//                     seeking = progress.pressed
//                 }
//                 // Handle clicks and drags anywhere on the bar
//                 onValueChanged: {
//                     if (progress.pressed && !seeking) {
//                         // clicked on track
//                         player.setPosition(value)
//                     } else if (progress.pressed) {
//                         // dragging handle
//                         player.setPosition(value)
//                     }
//                 }
//             }

//             // Timestamps
//             RowLayout {
//                 spacing: 10
//                 Layout.alignment: Qt.AlignHCenter
//                 Text { text: formatDuration(player.position) }
//                 Text { text: formatDuration(player.duration) }
//             }

//             // Playback controls
//             RowLayout {
//                 spacing: 20
//                 Layout.alignment: Qt.AlignHCenter

//                 Button { text: "⏮"; onClicked: player.previous() }
//                 Button {
//                     text: player.playing ? "⏸ Pause" : "▶ Play"
//                     onClicked: {
//                         player.playing ? player.pause() : player.playIndex(player.currentIndex)
//                     }
//                 }
//                 Button { text: "■ Stop"; onClicked: player.stop() }
//                 Button { text: "⏭"; onClicked: player.next() }
//             }

//             // Volume slider
//             RowLayout {
//                 spacing: 10
//                 Layout.alignment: Qt.AlignHCenter

//                 Label { text: "Volume" }
//                 Slider {
//                     id: volumeSlider
//                     from: 0; to: 100
//                     property real sliderValue: player.volume
//                     value: sliderValue
//                     onValueChanged: {
//                         sliderValue = value
//                         player.volume = value
//                     }
//                 }
//             }
//         }
//     }
// }
