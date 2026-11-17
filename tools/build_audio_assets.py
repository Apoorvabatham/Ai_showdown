#!/usr/bin/env python3
"""
Procedural sound generator for AI Showdown (Tasks G5 & G7).
Generates high quality 44.1kHz 16-bit PCM WAV audio effects for stages and super moves.
Released under CC0.
"""

import os
import math
import wave
import numpy as np

SAMPLE_RATE = 44100

def write_wav(path: str, samples: np.ndarray, sample_rate: int = SAMPLE_RATE):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    # Clip and convert float in [-1.0, 1.0] to int16
    clamped = np.clip(samples, -0.98, 0.98)
    int16_data = (clamped * 32767.0).astype(np.int16)
    with wave.open(path, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(int16_data.tobytes())
    print(f"Generated {path} ({len(samples)/sample_rate:.2f}s)")

# --- Sound Synthesis Helpers ---

def noise(duration: float, color: str = 'white', count: int = -1) -> np.ndarray:
    n_samples = count if count > 0 else int(duration * SAMPLE_RATE)
    raw = np.random.uniform(-1.0, 1.0, n_samples)
    if color == 'pink':
        # Simple IIR filter for pinkish noise
        b = [0.049922035, -0.095993537, 0.050612699, -0.004408786]
        a = [1.0, -2.494956002, 2.017265875, -0.522189400]
        y = np.zeros(n_samples)
        for i in range(3, n_samples):
            y[i] = b[0]*raw[i] + b[1]*raw[i-1] + b[2]*raw[i-2] + b[3]*raw[i-3] - a[1]*y[i-1] - a[2]*y[i-2] - a[3]*y[i-3]
        return y / (np.max(np.abs(y)) + 1e-6)
    return raw

def exp_decay(duration: float, decay_rate: float = 6.0) -> np.ndarray:
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), endpoint=False)
    return np.exp(-decay_rate * t)

def tone(freq: float, duration: float, phase: float = 0.0) -> np.ndarray:
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), endpoint=False)
    return np.sin(2 * np.pi * freq * t + phase)

def sweep(f_start: float, f_end: float, duration: float) -> np.ndarray:
    t = np.linspace(0, duration, int(duration * SAMPLE_RATE), endpoint=False)
    # Linear frequency chirp
    freqs = f_start + (f_end - f_start) * (t / duration)
    phases = 2 * np.pi * np.cumsum(freqs) / SAMPLE_RATE
    return np.sin(phases)

def apply_envelope(signal: np.ndarray, attack_s: float, release_s: float) -> np.ndarray:
    att_samples = int(attack_s * SAMPLE_RATE)
    rel_samples = int(release_s * SAMPLE_RATE)
    env = np.ones_like(signal)
    if att_samples > 0:
        env[:att_samples] = np.linspace(0.0, 1.0, att_samples)
    if rel_samples > 0 and len(signal) > rel_samples:
        env[-rel_samples:] = np.linspace(1.0, 0.0, rel_samples)
    return signal * env

# ==============================================================================
# G5: STAGE SOUNDS
# ==============================================================================

