#include "SongFilterProxyModel.h"
#include "SongModel.h"
#include <QModelIndex>

// Custom proxy model to filter and sort songs by title or artist
SongFilterProxyModel::SongFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent) {
    // Perform case-insensitive filtering by default
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    // Use the TitleRole of SongModel when matching the filter  - default
    setFilterRole(SongModel::TitleRole);
}

// Getter for the filter string property
QString SongFilterProxyModel::filterString() const { return m_filterString; }

// Setter for the filter string property (callable from QML)
void SongFilterProxyModel::setFilterString(const QString &str) {
    // No change, no work needed
    if (m_filterString == str) return;

    // Update internal value and apply new filter
    m_filterString = str;
    // Tell base class what string to filter
    setFilterFixedString(str);
    // Re-run the filtering operation
    invalidateFilter();
    // Notify QML that the property changed
    emit filterStringChanged();
}

// Filter mode
SongFilterProxyModel::FilterMode SongFilterProxyModel::filterMode() const {
    return m_filterMode;
}

void SongFilterProxyModel::setFilterMode(SongFilterProxyModel::FilterMode mode) {
    if (m_filterMode == mode)
        return;
    m_filterMode = mode;
    invalidateFilter();
    emit filterModeChanged();
}

// Override to customize which rows are shown
bool SongFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &parent) const {
    // If no filter string, show all rows
    if (m_filterString.isEmpty()) return true;

    // Fetch title and artist from the source model for this row
    // Retrieve title & artist once for efficiency
    QModelIndex idx = sourceModel()->index(sourceRow, 0, parent);
    QString title  = sourceModel()->data(idx, SongModel::TitleRole).toString();
    QString artist = sourceModel()->data(idx, SongModel::ArtistRole).toString();

    switch (m_filterMode) {
    case TitleOnly:
        return title.contains(m_filterString, Qt::CaseInsensitive);
    case ArtistOnly:
        return artist.contains(m_filterString, Qt::CaseInsensitive);
    case TitleOrArtist:
    default:
        return title.contains(m_filterString, Qt::CaseInsensitive) ||
               artist.contains(m_filterString, Qt::CaseInsensitive);
    }
}

// Map a row in the proxy model back to the source model's row index
int SongFilterProxyModel::sourceIndex(int proxyRow) const {
    QModelIndex idx = index(proxyRow,0);
    return mapToSource(idx).row();
}

// Retrieve song data as a QVariantMap for a given proxy-row (for easy QML access)
QVariantMap SongFilterProxyModel::get(int proxyRow) const {
    QVariantMap map;

    // Map proxy index to source model index
    QModelIndex pIdx = index(proxyRow,0);
    int srcRow = mapToSource(pIdx).row();
    QModelIndex sIdx = sourceModel()->index(srcRow,0);

    // Populate map with song properties
    map["title"] = sourceModel()->data(sIdx, SongModel::TitleRole);
    map["artist"] = sourceModel()->data(sIdx, SongModel::ArtistRole);
    map["duration"] = sourceModel()->data(sIdx, SongModel::DurationRole);
    return map;
}
