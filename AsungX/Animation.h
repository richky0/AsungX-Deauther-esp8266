#ifndef Animation_h
#define Animation_h

#include "Arduino.h"
#include <LittleFS.h>
#include "DisplayUI.h"

#define ANIM_MAX_PATH 32
#define ANIM_FPS_DEFAULT 15
#define ANIM_LIMIT_SOFT (45 * 1024)
#define ANIM_LIMIT_HARD (60 * 1024)
#define ANIM_FRAME_SIZE_128x64 1024

class Animation {
    public:
        static void   begin();
        static bool   play(const char* filename, bool loop = false);
        static void   stop();
        static void   update();
        static bool   isPlaying();
        static void   setFPS(uint8_t fps);
        static uint8_t getFPS();
        static void   setLoop(bool loop);
        static bool   getLoop();

        static String listFilesJSON();
        static bool   deleteFile(const char* filename);
        static size_t getFreeSpace();

    private:
        static File     _file;
        static bool     _playing;
        static bool     _loop;
        static uint16_t _frameCount;
        static uint16_t _frameSize;
        static uint16_t _currentFrame;
        static uint32_t _lastFrameTime;
        static uint32_t _frameInterval;
        static bool     _deltaEncoded;
        static uint8_t  _fps;
        static uint8_t  _buffer[128 * 64 / 8]; // 1 KB max buffer
        static char     _currentFile[ANIM_MAX_PATH];

        static void _renderFrame();
        static void _resetState();
};

#endif
