#include "SongModel.h"
#include <QFileInfo>
#include <QMediaPlayer>
#include <QEventLoop>
#include <QUrl>
#include <QMediaMetaData>
#include <QDirIterator>

// SongModel: a list model exposing metadata for audio files
SongModel::SongModel(QObject *parent)
    : QAbstractListModel(parent) {}

// Public slot: add all supported audio files from a folder (and subfolders)
void SongModel::addFolder(const QUrl &folderUrl)
{
    // Convert QUrl to local filesystem path if possible
    const QString folderPath = folderUrl.isLocalFile()
                                   ? folderUrl.toLocalFile()
                                   : folderUrl.toString(QUrl::PreferLocalFile);

    // Collect supported file extensions recursively
    QStringList files;
    QDirIterator it(folderPath,
                    { "*.mp3", "*.m4a", "*.flac", "*.wav", "*.ogg" },
                    QDir::Files,
                    QDirIterator::Subdirectories);


    while (it.hasNext())
        files << it.next();          // collect every audio file we find
    addSongs(files);                 // re‑use the existing method
}

// Number of rows in the model
int SongModel::rowCount(const QModelIndex &) const {
    return m_songs.size(); // one row per Song struct
}

// Data lookup by index and role
QVariant SongModel::data(const QModelIndex &idx, int role) const {
    const Song &s = m_songs.at(idx.row());
    switch (role) {
    case TitleRole:    return s.title;
    case ArtistRole:   return s.artist;
    case DurationRole: return s.duration;
    case FilePathRole: return s.filePath;
    case AlbumArtRole: return s.albumArt;
    default:           return {};
    }
}

// Load metadata for each file and reset the model
QHash<int, QByteArray> SongModel::roleNames() const {
    return {
        { TitleRole,    "title"     },
        { ArtistRole,   "artist"    },
        { DurationRole, "duration"  },
        { FilePathRole, "filePath"  },
        { AlbumArtRole, "albumArt"  }   // <-- expose the art
    };
}

// Required override: mapping from role enum to role name for QML
void SongModel::addSongs(const QStringList &files) {
    // notify views that data is about to change
    beginResetModel();
    // m_songs.clear();
    for (const QString &file : files) {
        Song s;
        s.filePath = file;

        // Default metadata from filename
        QFileInfo info(file);
        s.title = info.baseName(); // file name without extension
        s.artist = "Unknown"; // fallback if no metadata
        s.duration = 0;
        s.albumArt = QImage(); // empty image

        // Use a temporary QMediaPlayer to extract metadata
        QMediaPlayer tmp;
        tmp.setSource(QUrl::fromLocalFile(file));

        // Wait synchronously for metadata to load
        QEventLoop loop;
        QObject::connect(&tmp, &QMediaPlayer::mediaStatusChanged,
                         &loop, [&](auto status){ if (status == QMediaPlayer::LoadedMedia) loop.quit(); });
        loop.exec();

        // Now query duration and tags
        s.duration = tmp.duration();
        auto meta = tmp.metaData();

        // Extract artist tag if available
        auto artistVar = meta.value(QMediaMetaData::ContributingArtist);
        if (artistVar.canConvert<QString>())
            s.artist = artistVar.toString();

        // Extract album art thumbnail if available
        auto artVar = meta.value(QMediaMetaData::ThumbnailImage);
        if (artVar.canConvert<QImage>()){
            s.albumArt = artVar.value<QImage>();
        }

        // add to internal list
        m_songs.append(s);
    }

    // notify views that data has changed
    endResetModel();

    // signal consumers that new songs are available
    emit songsAdded();
}

// Return album art for a given model index, or empty image
QImage SongModel::albumArt(int index) const {
    return (index >= 0 && index < m_songs.size()) ? m_songs[index].albumArt : QImage();
}
