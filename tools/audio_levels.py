#!/usr/bin/env python3
"""Measure peak and RMS loudness of every .wav/.ogg under assets/audio/."""

import os
import math

BASE = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "audio")
SAMPLE_RATE = 44100

try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False

try:
    import soundfile as sf
    HAS_SOUNDFILE = True
except ImportError:
    HAS_SOUNDFILE = False


def read_wav_rms_peak(filepath):
    """Read a WAV file and return (peak_db, rms_db) using wave module + numpy."""
    import wave
    with wave.open(filepath, "rb") as wf:
        nchannels = wf.getnchannels()
        nframes = wf.getnframes()
        samples = wf.readframes(nframes)
    if HAS_NUMPY:
        data = np.frombuffer(samples, dtype=np.int16).astype(np.float64) / 32768.0
        if nchannels > 1:
            data = data.reshape(-1, nchannels).mean(axis=1)
        peak = float(np.max(np.abs(data))) if data.size > 0 else 0.0
        rms_val = float(np.sqrt(np.mean(data**2))) if data.size > 0 else 0.0
    else:
        # Pure Python without numpy - manual conversion
        samples_list = []
        for i in range(0, len(samples), 2 * nchannels):
            val = int.from_bytes(samples[i:i+2], 'little', signed=True)
            samples_list.append(val / 32768.0)
        data = samples_list
        peak = max(abs(x) for x in data) if data else 0.0
        rms_val = (sum(x*x for x in data) / len(data)) ** 0.5 if data else 0.0

    peak_db = 20.0 * math.log10(max(peak, 1e-9))
    rms_db = 20.0 * math.log10(max(rms_val, 1e-9))
    return peak_db, rms_db


def read_ogg_rms_peak(filepath):
    """Read an OGG file - may not have decoder, return None if unavailable."""
    try:
        data, sr = sf.read(filepath)
        if data.ndim > 1:
            data = data.mean(axis=1)
        if HAS_NUMPY:
            data = data.astype(np.float64)
        peak = float(np.max(np.abs(data))) if len(data) > 0 else 0.0
        rms_val = float(np.sqrt(np.mean(data**2))) if len(data) > 0 else 0.0
        peak_db = 20.0 * math.log10(max(peak, 1e-9))
        rms_db = 20.0 * math.log10(max(rms_val, 1e-9))
        return peak_db, rms_db
    except Exception:
        return None


def measure_audio(filepath):
    """Measure peak and RMS dBFS for a audio file."""
    ext = os.path.splitext(filepath)[1].lower()
    if ext == ".wav":
        return read_wav_rms_peak(filepath)
    elif ext == ".ogg":
        result = read_ogg_rms_peak(filepath)
        if result is not None:
            return result
        return None
    return None


def main():
    # Collect all .wav and .ogg files under BASE
    results = {}
    for root, _dirs, files in os.walk(BASE):
        for fname in sorted(files):
            if not (fname.endswith(".wav") or fname.endswith(".ogg")):
                continue
            fpath = os.path.join(root, fname)
            result = measure_audio(fpath)
            if result is not None:
                results[fname] = {"peak_db": result[0], "rms_db": result[1]}

    # Print table sorted by filename
    fnames = sorted(results.keys())
    header = f"{'Filename':<30} {'Peak dBFS':>12} {'RMS dBFS':>12}"
    print(header)
    print("-" * len(header))
    for f in fnames:
        r = results[f]
        print(f"{f:<30} {r['peak_db']:>12.2f} {r['rms_db']:>12.2f}")

    # Summarize by fighter category (first folder under audio)
    print("\n--- By fighter ---")
    fighters = {}
    for root, _dirs, files in os.walk(BASE):
        for fname in sorted(files):
            if not (fname.endswith(".wav") or fname.endswith(".ogg")):
                continue
            fpath = os.path.join(root, fname)
            rel = os.path.relpath(fpath, BASE)
            parts = rel.split(os.sep)
            cat = parts[0] if parts else ""
            if cat not in fighters:
                fighters[cat] = {}
            if fname in results:
                fighters[cat][fname] = results[fname]

    for cat in sorted(fighters.keys()):
        fnames_cat = sorted(fighters[cat].keys())
        print(f"\n{cat}:")
        header = f"{'Filename':<30} {'Peak dBFS':>12} {'RMS dBFS':>12}"
        print(header)
        print("-" * len(header))
        for f in fnames_cat:
            r = fighters[cat][f]
            print(f"{f:<30} {r['peak_db']:>12.2f} {r['rms_db']:>12.2f}")


if __name__ == "__main__":
    main()