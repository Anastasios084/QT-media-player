QT += qml quick quickcontrols2 multimedia
CONFIG += c++17

SOURCES += \
    src/main.cpp \
    src/SongModel.cpp \
    src/AlbumArtProvider.cpp \
    src/SongFilterProxyModel.cpp \
    src/PlayerController.cpp

HEADERS += \
    src/SongModel.h \
    src/AlbumArtProvider.h \
    src/SongFilterProxyModel.h \
    src/PlayerController.h

RESOURCES += resources.qrc
