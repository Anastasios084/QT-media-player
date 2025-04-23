#include "PlayerController.h"

PlayerController::PlayerController(SongModel* model, QObject* parent)
    : QObject(parent), m_model(model) {
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(m_audioOutput);

    connect(m_player, &QMediaPlayer::positionChanged, this, &PlayerController::positionChanged);
    connect(m_player, &QMediaPlayer::durationChanged, this, &PlayerController::durationChanged);
    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](auto state){
        emit playingChanged(state == QMediaPlayer::PlayingState);
    });
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](auto status){
        if (status == QMediaPlayer::EndOfMedia) next();
    });

    connect(m_model, &SongModel::songsAdded, this, [this](){
        m_playlist.clear();
        for (int i = 0; i < m_model->rowCount(); ++i) {
            auto idx = m_model->index(i, 0);
            QString path = m_model->data(idx, SongModel::FilePathRole).toString();
            m_playlist.append(path);
        }
        m_currentIndex = 0;//m_currentIndex+1; // PROBABLY WILL CHANGE IT
        newSong = true;
        // m_player->stop();
        // m_player->setSource(m_playlist[m_currentIndex]);
        playIndex(m_currentIndex);
    });
}

void PlayerController::play() {
    qDebug() << "PLAY WAS CALLED!!!!!!!";
    if (m_currentIndex < 0 && !m_playlist.isEmpty()) {
        m_currentIndex = 0;
        m_player->setSource(m_playlist[0]);
        emit currentIndexChanged(m_currentIndex);
    }
    m_player->play();
}

void PlayerController::playIndex(int index) {
    // if (index < 0 || index >= m_playlist.size()) return;
    if(newSong || index != m_currentIndex){
        bumpArtVersion();
        newSong = false;
        m_currentIndex = index;
        m_player->setSource(m_playlist[m_currentIndex]);
        connect(m_player, &QMediaPlayer::mediaStatusChanged, this,
                [this](QMediaPlayer::MediaStatus s){
                    if (s == QMediaPlayer::LoadedMedia){
                        m_player->stop();
                    }
                }, Qt::SingleShotConnection); // big brain move
        emit currentIndexChanged(m_currentIndex);
        // m_player->play();
        m_player->setPosition(0);
        emit m_player->positionChanged(0);


    }else{
        emit currentIndexChanged(m_currentIndex);
        m_player->play();
    }
}
void PlayerController::pause() { m_player->pause(); }
void PlayerController::stop() { m_player->stop(); }

void PlayerController::next() {
    if (m_playlist.isEmpty()) return;
    // newSong = true;
    const int nextIdx = (m_currentIndex + 1) % m_playlist.size();
    playIndex(nextIdx);
}
void PlayerController::previous() {
    if (m_playlist.isEmpty()) return;
    // newSong = true;
    const int prevIdx = (m_currentIndex - 1 + m_playlist.size()) % m_playlist.size();
    playIndex(prevIdx);
}

void PlayerController::setPosition(qint64 pos) {
    m_player->setPosition(pos);
}
qint64 PlayerController::position() const { return m_player->position(); }
qint64 PlayerController::duration() const { return m_player->duration(); }
bool PlayerController::isPlaying() const { return m_player->playbackState() == QMediaPlayer::PlayingState; }
int PlayerController::volume() const {
    // Return percentage 0–100
    return static_cast<int>(m_audioOutput->volume() * 100);
}

void PlayerController::setVolume(int vol) {
    // Scale 0–100 to 0.0–1.0
    qreal linear = qBound<qreal>(0.0, vol / 100.0, 1.0);
    m_audioOutput->setVolume(linear);
    emit volumeChanged(volume());
}
int PlayerController::currentIndex() const { return m_currentIndex; }
