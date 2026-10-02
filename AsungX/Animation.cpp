#include "Animation.h"
#include "oui.h"
#include "language.h"

#include "DisplayUI.h"
extern DisplayUI displayUI;
extern uint32_t currentTime;

File     Animation::_file;
bool     Animation::_playing = false;
bool     Animation::_loop = false;
uint16_t Animation::_frameCount = 0;
uint16_t Animation::_frameSize = 0;
uint16_t Animation::_currentFrame = 0;
uint32_t Animation::_lastFrameTime = 0;
uint32_t Animation::_frameInterval = 1000 / ANIM_FPS_DEFAULT;
bool     Animation::_deltaEncoded = false;
uint8_t  Animation::_fps = ANIM_FPS_DEFAULT;
uint8_t  Animation::_buffer[128 * 64 / 8];
char     Animation::_currentFile[ANIM_MAX_PATH] = {0};

void Animation::begin() {
    _resetState();
    prntln("AsungX: Animation module ready");
}

void Animation::_resetState() {
    if (_file) _file.close();
    _playing = false;
    _loop = false;
    _frameCount = 0;
    _frameSize = 0;
    _currentFrame = 0;
    _deltaEncoded = false;
    memset(_buffer, 0, sizeof(_buffer));
}

bool Animation::play(const char* filename, bool loop) {
    stop();

    if (!LittleFS.exists(filename)) {
        prntln("Animation: file tidak ditemukan");
        return false;
    }

    _file = LittleFS.open(filename, "r");
    if (!_file) {
        prntln("Animation: gagal buka file");
        return false;
    }

    // Baca header: frame_count (u16), frame_size (u16), delta_flag (u8)
    uint8_t header[5];
    if (_file.read(header, 5) != 5) {
        prntln("Animation: header invalid");
        stop();
        return false;
    }

    _frameCount  = header[0] | (header[1] << 8);
    _frameSize   = header[2] | (header[3] << 8);
    _deltaEncoded = (header[4] != 0);

    if (_frameCount == 0 || _frameSize == 0 || _frameSize > sizeof(_buffer)) {
        prntln("Animation: dimensi invalid");
        stop();
        return false;
    }

    _currentFrame = 0;
    _lastFrameTime = 0;
    _loop = loop;
    _playing = true;
    _frameInterval = 1000 / _fps;
    strncpy(_currentFile, filename, ANIM_MAX_PATH - 1);

    prnt(String("Animation: play ") + filename + " (" + _frameCount + " frames)");
    return true;
}

void Animation::stop() {
    if (_playing) {
        prntln("Animation: stop");
    }
    _resetState();
}

bool Animation::isPlaying() {
    return _playing;
}

void Animation::setFPS(uint8_t fps) {
    if (fps < 1) fps = 1;
    if (fps > 30) fps = 30;
    _fps = fps;
    _frameInterval = 1000 / _fps;
}

uint8_t Animation::getFPS() { return _fps; }

void Animation::setLoop(bool loop) { _loop = loop; }
bool Animation::getLoop() { return _loop; }

void Animation::_renderFrame() {
    if (!_file) return;

    if (_deltaEncoded && _currentFrame > 0) {
        // Delta format (converter Claude):
        // [count:u16 LE][indices:u16 LE × count][values:u8 × count]
        uint8_t cb[2];
        if (_file.read(cb, 2) != 2) return;
        uint16_t count = cb[0] | (cb[1] << 8);
        if (count > 0) {
            size_t need = (size_t)count * 3;  // 2 B index + 1 B value per entry
            uint8_t* tmp = (uint8_t*)malloc(need);
            if (!tmp) return;
            if (_file.read(tmp, need) != need) { free(tmp); return; }
            const uint8_t* vals = tmp + (size_t)count * 2;
            for (uint16_t i = 0; i < count; i++) {
                uint16_t idx = tmp[i * 2] | (tmp[i * 2 + 1] << 8);
                if (idx < _frameSize) _buffer[idx] = vals[i];
            }
            free(tmp);
        }
    } else {
        // Full frame
        if (_file.read(_buffer, _frameSize) != _frameSize) return;
    }

    // Render ke OLED
    displayUI.display.clear();
    for (uint16_t y = 0; y < 64; y++) {
        for (uint16_t x = 0; x < 128; x++) {
            uint16_t byte_idx = y * 16 + (x / 8);
            uint8_t bit = 7 - (x % 8);
            if (byte_idx < _frameSize && (_buffer[byte_idx] & (1 << bit))) {
                displayUI.display.setPixel(x, y);
            }
        }
    }
    displayUI.display.display();
}

void Animation::update() {
    if (!_playing) return;
    if (currentTime - _lastFrameTime < _frameInterval) return;

    _lastFrameTime = currentTime;
    _renderFrame();
    _currentFrame++;

    if (_currentFrame >= _frameCount) {
        if (_loop) {
            _currentFrame = 0;
            _file.seek(5); // kembali ke awal data
        } else {
            stop();
        }
    }
}

String Animation::listFilesJSON() {
    String json = "[";
    Dir dir = LittleFS.openDir("/");
    bool first = true;
    while (dir.next()) {
        String name = dir.fileName();
        if (name.endsWith(".bin") || name.endsWith(".BIN")) {
            if (!first) json += ",";
            first = false;
            json += "{\"name\":\"" + name + "\",\"size\":" + String(dir.fileSize()) + "}";
        }
    }
    json += "]";
    return json;
}

bool Animation::deleteFile(const char* filename) {
    if (!LittleFS.exists(filename)) return false;
    return LittleFS.remove(filename);
}

size_t Animation::getFreeSpace() {
    FSInfo info;
    LittleFS.info(info);
    return info.totalBytes - info.usedBytes;
}
