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

    // Setup QML engine and core data/controller objects
    QQmlApplicationEngine engine;
    SongModel songModel;
    PlayerController controller(&songModel);

    // Expose objects to QML
    engine.rootContext()->setContextProperty("songModel", &songModel);
    engine.rootContext()->setContextProperty("player", &controller);

    // Provide album art images to QML using the "albumart" image provider
    engine.addImageProvider(QLatin1String("albumart"), new AlbumArtProvider(&songModel));

    // Load the main QML UI from the application resources
    engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));

    // If QML failed to load any root objects (e.g., file not found), exit with error
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
