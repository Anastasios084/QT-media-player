#include "AlbumArtProvider.h"
#include <QSize>
#include <Qt>

static const QSize kFixedSize(270, 270);   // <- pick any square you like

AlbumArtProvider::AlbumArtProvider(SongModel *model)
    : QQuickImageProvider(QQuickImageProvider::Image), m_model(model) {}

QImage AlbumArtProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize) {
    const QString idxStr = id.section('?', 0, 0);
    bool ok; int idx = idxStr.toInt(&ok);
    qDebug() << id;
    QImage img = m_model->albumArt(idx);

    if (img.isNull()) {
        if(!img.load(":/img/albumart.jpg")){
            qWarning() << "AlbumArtProvider: failed to load fallback qrc:/img/albumart.jpg";
        }
    }

    /* decide which size to return */
    const QSize target = requestedSize.isValid() ? requestedSize : kFixedSize;

    /* upscale / downscale if necessary */
    if (img.size() != target) {
        img = img.scaled(target,
                         Qt::KeepAspectRatioByExpanding,  // crop the overhang
                         Qt::SmoothTransformation);
    }

    if (size) *size = img.size();
    return img;
}