def make_mensa_sounds(out_dir: str):
    # 1. tray_clatter.wav: composite clatter of dropped cafeteria trays
    dur = 0.65
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    rng = np.random.default_rng(101)
    for delay in [0.0, 0.04, 0.09, 0.16, 0.23, 0.31]:
        start_idx = int(delay * SAMPLE_RATE)
        rem = len(t) - start_idx
        if rem <= 0: continue
        sub_t = t[:rem]
        hit = (np.sin(2 * np.pi * 920 * sub_t) * 0.4 +
               np.sin(2 * np.pi * 1480 * sub_t) * 0.35 +
               np.sin(2 * np.pi * 2350 * sub_t) * 0.25)
        hit += rng.uniform(-0.25, 0.25, rem)
        env = np.exp(-rng.uniform(18.0, 32.0) * sub_t)
        sig[start_idx:] += hit * env * rng.uniform(0.5, 1.0)
    write_wav(os.path.join(out_dir, "tray_clatter.wav"), sig / (np.max(np.abs(sig)) + 1e-6))

    # 2. dishes_clink.wav: ceramic mug & plate contact
    dur = 0.45
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = (np.sin(2 * np.pi * 2150 * t) * 0.5 +
           np.sin(2 * np.pi * 4320 * t) * 0.3 +
           np.sin(2 * np.pi * 6480 * t) * 0.1) * np.exp(-14.0 * t)
    sig += (noise(dur) * 0.2) * np.exp(-45.0 * t)
    write_wav(os.path.join(out_dir, "dishes_clink.wav"), sig)

    # 3. cafeteria_chatter.wav: ambient cafeteria background murmur loop
    dur = 3.5
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur, 'pink') * 0.4
    # Modulate with multi-frequency vocal rhythm
    mod = (0.5 + 0.25 * np.sin(2 * np.pi * 0.8 * t) +
           0.15 * np.sin(2 * np.pi * 2.1 * t + 0.5) +
           0.1 * np.sin(2 * np.pi * 4.3 * t))
    sig = apply_envelope(sig * mod, 0.2, 0.2)
    write_wav(os.path.join(out_dir, "cafeteria_chatter.wav"), sig)

    # 4. cheer.wav: student crowd cheer
    dur = 1.8
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = (np.sin(2 * np.pi * 440 * t) * 0.2 +
           np.sin(2 * np.pi * 550 * t) * 0.25 +
           np.sin(2 * np.pi * 660 * t) * 0.2 +
           noise(dur) * 0.35)
    env = apply_envelope(np.ones_like(t), 0.3, 0.8)
    sig = sig * env * (0.8 + 0.2 * np.sin(2 * np.pi * 6.0 * t))
    write_wav(os.path.join(out_dir, "cheer.wav"), sig)

    # 5. gasp.wav: student crowd gasp
    dur = 0.85
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = (noise(dur, 'pink') * 0.7 + np.sin(2 * np.pi * 320 * t) * 0.2)
    env = apply_envelope(np.ones_like(t), 0.12, 0.4)
    write_wav(os.path.join(out_dir, "gasp.wav"), sig * env)

def make_senate_sounds(out_dir: str):
    # 1. gavel.wav: authoritative mahogany/brass sound block strike
    dur = 0.55
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    # Heavy low thud
    thud = np.sin(2 * np.pi * 115 * t) * np.exp(-12.0 * t)
    # Wooden impact transient
    trans = (np.sin(2 * np.pi * 980 * t) * 0.6 +
             np.sin(2 * np.pi * 1650 * t) * 0.4) * np.exp(-35.0 * t)
    # Sharp click
    click = noise(dur) * np.exp(-85.0 * t) * 0.8
    sig = thud * 0.65 + trans * 0.5 + click * 0.35
    write_wav(os.path.join(out_dir, "gavel.wav"), sig)

    # 2. camera_shutter.wav: press DSLR shutter cycle
    dur = 0.28
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    # First click (mirror up)
    m1 = int(0.01 * SAMPLE_RATE)
    l1 = int(0.04 * SAMPLE_RATE)
    sig[m1:m1+l1] += noise(0.04) * np.exp(-60.0 * np.linspace(0, 0.04, l1)) * 0.9
    # Second click (shutter curtain)
    m2 = int(0.07 * SAMPLE_RATE)
    l2 = int(0.06 * SAMPLE_RATE)
    sig[m2:m2+l2] += (noise(0.06) + np.sin(2 * np.pi * 2400 * np.linspace(0, 0.06, l2)) * 0.5) * np.exp(-45.0 * np.linspace(0, 0.06, l2))
    # Motor drive whir
    m3 = int(0.12 * SAMPLE_RATE)
    l3 = len(t) - m3
    t3 = np.linspace(0, l3/SAMPLE_RATE, l3)
    sig[m3:] += (np.sin(2 * np.pi * 1800 * t3) * 0.25 + noise(l3/SAMPLE_RATE) * 0.2) * np.exp(-16.0 * t3)
    write_wav(os.path.join(out_dir, "camera_shutter.wav"), sig)

    # 3. flash_pop.wav: xenon strobe capacitor discharge
    dur = 0.35
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = (noise(dur) * np.exp(-70.0 * t) * 0.7 +
           np.sin(2 * np.pi * 380 * t) * np.exp(-22.0 * t) * 0.3)
    write_wav(os.path.join(out_dir, "flash_pop.wav"), sig)

    # 4. hearing_chatter.wav: reverberant senate gallery murmur
    dur = 3.0
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur, 'pink') * 0.25 * (0.6 + 0.4 * np.sin(2 * np.pi * 0.4 * t))
    sig = apply_envelope(sig, 0.3, 0.3)
    write_wav(os.path.join(out_dir, "hearing_chatter.wav"), sig)

    # 5. cheer.wav: hearing room applause
    dur = 2.0
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    rng = np.random.default_rng(42)
    for _ in range(80):
        t_hit = rng.uniform(0.1, 1.8)
        idx = int(t_hit * SAMPLE_RATE)
        rem = min(int(0.04 * SAMPLE_RATE), len(t) - idx)
        if rem > 0:
            clap = noise(rem / SAMPLE_RATE) * np.exp(-40.0 * np.linspace(0, rem/SAMPLE_RATE, rem))
            sig[idx:idx+rem] += clap * rng.uniform(0.2, 0.5)
    sig = apply_envelope(sig, 0.2, 0.4)
    write_wav(os.path.join(out_dir, "cheer.wav"), sig / (np.max(np.abs(sig)) + 1e-6))

    # 6. gasp.wav: committee room collective gasp
    dur = 0.9
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur, 'pink') * np.exp(-4.0 * (t - 0.2)**2 / 0.05) * 0.8
    write_wav(os.path.join(out_dir, "gasp.wav"), sig)

