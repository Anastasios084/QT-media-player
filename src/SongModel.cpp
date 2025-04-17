#include "SongModel.h"
#include <QFileInfo>
#include <QMediaPlayer>
#include <QEventLoop>
#include <QUrl>
#include <QMediaMetaData>

SongModel::SongModel(QObject *parent)
    : QAbstractListModel(parent) {}

int SongModel::rowCount(const QModelIndex &) const {
    return m_songs.size();
}

QVariant SongModel::data(const QModelIndex &idx, int role) const {
    if (!idx.isValid() || idx.row() >= m_songs.size())
        return {};
    const Song &s = m_songs.at(idx.row());
    switch (role) {
    case TitleRole:    return s.title;
    case ArtistRole:   return s.artist;
    case DurationRole: return s.duration;
    case FilePathRole: return s.filePath;
    default:           return {};
    }
}

QHash<int, QByteArray> SongModel::roleNames() const {
    return {{TitleRole, "title"},
            {ArtistRole, "artist"},
            {DurationRole, "duration"},
            {FilePathRole, "filePath"}};
}

void SongModel::addSongs(const QStringList &files) {
    beginResetModel();
    m_songs.clear();
    for (const QString &file : files) {
        Song s;
        s.filePath = file;
        QFileInfo info(file);
        s.title = info.baseName();
        s.artist = "";
        s.duration = 0;
        s.albumArt = QImage();

        QMediaPlayer tmp;
        tmp.setSource(QUrl::fromLocalFile(file));
        QEventLoop loop;
        QObject::connect(&tmp, &QMediaPlayer::mediaStatusChanged,
                         &loop, [&](auto status){ if (status == QMediaPlayer::LoadedMedia) loop.quit(); });
        loop.exec();
        s.duration = tmp.duration();
        auto meta = tmp.metaData();
        auto artistVar = meta.value(QMediaMetaData::ContributingArtist);
        if (artistVar.canConvert<QString>())
            s.artist = artistVar.toString();
        auto artVar = meta.value(QMediaMetaData::CoverArtImage);
        if (artVar.canConvert<QImage>())
            s.albumArt = artVar.value<QImage>();

        m_songs.append(s);
    }
    endResetModel();
    emit songsAdded();
}

QImage SongModel::albumArt(int index) const {
    return (index >= 0 && index < m_songs.size()) ? m_songs[index].albumArt : QImage();
}
