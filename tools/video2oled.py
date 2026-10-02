#!/usr/bin/env python3
"""
Video/GIF → ESP8266 OLED Animation (.bin)
Format: [frame_count:u16][frame_size:u16][frame_data...]

Usage:
  python video2oled.py input.mp4 output.bin --fps 15 --duration 3
  python video2oled.py input.gif output.bin --fps 15 --delta
"""
from PIL import Image, ImageSequence
import subprocess
import struct
import sys
import os
import argparse
import shutil

FFMPEG_AVAILABLE = shutil.which("ffmpeg") is not None

def extract_frames_video(video, fps, duration, tmp_dir):
    if not FFMPEG_AVAILABLE:
        print("❌ FFmpeg tidak ada. Install: sudo apt install ffmpeg")
        sys.exit(1)
    os.makedirs(tmp_dir, exist_ok=True)
    subprocess.run([
        "ffmpeg", "-y", "-i", video,
        "-vf", f"fps={fps}",
        "-t", str(duration),
        f"{tmp_dir}/frame_%04d.png"
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return sorted([f"{tmp_dir}/{f}" for f in os.listdir(tmp_dir) if f.endswith(".png")])

def extract_frames_gif(gif_path, fps, duration):
    img = Image.open(gif_path)
    frames = []
    max_frames = int(fps * duration) if duration > 0 else 9999
    for i, frame in enumerate(ImageSequence.Iterator(img)):
        if i >= max_frames:
            break
        frames.append(frame.convert("RGB").copy())
    return frames

def frame_to_oled_bytes(img, width, height):
    if isinstance(img, str):
        img = Image.open(img)
    img = img.convert("L").resize((width, height))
    bw = img.point(lambda x: 255 if x > 128 else 0, "1")
    frame_bytes = bytearray()
    for y in range(height):
        for x_byte in range(width // 8):
            byte = 0
            for bit in range(8):
                if bw.getpixel((x_byte * 8 + bit, y)):
                    byte |= (1 << (7 - bit))
            frame_bytes.append(byte)
    return bytes(frame_bytes)

def delta_encode(frames):
    """Delta: [changed_count:u16][changed_indices...][changed_values...]"""
    encoded = [frames[0]]
    for i in range(1, len(frames)):
        indices = []
        values = []
        for j in range(len(frames[i])):
            if frames[i][j] != frames[i-1][j]:
                indices.append(j)
                values.append(frames[i][j])
        if len(indices) > 65535:
            indices = indices[:65535]
            values = values[:65535]
        out = bytearray()
        out += struct.pack("<H", len(indices))
        out += bytes(indices)
        out += bytes(values)
        encoded.append(bytes(out))
    return encoded

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Input video/GIF")
    parser.add_argument("output", help="Output .bin")
    parser.add_argument("--fps", type=int, default=15)
    parser.add_argument("--duration", type=float, default=3.0)
    parser.add_argument("--width", type=int, default=128)
    parser.add_argument("--height", type=int, default=64)
    parser.add_argument("--delta", action="store_true")
    parser.add_argument("--threshold", type=int, default=128)
    args = parser.parse_args()

    print(f"📹 Input: {args.input}")
    print(f"🎯 Target: {args.width}×{args.height} @ {args.fps} FPS, {args.duration}s")

    is_gif = args.input.lower().endswith(".gif")

    if is_gif:
        print("📦 Extract frames dari GIF...")
        raw_frames = extract_frames_gif(args.input, args.fps, args.duration)
    else:
        print("📦 Extract frames dari video...")
        tmp_dir = "/tmp/video2oled_frames"
        shutil.rmtree(tmp_dir, ignore_errors=True)
        frame_paths = extract_frames_video(args.input, args.fps, args.duration, tmp_dir)
        raw_frames = frame_paths

    print(f"   → {len(raw_frames)} frames")

    print(f"🎨 Convert ke OLED format...")
    oled_frames = [frame_to_oled_bytes(f, args.width, args.height) for f in raw_frames]

    # Cleanup tmp
    if not is_gif:
        shutil.rmtree("/tmp/video2oled_frames", ignore_errors=True)

    frame_size = (args.width * args.height) // 8

    if args.delta:
        print("📦 Apply delta encoding...")
        oled_frames = delta_encode(oled_frames)
        avg_size = sum(len(f) for f in oled_frames) // len(oled_frames)
        print(f"   → Rata-rata frame: {avg_size} B (dari {frame_size} B)")
    else:
        avg_size = frame_size

    with open(args.output, "wb") as f:
        f.write(struct.pack("<HH", len(oled_frames), frame_size))
        f.write(b"\x01" if args.delta else b"\x00")  # delta flag
        for frame in oled_frames:
            f.write(frame)

    total = os.path.getsize(args.output)
    print(f"\n✅ Selesai: {args.output}")
    print(f"   Frames: {len(oled_frames)}")
    print(f"   Frame size: {frame_size} B (avg {avg_size} B)")
    print(f"   Total: {total} B ({total/1024:.1f} KB)")
    print(f"   Durasi: {len(oled_frames)/args.fps:.1f} detik")

    # Validasi terhadap batas ESP8266
    LIMIT_SOFT = 45 * 1024
    LIMIT_HARD = 60 * 1024
    if total > LIMIT_HARD:
        print(f"\n❌ FILE TERLALU BESAR! (> {LIMIT_HARD/1024:.0f} KB)")
        print(f"   ESP8266 hanya punya ~49 KB free SPIFFS.")
        print(f"   Solusi: kurangi --duration, --fps, atau tambah --delta")
    elif total > LIMIT_SOFT:
        print(f"\n⚠️  Warning: file > {LIMIT_SOFT/1024:.0f} KB")
        print(f"   Mungkin gagal upload karena SPIFFS penuh.")

if __name__ == "__main__":
    main()