def make_server_farm_sounds(out_dir: str):
    # 1. fan_whir.wav: high-speed server blower fan drone
    dur = 2.5
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = (np.sin(2 * np.pi * 120 * t) * 0.3 +
           np.sin(2 * np.pi * 240 * t) * 0.25 +
           np.sin(2 * np.pi * 480 * t) * 0.15 +
           noise(dur, 'pink') * 0.35)
    sig = apply_envelope(sig, 0.15, 0.15)
    write_wav(os.path.join(out_dir, "fan_whir.wav"), sig)

    # 2. alarm.wav: server rack fault siren
    dur = 1.2
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    freq = np.where(np.sin(2 * np.pi * 3.5 * t) > 0, 880.0, 1175.0)
    sig = np.sin(2 * np.pi * freq * t) * 0.7
    write_wav(os.path.join(out_dir, "alarm.wav"), sig)

    # 3. terminal_beep.wav: status terminal blip
    dur = 0.12
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.sin(2 * np.pi * 1760 * t) * np.exp(-18.0 * t) * 0.8
    write_wav(os.path.join(out_dir, "terminal_beep.wav"), sig)

    # 4. steam_hiss.wav: cooling manifold pressure release
    dur = 1.0
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur) * np.exp(-3.5 * t) * 0.75
    sig = apply_envelope(sig, 0.05, 0.3)
    write_wav(os.path.join(out_dir, "steam_hiss.wav"), sig)

    # 5. cheer.wav: sysadmin and NOC engineer crowd applause
    dur = 2.0
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    rng = np.random.default_rng(256)
    for _ in range(70):
        t_hit = rng.uniform(0.1, 1.8)
        idx = int(t_hit * SAMPLE_RATE)
        rem = min(int(0.04 * SAMPLE_RATE), len(t) - idx)
        if rem > 0:
            clap = noise(rem / SAMPLE_RATE) * np.exp(-42.0 * np.linspace(0, rem / SAMPLE_RATE, rem))
            sig[idx:idx+rem] += clap * rng.uniform(0.2, 0.5)
    sig = apply_envelope(sig, 0.2, 0.4)
    write_wav(os.path.join(out_dir, "cheer.wav"), sig / (np.max(np.abs(sig)) + 1e-6))

    # 6. gasp.wav: sysadmin collective gasp at server rack impact
    dur = 0.85
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur, 'pink') * np.exp(-5.0 * (t - 0.18)**2 / 0.04) * 0.75
    write_wav(os.path.join(out_dir, "gasp.wav"), sig)

