#ifndef SONGFILTERPROXYMODEL_H
#define SONGFILTERPROXYMODEL_H

#include <QSortFilterProxyModel>
#include <QVariantMap>

class SongFilterProxyModel : public QSortFilterProxyModel {
    Q_OBJECT
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)
public:
    explicit SongFilterProxyModel(QObject *parent = nullptr);
    QString filterString() const;
    void setFilterString(const QString &);
    Q_INVOKABLE int sourceIndex(int proxyRow) const;
    Q_INVOKABLE QVariantMap get(int proxyRow) const;
signals:
    void filterStringChanged();
protected:
    bool filterAcceptsRow(int row, const QModelIndex &parent) const override;
private:
    QString m_filterString;
};
#endif
