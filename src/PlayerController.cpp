#include "PlayerController.h"

// PlayerController ties together SongModel and QMediaPlayer to drive playback
PlayerController::PlayerController(SongModel* model, QObject* parent)
    : QObject(parent), m_model(model) {

    // Create and configure the media player and audio output
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(m_audioOutput);

    // Forward position and duration changes to QML
    connect(m_player, &QMediaPlayer::positionChanged, this, &PlayerController::positionChanged);
    connect(m_player, &QMediaPlayer::durationChanged, this, &PlayerController::durationChanged);
    // Notify QML when playback starts or stops
    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](auto state){
        emit playingChanged(state == QMediaPlayer::PlayingState);
    });
    // Automatically advance to the next song when one finishes
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](auto status){
        if (status == QMediaPlayer::EndOfMedia) next();
    });

    // When the SongModel emits that songs have been added, rebuild playlist
    connect(m_model, &SongModel::songsAdded, this, [this](){
        m_playlist.clear();
        for (int i = 0; i < m_model->rowCount(); ++i) {
            auto idx = m_model->index(i, 0);
            QString path = m_model->data(idx, SongModel::FilePathRole).toString();
            m_playlist.append(path);
        }

        // start from the first song if playlist is newly created or from the latest added song
        m_currentIndex = m_currentIndex == -1 ? 0 : m_playlist.size()-1;
        newSong = true;
        playIndex(m_currentIndex);
    });
}

void PlayerController::play() {
    // If nothing has been loaded yet, start with the first track
    if (m_currentIndex < 0 && !m_playlist.isEmpty()) {
        m_currentIndex = 0;
        m_player->setSource(m_playlist[0]);
        emit currentIndexChanged(m_currentIndex);
    }
    m_player->play();
}

void PlayerController::playIndex(int index) {
    // Only load a new source if it's a different song or freshly loaded
    if(newSong || index != m_currentIndex){
        bumpArtVersion(); // trigger album art refresh in QML
        newSong = false;
        m_currentIndex = index;

        // Set the media source to the selected file
        m_player->setSource(m_playlist[m_currentIndex]);

        // Wait for media to load before updating position - timing issue fix
        connect(m_player, &QMediaPlayer::mediaStatusChanged, this,
                [this](QMediaPlayer::MediaStatus s){
                    if (s == QMediaPlayer::LoadedMedia){
                        m_player->stop();
                    }
                }, Qt::SingleShotConnection); // big brain move
        emit currentIndexChanged(m_currentIndex);

        // reset playback position
        m_player->setPosition(0);
        emit m_player->positionChanged(0);

    }else{
        // If re-selecting the same index, just resume playing
        emit currentIndexChanged(m_currentIndex);
        m_player->play();
    }
}

void PlayerController::pause() { m_player->pause(); }
void PlayerController::stop() { m_player->stop(); }

void PlayerController::next() {
    if (m_playlist.isEmpty()) return;
    // Wrap around to first track after the last
    const int nextIdx = (m_currentIndex + 1) % m_playlist.size();
    playIndex(nextIdx);
}
void PlayerController::previous() {
    if (m_playlist.isEmpty()) return;
    // Wrap around to last track when stepping back from the first
    const int prevIdx = (m_currentIndex - 1 + m_playlist.size()) % m_playlist.size();
    playIndex(prevIdx);
}

// Seek to given millisecond position
void PlayerController::setPosition(qint64 pos) {
    m_player->setPosition(pos);
}

// Current playback position
qint64 PlayerController::position() const { return m_player->position(); }

// Total media duration
qint64 PlayerController::duration() const { return m_player->duration(); }

// is playing?
bool PlayerController::isPlaying() const { return m_player->playbackState() == QMediaPlayer::PlayingState; }

// Convert volume (0.0–1.0) to percentage (0–100)
int PlayerController::volume() const {
    return static_cast<int>(m_audioOutput->volume() * 100);
}

// Clamp input to valid range and apply
void PlayerController::setVolume(int vol) {
    // Scale 0–100 to 0.0–1.0
    qreal linear = qBound<qreal>(0.0, vol / 100.0, 1.0);
    m_audioOutput->setVolume(linear);
    emit volumeChanged(volume());
}

// current index
int PlayerController::currentIndex() const { return m_currentIndex; }
