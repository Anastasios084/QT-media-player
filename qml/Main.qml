import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Dialogs
import QtQml.Models 2.15
import MediaPlayer 1.0

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
        // selectMultiple: true
        onAccepted: songModel.addSongs(selectedFiles)
    }

    // Our C++ proxy model
    SongFilterProxyModel { id: proxy; sourceModel: songModel }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // Song list
        ListView {
            id: listView
            model: proxy
            clip: true
            Layout.preferredWidth: 250
            delegate: SongDelegate { songIndex: index }
            onCurrentIndexChanged: {
                var src = proxy.sourceIndex(currentIndex)
                player.playIndex(src)
            }
        }

        // Player area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            spacing: 20

            // Album art (large)
            Image {
                id: art
                width: 200; height: 200
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.Center
                // 1) Try the embedded art
                source: "image://albumart/" + player.currentIndex

                // 2) If that fails, fall back to the file in qml/img/albumart.jpg
                onStatusChanged: {
                    if (status === Image.Error) {
                        // Qt.resolvedUrl makes it absolute relative to this QML file
                        art.source = Qt.resolvedUrl("img/albumart.jpg")
                    }
                }
            }

            // Song title
            Text {
                text: player.currentIndex >= 0
                      ? proxy.get(player.currentIndex).title
                      : ""
                font.pixelSize: 20
            }

            // Seek slider
            Slider {
                id: progress
                from: 0; to: player.duration
                value: seeking ? value : player.position

                onPressedChanged: {
                    if (pressed) seeking = true
                    else {
                        seeking = false
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

                Button { text: "<<"; onClicked: player.previous() }
                Button {
                    text: player.playing ? "Pause" : "Play"
                    onClicked: player.playing ? player.pause() : player.play()
                }
                Button { text: "Stop"; onClicked: player.stop() }
                Button { text: ">>"; onClicked: player.next() }
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
