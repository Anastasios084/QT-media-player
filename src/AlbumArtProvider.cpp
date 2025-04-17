#include "AlbumArtProvider.h"
#include <QSize>
#include <Qt>

AlbumArtProvider::AlbumArtProvider(SongModel *model)
    : QQuickImageProvider(QQuickImageProvider::Image), m_model(model) {}

QImage AlbumArtProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize) {
    bool ok; int idx = id.toInt(&ok);
    QImage img = m_model->albumArt(idx);
    // Provide a transparent placeholder if no art
    if (img.isNull()) {
        if(!img.load(":/albumart.jpg")){
            qWarning() << "AlbumArtProvider: failed to load fallback :/defaultCover.jpg";
        }
    }
    if (size) *size = img.size();
    return img;
}
