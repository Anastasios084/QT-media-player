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
        id:header
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10

            ToolButton {               // toggle playlist drawer
                text: "songs \u2630"        // ≡
                onClicked: playlistDrawer.open()
            }

            ToolButton {               // pick music folder
                text: "\ud83d\udcc1" // 📁
                onClicked: folderDialog.open()
            }

            // NOPE, not today
            // TextField {
            //     id: searchField
            //     placeholderText: "Search…"
            //     Layout.fillWidth: true
            //     onTextChanged: proxy.filterString = text
            // }

            // ComboBox {
            //     model: ["Title", "Artist"]
            //     onCurrentIndexChanged: proxy.sort(0, Qt.AscendingOrder)
            // }

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
        height: root.height-header.height
        y: header.height

        ListView {
            id: playlistView
            anchors.fill: parent
            clip: true
            model: proxy

            delegate: Item {
                width: root.width
                height: 48
                property int srcRow: proxy.sourceIndex(index)

                Rectangle {            // highlight current track
                    anchors.fill: parent
                    color: player.currentIndex === srcRow ? "#27391C" : "transparent"
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

            background: Rectangle {
                    x: progress.leftPadding
                    y: progress.topPadding + progress.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 4
                    width: progress.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: "#3F4F44"

                    Rectangle {
                                width: progress.visualPosition * parent.width
                                height: parent.height
                                color: "#A4B465"
                                radius: 2
                            }
            }

        }

        // Time stamps
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Text { text: formatDuration(player.position); color: "#ECF0F1" }
            Text { text: " : "; color: "#ECF0F1"}
            Text { text: formatDuration(player.duration); color: "#ECF0F1" }
        }

        // Playback controls
        RowLayout {
            spacing: 20
            Layout.alignment: Qt.AlignHCenter
            Button { text: "⏮"; onClicked: player.previous()}
            Button {
                id: play
                width: 100
                height: 100
                text: player.playing ? "⏸ Pause" : "▶ Play"
                font.pixelSize: 18
                onClicked: player.playing ? player.pause() : player.playIndex(player.currentIndex)
                // contentItem: Text {
                //     text: player.playing ? "⏸" : "▶"
                //     font.pixelSize: 30
                //     color: play.down ? "#255F38" : "#ECF0F1"
                //     horizontalAlignment: Text.AlignHCenter
                //     verticalAlignment: Text.AlignVCenter
                //     anchors.fill: parent
                // }

            }
            Button { text: "■ Stop"; onClicked: player.stop();font.pixelSize: 18}
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