def make_foundry_sounds(out_dir: str):
    # 1. welding.wav: electrical arc welding crackle and sizzle
    dur = 1.6
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    mains = np.sin(2 * np.pi * 120 * t) * 0.35
    sizzle = noise(dur) * (0.5 + 0.5 * np.sin(2 * np.pi * 30 * t)) * 0.55
    sig = apply_envelope(mains + sizzle, 0.1, 0.2)
    write_wav(os.path.join(out_dir, "welding.wav"), sig)

    # 2. sparks.wav: electrical plasma sparks
    dur = 0.75
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    rng = np.random.default_rng(777)
    for _ in range(25):
        st = rng.uniform(0.02, 0.7)
        idx = int(st * SAMPLE_RATE)
        l = min(int(0.015 * SAMPLE_RATE), len(t) - idx)
        if l > 0:
            spk = (noise(l/SAMPLE_RATE) + np.sin(2*np.pi*rng.uniform(2000, 5000)*np.linspace(0, l/SAMPLE_RATE, l))) * np.exp(-90.0*np.linspace(0, l/SAMPLE_RATE, l))
            sig[idx:idx+l] += spk * rng.uniform(0.4, 0.8)
    write_wav(os.path.join(out_dir, "sparks.wav"), sig / (np.max(np.abs(sig)) + 1e-6))

    # 3. air_shower.wav: cleanroom entrance high velocity air blast
    dur = 1.8
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur, 'pink') * 0.8
    sig = apply_envelope(sig, 0.25, 0.4)
    write_wav(os.path.join(out_dir, "air_shower.wav"), sig)

    # 4. euv_laser.wav: extreme ultraviolet pulsed beam charging and firing
    dur = 1.4
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    # Charge up sweep
    charge = sweep(60.0, 720.0, 0.9)
    # Pulse burst
    burst_t = t[int(0.9 * SAMPLE_RATE):]
    burst = (np.sin(2 * np.pi * 1350 * burst_t) * 0.5 + noise(len(burst_t)/SAMPLE_RATE) * 0.5) * np.exp(-12.0 * (burst_t - burst_t[0]))
    sig = np.zeros_like(t)
    sig[:int(0.9*SAMPLE_RATE)] = charge * np.linspace(0.1, 0.8, int(0.9*SAMPLE_RATE))
    sig[int(0.9*SAMPLE_RATE):] = burst
    write_wav(os.path.join(out_dir, "euv_laser.wav"), sig)

    # 5. alarm.wav: cleanroom protocol violation klaxon
    dur = 1.2
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.sin(2 * np.pi * 620 * t) * np.sign(np.sin(2 * np.pi * 3.0 * t)) * 0.75
    write_wav(os.path.join(out_dir, "alarm.wav"), sig)

    # 6. cheer.wav: cleanroom technicians applause through bunny-suit hoods
    dur = 1.9
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    rng = np.random.default_rng(999)
    for _ in range(75):
        t_hit = rng.uniform(0.12, 1.7)
        idx = int(t_hit * SAMPLE_RATE)
        rem = min(int(0.035 * SAMPLE_RATE), len(t) - idx)
        if rem > 0:
            # Slightly muffled clapping through cleanroom gloves
            clap = (noise(0, 'pink', rem) * 0.7 + np.sin(2 * np.pi * 800 * np.linspace(0, rem / SAMPLE_RATE, rem)) * 0.3) * np.exp(-38.0 * np.linspace(0, rem / SAMPLE_RATE, rem))
            sig[idx:idx+rem] += clap * rng.uniform(0.2, 0.5)
    sig = apply_envelope(sig, 0.2, 0.4)
    write_wav(os.path.join(out_dir, "cheer.wav"), sig / (np.max(np.abs(sig)) + 1e-6))

    # 7. gasp.wav: cleanroom technicians collective gasp at wafer risk
    dur = 0.9
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur, 'pink') * np.exp(-4.5 * (t - 0.2)**2 / 0.05) * 0.7
    write_wav(os.path.join(out_dir, "gasp.wav"), sig)

