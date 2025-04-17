cmake_minimum_required(VERSION 3.14)
project(MediaPlayer)

set(CMAKE_CXX_STANDARD 17)
find_package(Qt6 REQUIRED COMPONENTS Quick Controls2 Multimedia)

qt_standard_project_setup()

qt_add_executable(MediaPlayer
    src/main.cpp
    src/SongModel.h src/SongModel.cpp
    src/AlbumArtProvider.h src/AlbumArtProvider.cpp
    src/SongFilterProxyModel.h src/SongFilterProxyModel.cpp
    src/PlayerController.h src/PlayerController.cpp
    resources.qrc
)

qt_add_qml_module(MediaPlayer
    URI MediaPlayer
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/SongDelegate.qml
)

target_link_libraries(MediaPlayer
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
)

install(TARGETS MediaPlayer RUNTIME DESTINATION bin)
