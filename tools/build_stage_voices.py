#!/usr/bin/env python3
"""
Generate stage crowd voice shouts for AI Showdown (Task G6).
Reads data/stage_life/<stage>.json and synthesizes diverse male, female,
young, old, and technical voice lines into assets/audio/stage/<stage>/voice/<key>_<n>.ogg.
"""

import os
import json
import subprocess
import tempfile
import numpy as np
import soundfile as sf

STAGE_LIFE_DIR = "data/stage_life"
AUDIO_STAGE_DIR = "assets/audio/stage"

VOICE_PROFILES = {
    "senate": [
        {"voice": "Microsoft David Desktop", "rate": -1, "pitch": 0.88, "radio": False}, # Chair
        {"voice": "Microsoft David Desktop", "rate": 1, "pitch": 0.98, "radio": False},  # Senator
        {"voice": "Microsoft Zira Desktop",  "rate": 1, "pitch": 1.05, "radio": False},  # Stenographer / Sen. Lindqvist
        {"voice": "Microsoft David Desktop", "rate": 2, "pitch": 1.10, "radio": False},  # Press / Reporter
    ],
    "mensa": [
        {"voice": "Microsoft David Desktop", "rate": 2, "pitch": 1.15, "radio": False},  # Student male 1
        {"voice": "Microsoft Zira Desktop",  "rate": 2, "pitch": 1.18, "radio": False},  # Student female 1
        {"voice": "Microsoft David Desktop", "rate": 0, "pitch": 0.90, "radio": False},  # Cook / Postdoc
        {"voice": "Microsoft Zira Desktop",  "rate": 1, "pitch": 1.02, "radio": False},  # Cashier / Student 2
    ],
    "foundry": [
        {"voice": "Microsoft David Desktop", "rate": 1, "pitch": 1.02, "radio": True},   # Cleanroom operator 1
        {"voice": "Microsoft Zira Desktop",  "rate": 1, "pitch": 1.06, "radio": True},   # Cleanroom operator 2
        {"voice": "Microsoft David Desktop", "rate": 2, "pitch": 0.94, "radio": True},   # Lead architect
        {"voice": "Microsoft Zira Desktop",  "rate": 0, "pitch": 0.98, "radio": True},   # QA Inspector
    ],
    "server_farm": [
        {"voice": "Microsoft David Desktop", "rate": 2, "pitch": 1.05, "radio": False},  # Sysadmin 1
        {"voice": "Microsoft Zira Desktop",  "rate": 2, "pitch": 1.10, "radio": False},  # Sysadmin 2
        {"voice": "Microsoft David Desktop", "rate": 1, "pitch": 0.92, "radio": False},  # SRE Lead
        {"voice": "Microsoft Zira Desktop",  "rate": 1, "pitch": 1.02, "radio": False},  # Cloud architect
    ],
}

def trim_silence(sig: np.ndarray, threshold: float = 0.015) -> np.ndarray:
    abs_sig = np.abs(sig)
    above = np.where(abs_sig > threshold)[0]
    if len(above) == 0:
        return sig
    start = max(0, above[0] - 200)
    end = min(len(sig), above[-1] + 200)
    return sig[start:end]

def pitch_shift_simple(sig: np.ndarray, factor: float) -> np.ndarray:
    if abs(factor - 1.0) < 0.01:
        return sig
    n = len(sig)
    new_n = int(n / factor)
    if new_n <= 0:
        return sig
    # Linear interpolation
    old_indices = np.linspace(0, n - 1, new_n)
    shifted = np.interp(old_indices, np.arange(n), sig)
    return shifted.astype(np.float32)

