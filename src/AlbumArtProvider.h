#ifndef ALBUMARTPROVIDER_H
#define ALBUMARTPROVIDER_H
#include <QQuickImageProvider>
#include "SongModel.h"

class AlbumArtProvider : public QQuickImageProvider {
public:
    explicit AlbumArtProvider(SongModel *model);
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
private:
    SongModel *m_model;
};

#endif
