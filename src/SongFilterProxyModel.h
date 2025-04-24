#ifndef SONGFILTERPROXYMODEL_H
#define SONGFILTERPROXYMODEL_H

#include <QSortFilterProxyModel>
#include <QVariantMap>

class SongFilterProxyModel : public QSortFilterProxyModel {
    Q_OBJECT
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)
    // Which field(s) the proxy should match against
    Q_PROPERTY(FilterMode  filterMode  READ filterMode  WRITE setFilterMode NOTIFY filterModeChanged)
public:
    // Which field(s) the proxy should match against
    enum FilterMode {
        TitleOnly,      // 0 – Search only the song title
        ArtistOnly,     // 1 – Search only the artist name
        TitleOrArtist   // 2 – Default: search either title or artist
    };
    Q_ENUM(FilterMode)
    explicit SongFilterProxyModel(QObject *parent = nullptr);
    QString filterString() const;
    void setFilterString(const QString &);
    // Field(s) to match
    FilterMode filterMode() const;
    void setFilterMode(FilterMode mode);

    Q_INVOKABLE int sourceIndex(int proxyRow) const;
    Q_INVOKABLE QVariantMap get(int proxyRow) const;
signals:
    void filterStringChanged();
    void filterModeChanged();
protected:
    bool filterAcceptsRow(int row, const QModelIndex &parent) const override;
private:
    QString m_filterString;
    FilterMode m_filterMode { TitleOrArtist };

};
#endif
