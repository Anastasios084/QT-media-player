import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Dialogs
import QtQml.Models 2.15
import MediaPlayer 1.0
import QtQuick.Effects
ApplicationWindow {
    id: root
    visible: true
    width: 1200; height: 600
    title: "MediaPlayer"

    // Smooth transition whenever the C++ property changes
    property color topTint: player ? player.themeColor : "#18230F"

    // Background with gradient
    Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    id: topStop
                    position: 0.0
                    color: root.topTint                  // bind to property
                    Behavior on color {                 // animate the change
                        ColorAnimation { duration: 400 }
                    }
                }
                GradientStop { position: 1.0; color: "#000000" }
            }
        }
    // color: "#18230F"
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
        filterString:    search.text        // already there
        filterMode:      SongFilterProxyModel.TitleOrArtist   // new (default)
    }

    // ---- HEADER BAR ------------------------------------------------------
    header: ToolBar {
        id:header
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10

            ToolButton {               // toggle playlist drawer
                text: "Loaded Songs \u2630"        // ≡
                onClicked: playlistDrawer.open()
            }

            ToolButton {               // pick music folder
                text: "Add from \ud83d\udcc1" // 📁
                onClicked: folderDialog.open()
            }
            // ListView {
            //     model: proxy
            //     delegate: Text { text: title + " — " + artist }
            // }
            TextField {                 // seach functionality
                id: search
                placeholderText: "Search..."
                onTextChanged: {proxy.filterString = text; playlistDrawer.open();}
            }
            ComboBox {
                    id: fieldChooser
                    model: [
                        { text: qsTr("Title"),  mode: SongFilterProxyModel.TitleOnly     },
                        { text: qsTr("Artist"), mode: SongFilterProxyModel.ArtistOnly    },
                        { text: qsTr("Both"),   mode: SongFilterProxyModel.TitleOrArtist }
                    ]
                    textRole: "text"
                    onActivated: function(index) {
                        proxy.filterMode = model[index].mode
                    }
                    // keep the proxy up-to-date if user reopens the page:
                    Component.onCompleted: proxy.filterMode = model[currentIndex].mode
                    width: 100
                }

            Button {                   // pick individual files (old behaviour)
                text: "Add Song"
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
        onAccepted: songModel.addFolder(folderDialog.selectedFolder)
    }

    // ---- PLAYLIST DRAWER -------------------------------------------------
    Drawer {
        id: playlistDrawer
        edge: Qt.LeftEdge
        width: 0.30 * parent.width
        height: root.height - header.height
        y: header.height

        background: Rectangle {
            color: "#2C2C2C"
            opacity: 0.7
        }

        onOpened: {search.forceActiveFocus()}
        onClosed: {search.focus = false}

        ListView {
            id: playlistView
            anchors.fill: parent
            clip: true
            model: proxy
            cacheBuffer: 100

            delegate: Item {
                width: playlistView.width
                height: 48
                property int srcRow: proxy.sourceIndex(index)

                // Alternating row color
                Rectangle {
                    anchors.fill: parent
                    color: player && player.currentIndex === srcRow ? "#27391C"
                          : (index % 2 === 0 ? "#040f00" : "#0F0F0F")
                }

                Text {
                    text: model.title + " - " + model.artist
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

            Text{
                text: "Empty..."
                font.pixelSize: 30
                color: "#255F38"
                visible: player ? player.currentIndex === -1 : true
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

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
        Item{
            width: 270; height: 270 // this is from ksize, could be given
            Layout.alignment: Qt.AlignHCenter
            Image {
                id: art
                fillMode: Image.PreserveAspectFit

                source: player && player.currentIndex >= 0
                            ? "image://albumart/" + player.currentIndex + "?v=" + player.artVersion
                            : "qrc:/img/albumart.jpg"
                onStatusChanged: if (status === Image.Error)
                                     art.source = Qt.resolvedUrl("img/albumart.jpg")
                cache: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: art

                source: art
                shadowBlur: 1.5
                shadowEnabled: true
                shadowColor: "black"
                shadowVerticalOffset: 0
                shadowHorizontalOffset: 4

            }
        }



        // Title text
        Text {
            text: player && player.currentIndex >= 0 ? proxy.get(player.currentIndex).title : "No Song Loaded…"
            color: "#ECF0F1"
            font.pixelSize: 30
            Layout.alignment: Qt.AlignHCenter
        }

        // Seek slider
        Slider {
            id: progress
            Layout.fillWidth: true
            from: 0; to: player ? player.duration : "0:00"
            value: seeking ? progress.value : (player ? player.position : 0)
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
                    color: root.topTint

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
            Text { text: formatDuration(player ? player.position : "0:00"); color: "#ECF0F1"; font.pixelSize: 15}
            Text { text: " : "; color: "#ECF0F1"; font.pixelSize: 15}
            Text { text: formatDuration(player ? player.duration : "0:00"); color: "#ECF0F1"; font.pixelSize: 15 }
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
                text: player && player.playing ? "⏸ Pause" : "▶ Play"
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

                        Label { text: "Volume 🔉" ; color: "#ECF0F1"}
                        Slider {
                            id: volumeSlider
                            from: 0; to: 100
                            property real sliderValue: player.volume
                            value: sliderValue
                            onValueChanged: {
                                sliderValue = value
                                player.volume = value
                            }
                            background: Rectangle {
                                    x: volumeSlider.leftPadding
                                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 200
                                    implicitHeight: 4
                                    width: volumeSlider.availableWidth
                                    height: implicitHeight
                                    radius: 2
                                    color: root.topTint

                                    Rectangle {
                                                width: volumeSlider.visualPosition * parent.width
                                                height: parent.height
                                                color: "#A4B465"
                                                radius: 2
                                            }
                            }
                        }
                    }
    }
}
