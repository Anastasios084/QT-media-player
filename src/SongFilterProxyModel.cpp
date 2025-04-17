#include "SongFilterProxyModel.h"
#include "SongModel.h"
#include <QModelIndex>

SongFilterProxyModel::SongFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent) {
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    setFilterRole(SongModel::TitleRole);
}

QString SongFilterProxyModel::filterString() const { return m_filterString; }

void SongFilterProxyModel::setFilterString(const QString &str) {
    if (m_filterString == str) return;
    m_filterString = str;
    setFilterFixedString(str);
    invalidateFilter();
    emit filterStringChanged();
}

bool SongFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &parent) const {
    if (m_filterString.isEmpty()) return true;
    QModelIndex idx0 = sourceModel()->index(sourceRow,0,parent);
    QString t = sourceModel()->data(idx0, SongModel::TitleRole).toString();
    QString a = sourceModel()->data(idx0, SongModel::ArtistRole).toString();
    return t.contains(m_filterString, Qt::CaseInsensitive) ||
           a.contains(m_filterString, Qt::CaseInsensitive);
}

int SongFilterProxyModel::sourceIndex(int proxyRow) const {
    QModelIndex idx = index(proxyRow,0);
    return mapToSource(idx).row();
}

QVariantMap SongFilterProxyModel::get(int proxyRow) const {
    QVariantMap map;
    QModelIndex pIdx = index(proxyRow,0);
    int srcRow = mapToSource(pIdx).row();
    QModelIndex sIdx = sourceModel()->index(srcRow,0);
    map["title"] = sourceModel()->data(sIdx, SongModel::TitleRole);
    map["artist"] = sourceModel()->data(sIdx, SongModel::ArtistRole);
    map["duration"] = sourceModel()->data(sIdx, SongModel::DurationRole);
    return map;
}
