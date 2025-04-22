import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Dialogs
import QtQml.Models 2.15
import MediaPlayer 1.0
// import Qt.labs.platform 1.1

ApplicationWindow {
    visible: true
    width: 800; height: 600
    title: "MediaPlayer"

    // Used to guard against binding‐loop in the progress slider
    property bool seeking: false

    // Simple JS helper to format mm:ss
    function formatDuration(ms) {
        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        s %= 60
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    header: ToolBar {
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10

            TextField {
                id: searchField
                placeholderText: "Search..."
                Layout.fillWidth: true
                onTextChanged: proxy.filterString = text
            }

            ComboBox {
                model: ["Title","Artist"]
                onCurrentIndexChanged: proxy.sort(0, Qt.AscendingOrder)
            }

            Button { text: "Add Songs"; onClicked: fileDialog.open() }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Select Audio Files"
        nameFilters: ["Audio (*.mp3 *.wav)"]
        onAccepted: {
            songModel.addSongs(selectedFiles)
        }
    }

    // Our C++ proxy model
    SongFilterProxyModel { id: proxy; sourceModel: songModel }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // // Song list (left pane)
        // ListView {
        //     id: listView
        //     model: songModel
        //     clip: true
        //     Layout.minimumWidth: 200
        //     Layout.fillWidth: true
        //     Layout.fillHeight: true

        //     delegate: SongDelegate {
        //         songIndex: index
        //         onClicked: {
        //             listView.currentIndex = index
        //             player.playIndex(index)
        //         }
        //     }

        //     onCurrentIndexChanged: {
        //         if (currentIndex >= 0)
        //             player.playIndex(currentIndex)
        //     }
        // }

        // Player area (right pane)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            anchors.centerIn: parent
            Layout.margins: 20
            spacing: 20

            // Album art, centered
            Image {
                id: art
                width: 40; height: 40
                fillMode: Image.PreserveAspectFit
                // Center this item in the ColumnLayout
                Layout.alignment: Qt.AlignHCenter

                source: player.currentIndex >= 0
                            ? "image://albumart/" + player.currentIndex + "?v=" + player.artVersion // pretty hacky way to do it
                            : "qrc:/img/albumart.jpg"
                onStatusChanged: {
                    if (status === Image.Error)
                        art.source = Qt.resolvedUrl("img/albumart.jpg")
                }
                cache: false
            }

            // Song title, centered
            Text {
                text: player.currentIndex >= 0
                      ? proxy.get(player.currentIndex).title
                      : "No Song Loaded..."
                font.pixelSize: 30
                // Center this item in the ColumnLayout
                Layout.alignment: Qt.AlignHCenter
            }

            // Seek slider (now stretches full width)
            Slider {
                id: progress
                from: 0; to: player.duration
                // Make slider fill the ColumnLayout width
                Layout.fillWidth: true

                // Two‑way bind
                value: seeking ? progress.value : player.position

                // Handle handle press/release
                onPressedChanged: {
                    seeking = progress.pressed
                }
                // Handle clicks and drags anywhere on the bar
                onValueChanged: {
                    if (progress.pressed && !seeking) {
                        // clicked on track
                        player.setPosition(value)
                    } else if (progress.pressed) {
                        // dragging handle
                        player.setPosition(value)
                    }
                }
            }

            // Timestamps
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignHCenter
                Text { text: formatDuration(player.position) }
                Text { text: formatDuration(player.duration) }
            }

            // Playback controls
            RowLayout {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter

                Button { text: "⏮"; onClicked: player.previous() }
                Button {
                    text: player.playing ? "⏸ Pause" : "▶ Play"
                    onClicked: {
                        player.playing ? player.pause() : player.playIndex(player.currentIndex)
                    }
                }
                Button { text: "■ Stop"; onClicked: player.stop() }
                Button { text: "⏭"; onClicked: player.next() }
            }

            // Volume slider
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignHCenter

                Label { text: "Volume" }
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
}