# ==============================================================================
# G7: SUPER & VICTORY SOUNDS
# ==============================================================================

def make_tesla_supers(out_dir: str):
    # truck_engine.wav: high-torque electric cyber acceleration whine
    dur = 1.4
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    whine = sweep(120.0, 1950.0, dur) * (0.6 + 0.4 * np.sin(2 * np.pi * 14 * t))
    rumble = np.sin(2 * np.pi * 55 * t) * 0.4
    sig = apply_envelope((whine * 0.6 + rumble * 0.4), 0.1, 0.25)
    write_wav(os.path.join(out_dir, "truck_engine.wav"), sig)

    # chain_rattle.wav: heavy grade tow chains rattling and snapping taut
    dur = 0.9
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    rng = np.random.default_rng(99)
    for _ in range(30):
        pos = rng.uniform(0.01, 0.7)
        idx = int(pos * SAMPLE_RATE)
        l = min(int(0.03 * SAMPLE_RATE), len(t) - idx)
        if l > 0:
            lt = np.linspace(0, l/SAMPLE_RATE, l)
            clink = (np.sin(2*np.pi*rng.uniform(1100, 3200)*lt) + noise(l/SAMPLE_RATE)*0.3) * np.exp(-50.0*lt)
            sig[idx:idx+l] += clink * rng.uniform(0.3, 0.7)
    # Final sharp tension snap at 0.75s
    snap_idx = int(0.75 * SAMPLE_RATE)
    snap_l = len(t) - snap_idx
    snap_t = np.linspace(0, snap_l/SAMPLE_RATE, snap_l)
    sig[snap_idx:] += (np.sin(2*np.pi*850*snap_t) * 0.7 + noise(snap_l/SAMPLE_RATE)*0.6) * np.exp(-30.0*snap_t)
    write_wav(os.path.join(out_dir, "chain_rattle.wav"), sig / (np.max(np.abs(sig)) + 1e-6))

    # rocket_launch_roar.wav: orbital rocket first stage ignition roar
    dur = 2.2
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    rumble = (np.sin(2 * np.pi * 42 * t) * 0.4 + np.sin(2 * np.pi * 68 * t) * 0.3)
    shear = noise(dur, 'pink') * 0.7
    sig = apply_envelope(rumble + shear, 0.3, 0.5)
    write_wav(os.path.join(out_dir, "rocket_launch_roar.wav"), sig)

    # space_whoosh.wav: atmospheric boundary exit whoosh
    dur = 1.2
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur, 'pink') * np.sin(np.pi * t / dur) * 0.85
    write_wav(os.path.join(out_dir, "space_whoosh.wav"), sig)

    # reentry_burn.wav: hypersonic friction plasma burn
    dur = 1.6
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = (noise(dur) * 0.6 + np.sin(2 * np.pi * 88 * t) * 0.4)
    sig = apply_envelope(sig, 0.2, 0.4)
    write_wav(os.path.join(out_dir, "reentry_burn.wav"), sig)

    # flag_plant.wav: titanium mast impact in lunar dust
    dur = 0.7
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    thud = np.sin(2 * np.pi * 95 * t) * np.exp(-15.0 * t) * 0.7
    ring = np.sin(2 * np.pi * 1850 * t) * np.exp(-22.0 * t) * 0.5
    write_wav(os.path.join(out_dir, "flag_plant.wav"), thud + ring)

    # victory.wav: futuristic cyber techno victory fanfare
    dur = 2.5
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    notes = [440.0, 554.37, 659.25, 880.0] # A major arpeggio
    sig = np.zeros_like(t)
    for i, n in enumerate(notes):
        st = i * 0.35
        idx = int(st * SAMPLE_RATE)
        rem = len(t) - idx
        if rem > 0:
            nt = t[:rem]
            sig[idx:] += np.sin(2 * np.pi * n * nt) * np.exp(-4.0 * nt) * 0.5
    write_wav(os.path.join(out_dir, "victory.wav"), sig)

