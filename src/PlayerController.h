#ifndef PLAYERCONTROLLER_H
#define PLAYERCONTROLLER_H

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
#include "SongModel.h"

class PlayerController : public QObject {
    Q_OBJECT
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
public:
    explicit PlayerController(SongModel* model, QObject *parent = nullptr);
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void playIndex(int index);
    Q_INVOKABLE void setPosition(qint64 pos);
    qint64 position() const;
    qint64 duration() const;
    bool isPlaying() const;
    int volume() const;
    void setVolume(int vol);
    int currentIndex() const;
signals:
    void positionChanged(qint64);
    void durationChanged(qint64);
    void playingChanged(bool);
    void volumeChanged(int);
    void currentIndexChanged(int);
private:
    SongModel *m_model;
    QMediaPlayer *m_player;
    QAudioOutput *m_audioOutput;
    QList<QUrl> m_playlist;
    int m_currentIndex{-1};
};

#endif
