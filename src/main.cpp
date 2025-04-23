#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlEngine>
#include "SongModel.h"
#include "AlbumArtProvider.h"
#include "SongFilterProxyModel.h"
#include "PlayerController.h"
#include <QLoggingCategory>

int main(int argc, char *argv[]) {
    // Suppress FFmpeg warnings and info logs:
    QLoggingCategory::setFilterRules(
        "qt.multimedia.ffmpeg.warning=false\n"
        "qt.multimedia.ffmpeg.info=false"
        );

    // Init GUI
    QGuiApplication app(argc, argv);

    // Expose SongModel to QML (uncreatable gives enum access)
    qmlRegisterUncreatableType<SongModel>("MediaPlayer", 1, 0, "SongModel", "Reference only");
    // Expose filter proxy model to QML
    qmlRegisterType<SongFilterProxyModel>("MediaPlayer", 1, 0, "SongFilterProxyModel");

    QQmlApplicationEngine engine;
    SongModel songModel;
    PlayerController controller(&songModel);

    engine.rootContext()->setContextProperty("songModel", &songModel);
    engine.rootContext()->setContextProperty("player", &controller);

    engine.addImageProvider(QLatin1String("albumart"), new AlbumArtProvider(&songModel));

    engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