def make_donald_supers(out_dir: str):
    # container_crash.wav: multi-ton steel shipping container slam
    dur = 1.5
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sub = np.sin(2 * np.pi * 48 * t) * np.exp(-6.0 * t) * 0.8
    body = (np.sin(2 * np.pi * 140 * t) * 0.5 + np.sin(2 * np.pi * 280 * t) * 0.3) * np.exp(-14.0 * t)
    crash = noise(dur) * np.exp(-25.0 * t) * 0.7
    write_wav(os.path.join(out_dir, "container_crash.wav"), sub + body + crash)

    # stamp_thud.wav: giant bureaucratic rubber/steel tariff stamp impact
    dur = 0.8
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    thud = np.sin(2 * np.pi * 85 * t) * np.exp(-16.0 * t) * 0.85
    snap = noise(dur) * np.exp(-65.0 * t) * 0.5
    write_wav(os.path.join(out_dir, "stamp_thud.wav"), thud + snap)

    # paper_flutter.wav: executive order tariff papers rustling
    dur = 0.85
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur) * (0.5 + 0.5 * np.sin(2 * np.pi * 16.0 * t)) * np.exp(-3.5 * t) * 0.7
    write_wav(os.path.join(out_dir, "paper_flutter.wav"), sig)

    # usa_chant.wav: roaring rally crowd chanting "U-S-A!"
    dur = 2.4
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    # Three chants: "U" (0.2s), "S" (0.8s), "A" (1.4s)
    for ct, f1, f2 in [(0.2, 350.0, 700.0), (0.8, 450.0, 900.0), (1.4, 550.0, 1100.0)]:
        idx = int(ct * SAMPLE_RATE)
        rem = min(int(0.45 * SAMPLE_RATE), len(t) - idx)
        st = np.linspace(0, rem/SAMPLE_RATE, rem)
        vox = (np.sin(2*np.pi*f1*st)*0.4 + np.sin(2*np.pi*f2*st)*0.3 + noise(rem/SAMPLE_RATE)*0.35) * np.sin(np.pi * st / (rem/SAMPLE_RATE))
        sig[idx:idx+rem] += vox
    write_wav(os.path.join(out_dir, "usa_chant.wav"), sig)

    # victory.wav: triumphant brass presidential march fanfare
    dur = 2.5
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    notes = [261.63, 329.63, 392.0, 523.25] # C major
    sig = np.zeros_like(t)
    for i, n in enumerate(notes):
        idx = int(i * 0.35 * SAMPLE_RATE)
        rem = len(t) - idx
        if rem > 0:
            nt = t[:rem]
            sig[idx:] += (np.sin(2*np.pi*n*nt) + 0.3*np.sin(4*np.pi*n*nt)) * np.exp(-3.5 * nt) * 0.45
    write_wav(os.path.join(out_dir, "victory.wav"), sig)

def make_jensen_supers(out_dir: str):
    # whoosh.wav: supersonic acceleration whoosh
    dur = 0.8
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = noise(dur, 'pink') * np.sin(np.pi * t / dur)**2 * 0.9
    write_wav(os.path.join(out_dir, "whoosh.wav"), sig)

    # tornado.wav: vortex of graphics computing wind
    dur = 1.8
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    mod = 0.6 + 0.4 * np.sin(2 * np.pi * 5.0 * t)
    sig = noise(dur, 'pink') * mod
    sig = apply_envelope(sig, 0.25, 0.4)
    write_wav(os.path.join(out_dir, "tornado.wav"), sig)

    # gpu_sparks.wav: raytracing electric arc discharge
    dur = 0.65
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = (noise(dur) * 0.7 + np.sin(2 * np.pi * 1200 * t) * 0.3) * np.exp(-8.0 * t)
    write_wav(os.path.join(out_dir, "gpu_sparks.wav"), sig)

    # victory.wav: hyper-tempo cyber victory fanfare
    dur = 2.2
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    notes = [329.63, 440.0, 554.37, 659.25] # E major
    sig = np.zeros_like(t)
    for i, n in enumerate(notes):
        idx = int(i * 0.3 * SAMPLE_RATE)
        rem = len(t) - idx
        if rem > 0:
            nt = t[:rem]
            sig[idx:] += np.sin(2*np.pi*n*nt) * np.exp(-4.5 * nt) * 0.5
    write_wav(os.path.join(out_dir, "victory.wav"), sig)

