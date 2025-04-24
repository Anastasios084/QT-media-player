#include "AlbumArtProvider.h"
#include <QSize>
#include <Qt>

static const QSize kFixedSize(270, 270);   // <- pick any square you like

// Constructor
AlbumArtProvider::AlbumArtProvider(SongModel *model)
    : QQuickImageProvider(QQuickImageProvider::Image), m_model(model) {}

// Get image by ID
QImage AlbumArtProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize) {
    // get the id but clean the version
    const QString idxStr = id.section('?', 0, 0);
    bool ok; int idx = idxStr.toInt(&ok);
    qDebug() << id;
    QImage img = m_model->albumArt(idx);

    // If no art is found, load the default
    if (img.isNull()) {
        if(!img.load(":/img/albumart.jpg")){
            qWarning() << "AlbumArtProvider: failed to load fallback qrc:/img/albumart.jpg";
        }
    }

    // decide which size to return
    const QSize target = requestedSize.isValid() ? requestedSize : kFixedSize;

    // upscale / downscale if necessary
    if (img.size() != target) {
        img = img.scaled(target,
                         Qt::KeepAspectRatioByExpanding,  // crop the overhang
                         Qt::SmoothTransformation);
    }

    if (img.size() != target) {
        // centre-crop to target rectangle
        const int x = (img.width()  - target.width())  / 2;
        const int y = (img.height() - target.height()) / 2;
        img = img.copy(x, y, target.width(), target.height());
    }

    // check for custom size
    if (size) *size = img.size();
    return img;
}
