#ifndef SONGMODEL_H
#define SONGMODEL_H

#include <QAbstractListModel>
#include <QImage>

struct Song {
    QString title;
    QString artist;
    qint64 duration;
    QString filePath;
    QImage albumArt;
};

class SongModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Role { TitleRole = Qt::UserRole+1,
                ArtistRole,
                DurationRole,
                FilePathRole };

    explicit SongModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addSongs(const QStringList &files);
    QImage albumArt(int index) const;

signals:
    void songsAdded();

private:
    QList<Song> m_songs;
};

#endif // SONGMODEL_H