def make_zuckerbot_supers(out_dir: str):
    # vr_powerup.wav: metaverse headset boot rising resonance
    dur = 1.2
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = sweep(180.0, 880.0, dur) * (0.7 + 0.3 * np.sin(2 * np.pi * 8 * t))
    sig = apply_envelope(sig, 0.15, 0.25)
    write_wav(os.path.join(out_dir, "vr_powerup.wav"), sig)

    # digital_glitch.wav: matrix packet glitch stutter
    dur = 0.5
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    for i in range(10):
        st = i * 0.05
        idx = int(st * SAMPLE_RATE)
        l = int(0.04 * SAMPLE_RATE)
        f = 400.0 + (i * 270) % 1800
        sig[idx:idx+l] = np.sin(2 * np.pi * f * t[:l]) * 0.7
    write_wav(os.path.join(out_dir, "digital_glitch.wav"), sig)

    # teleport.wav: avatar desync and instant relocation
    dur = 0.6
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = sweep(900.0, 150.0, dur) * np.exp(-4.0 * t) * 0.8
    write_wav(os.path.join(out_dir, "teleport.wav"), sig)

    # victory.wav: 8-bit synthetic algorithmic victory stinger
    dur = 2.0
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    notes = [523.25, 659.25, 783.99, 1046.50]
    sig = np.zeros_like(t)
    for i, n in enumerate(notes):
        idx = int(i * 0.25 * SAMPLE_RATE)
        rem = len(t) - idx
        if rem > 0:
            nt = t[:rem]
            # Square wave for 8-bit feel
            sig[idx:] += np.sign(np.sin(2*np.pi*n*nt)) * np.exp(-5.0 * nt) * 0.35
    write_wav(os.path.join(out_dir, "victory.wav"), sig)

def make_sundar_supers(out_dir: str):
    # keyboard_typing.wav: mechanical clicky switches rapid typing
    dur = 1.0
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    rng = np.random.default_rng(1234)
    for _ in range(14):
        pos = rng.uniform(0.02, 0.95)
        idx = int(pos * SAMPLE_RATE)
        l = min(int(0.015 * SAMPLE_RATE), len(t) - idx)
        if l > 0:
            lt = np.linspace(0, l/SAMPLE_RATE, l)
            click = (noise(l/SAMPLE_RATE)*0.6 + np.sin(2*np.pi*3600*lt)*0.4) * np.exp(-120.0 * lt)
            sig[idx:idx+l] += click * rng.uniform(0.5, 0.85)
    write_wav(os.path.join(out_dir, "keyboard_typing.wav"), sig / (np.max(np.abs(sig)) + 1e-6))

    # error_beep.wav: 404 context window prompt error double beep
    dur = 0.45
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    b_len = int(0.12 * SAMPLE_RATE)
    sig[:b_len] = np.sin(2 * np.pi * 480 * t[:b_len]) * 0.7
    gap = int(0.08 * SAMPLE_RATE)
    sig[b_len+gap:2*b_len+gap] = np.sin(2 * np.pi * 480 * t[:b_len]) * 0.7
    write_wav(os.path.join(out_dir, "error_beep.wav"), sig)

    # search_query.wav: harmonic autocomplete confirmation chime
    dur = 0.6
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = (np.sin(2 * np.pi * 1046.5 * t) * 0.4 + np.sin(2 * np.pi * 1318.5 * t) * 0.4) * np.exp(-8.0 * t)
    write_wav(os.path.join(out_dir, "search_query.wav"), sig)

    # victory.wav: clean friendly product announcement fanfare
    dur = 2.2
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    notes = [392.0, 523.25, 659.25, 783.99] # G C E G
    sig = np.zeros_like(t)
    for i, n in enumerate(notes):
        idx = int(i * 0.3 * SAMPLE_RATE)
        rem = len(t) - idx
        if rem > 0:
            nt = t[:rem]
            sig[idx:] += np.sin(2*np.pi*n*nt) * np.exp(-4.0 * nt) * 0.45
    write_wav(os.path.join(out_dir, "victory.wav"), sig)