def apply_radio_filter(sig: np.ndarray, sr: int = 22050) -> np.ndarray:
    # Frequency domain bandpass (350 Hz to 3800 Hz) + slight saturation
    n = len(sig)
    X = np.fft.rfft(sig)
    freqs = np.fft.rfftfreq(n, 1.0 / sr)
    gain = np.zeros_like(freqs)
    band = (freqs >= 350.0) & (freqs <= 3800.0)
    gain[band] = 1.0
    # Soft transition skirts
    low_skirt = (freqs >= 200.0) & (freqs < 350.0)
    gain[low_skirt] = 0.5 * (1.0 - np.cos(np.pi * (freqs[low_skirt] - 200.0) / 150.0))
    high_skirt = (freqs > 3800.0) & (freqs <= 4500.0)
    gain[high_skirt] = 0.5 * (1.0 + np.cos(np.pi * (freqs[high_skirt] - 3800.0) / 700.0))
    filtered = np.fft.irfft(X * gain, n=n).astype(np.float32)
    # Slight soft clipping for cleanroom headset mic character
    clipped = np.tanh(filtered * 1.4) * 0.8
    return clipped

def normalize_peak(sig: np.ndarray, target_peak: float = 0.80) -> np.ndarray:
    peak = np.max(np.abs(sig))
    if peak > 1e-5:
        return (sig / peak * target_peak).astype(np.float32)
    return sig.astype(np.float32)

def generate_voice_file(text: str, out_ogg_path: str, profile: dict):
    os.makedirs(os.path.dirname(out_ogg_path), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_wav:
        temp_wav_path = temp_wav.name
    with tempfile.NamedTemporaryFile(suffix=".ps1", delete=False, mode="w", encoding="utf-8") as temp_ps1:
        # Sanitize single quotes
        safe_text = text.replace("'", "''")
        voice = profile.get("voice", "Microsoft David Desktop")
        rate = profile.get("rate", 0)
        ps_code = f"""
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.SelectVoice('{voice}')
$synth.Rate = {rate}
$synth.SetOutputToWaveFile('{temp_wav_path}')
$synth.Speak('{safe_text}')
$synth.Dispose()
"""
        temp_ps1.write(ps_code)
        temp_ps1_path = temp_ps1.name

    try:
        res = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", temp_ps1_path],
                             capture_output=True, text=True)
        if res.returncode != 0 or not os.path.exists(temp_wav_path) or os.path.getsize(temp_wav_path) == 0:
            print(f"Error synthesizing '{text}': {res.stderr}")
            return False

        sig, sr = sf.read(temp_wav_path)
        sig = trim_silence(sig)
        if profile.get("pitch", 1.0) != 1.0:
            sig = pitch_shift_simple(sig, profile["pitch"])
        if profile.get("radio", False):
            sig = apply_radio_filter(sig, sr)
        sig = normalize_peak(sig)

        # Write out as OGG Vorbis
        sf.write(out_ogg_path, sig, sr, format="OGG", subtype="VORBIS")
        print(f"  Generated {out_ogg_path} ({len(sig)/sr:.2f}s) -> '{text}'")
        return True
    finally:
        if os.path.exists(temp_ps1_path):
            os.remove(temp_ps1_path)
        if os.path.exists(temp_wav_path):
            os.remove(temp_wav_path)

def main():
    print("Building stage shout voices (Task G6)...")
    stages = ["senate", "mensa", "foundry", "server_farm"]
    total = 0
    for stage in stages:
        json_path = os.path.join(STAGE_LIFE_DIR, f"{stage}.json")
        if not os.path.exists(json_path):
            print(f"Skipping {stage}: JSON not found")
            continue
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        shouts = data.get("shouts", {})
        profiles = VOICE_PROFILES.get(stage, VOICE_PROFILES["senate"])
        print(f"Generating voices for stage: {stage}")
        for key, lines in shouts.items():
            for idx, line in enumerate(lines):
                out_path = os.path.join(AUDIO_STAGE_DIR, stage, "voice", f"{key}_{idx}.ogg")
                profile = profiles[idx % len(profiles)]
                ok = generate_voice_file(line, out_path, profile)
                if ok:
                    total += 1
    print(f"Task G6 Complete: Generated {total} stage shout voice files!")

if __name__ == "__main__":
    main()