def make_xi_supers(out_dir: str):
    # footsteps_sprint.wav: rapid sprint strides
    dur = 1.1
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    for i in range(6):
        idx = int(i * 0.16 * SAMPLE_RATE)
        l = min(int(0.06 * SAMPLE_RATE), len(t) - idx)
        lt = np.linspace(0, l/SAMPLE_RATE, l)
        step = (np.sin(2 * np.pi * 110 * lt) * 0.6 + noise(l/SAMPLE_RATE) * 0.4) * np.exp(-35.0 * lt)
        sig[idx:idx+l] += step * 0.8
    write_wav(os.path.join(out_dir, "footsteps_sprint.wav"), sig)

    # punch_flurry.wav: rapid wing chun punch flurry
    dur = 1.2
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    sig = np.zeros_like(t)
    for i in range(8):
        idx = int(i * 0.13 * SAMPLE_RATE)
        l = min(int(0.08 * SAMPLE_RATE), len(t) - idx)
        lt = np.linspace(0, l/SAMPLE_RATE, l)
        swoosh = noise(l/SAMPLE_RATE) * np.sin(np.pi * lt / (l/SAMPLE_RATE)) * 0.5
        impact = np.sin(2 * np.pi * 160 * lt) * np.exp(-50.0 * lt) * 0.5
        sig[idx:idx+l] += swoosh + impact
    write_wav(os.path.join(out_dir, "punch_flurry.wav"), sig)

    # gong_strike.wav: deep ceremonial gong strike with long shimmery wash
    dur = 2.5
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    gong = (np.sin(2 * np.pi * 180 * t) * 0.4 +
            np.sin(2 * np.pi * 370 * t) * 0.3 +
            np.sin(2 * np.pi * 560 * t) * 0.2 +
            np.sin(2 * np.pi * 840 * t) * 0.1) * np.exp(-2.5 * t)
    crash = noise(dur) * np.exp(-18.0 * t) * 0.35
    write_wav(os.path.join(out_dir, "gong_strike.wav"), gong + crash)

    # victory.wav: grand martial victory stinger
    dur = 2.4
    t = np.linspace(0, dur, int(dur * SAMPLE_RATE), endpoint=False)
    notes = [293.66, 369.99, 440.0, 587.33] # D major
    sig = np.zeros_like(t)
    for i, n in enumerate(notes):
        idx = int(i * 0.32 * SAMPLE_RATE)
        rem = len(t) - idx
        if rem > 0:
            nt = t[:rem]
            sig[idx:] += (np.sin(2*np.pi*n*nt) + 0.3*np.sin(3*np.pi*n*nt)) * np.exp(-3.5 * nt) * 0.5
    write_wav(os.path.join(out_dir, "victory.wav"), sig)

def main():
    print("Generating stage audio assets (Task G5)...")
    make_mensa_sounds("assets/audio/stage/mensa")
    make_senate_sounds("assets/audio/stage/senate")
    make_server_farm_sounds("assets/audio/stage/server_farm")
    make_foundry_sounds("assets/audio/stage/foundry")

    print("Generating super & victory audio assets (Task G7)...")
    make_tesla_supers("assets/audio/supers/tesla")
    make_donald_supers("assets/audio/supers/donald")
    make_jensen_supers("assets/audio/supers/jensen")
    make_zuckerbot_supers("assets/audio/supers/zuckerbot")
    make_sundar_supers("assets/audio/supers/sundar")
    make_xi_supers("assets/audio/supers/xi")
    print("All audio assets successfully generated!")

if __name__ == "__main__":
    main()
