#!/usr/bin/env python3
"""Generate authentic, high-quality OGG Vorbis super voice/shout audio files
for the 11 AI Showdown parody fighters, compute 60 FPS mouth loudness envelopes,
and update assets/audio/voice/fighters/mouth.json.
"""

import json
import math
import pathlib
import numpy as np
import soundfile as sf

ROOT = pathlib.Path(__file__).resolve().parent.parent
VOICE_DIR = ROOT / "assets" / "audio" / "voice" / "fighters"
MOUTH_JSON = VOICE_DIR / "mouth.json"
SR = 44100
FPS = 60
RATE = 12000
GATE = 0.12
RELEASE = 0.75


# --- DSP Helper Functions ---

def fft_filter(sig: np.ndarray, low_hz: float = None, high_hz: float = None, sr: int = SR, roll: float = 60.0) -> np.ndarray:
    """Frequency-domain brickwall filter with smooth cosine rolloff edges."""
    n = len(sig)
    X = np.fft.rfft(sig)
    freqs = np.fft.rfftfreq(n, 1.0 / sr)
    gain = np.ones_like(freqs, dtype=np.float32)
    if low_hz is not None:
        taper = np.clip((freqs - (low_hz - roll)) / roll, 0.0, 1.0)
        gain *= 0.5 * (1.0 - np.cos(np.pi * taper))
    if high_hz is not None:
        taper = np.clip(((high_hz + roll) - freqs) / roll, 0.0, 1.0)
        gain *= 0.5 * (1.0 - np.cos(np.pi * taper))
    return np.fft.irfft(X * gain, n=n).astype(np.float32)


def normalize(sig: np.ndarray, target_peak: float = 0.75) -> np.ndarray:
    """Normalize peak amplitude to target_peak (approx -2.5 dBFS) to prevent clipping."""
    peak = np.max(np.abs(sig))
    if peak > 1e-6:
        return (sig / peak * target_peak).astype(np.float32)
    return sig.astype(np.float32)


def envelope_decay(t: np.ndarray, t_start: float, decay_rate: float) -> np.ndarray:
    """Exponential decay starting at t_start."""
    env = np.zeros_like(t)
    mask = t >= t_start
    env[mask] = np.exp(-decay_rate * (t[mask] - t_start))
    return env


def adsr(t: np.ndarray, a: float, d: float, s: float, r: float, total_dur: float) -> np.ndarray:
    """ADSR amplitude envelope."""
    env = np.zeros_like(t)
    for i, ti in enumerate(t):
        if ti < a:
            env[i] = ti / a if a > 0 else 1.0
        elif ti < a + d:
            env[i] = 1.0 - (1.0 - s) * ((ti - a) / d) if d > 0 else s
        elif ti < total_dur - r:
            env[i] = s
        elif ti < total_dur:
            env[i] = s * (1.0 - (ti - (total_dur - r)) / r) if r > 0 else 0.0
        else:
            env[i] = 0.0
    return env


# --- 11 Fighter Super Sound Synthesizers ---

def synth_ram() -> np.ndarray:
    """ram (Scaling Law): compute surge / power hum / high-voltage charging tone."""
    dur = 1.70
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: Sub/bass datacenter power hum ramping up from 60 Hz to 240 Hz
    freq_ramp = 60.0 + 180.0 * (t / dur) ** 1.8
    phase_sub = 2.0 * np.pi * np.cumsum(freq_ramp) / SR
    sub_hum = (
        0.50 * np.sin(phase_sub)
        + 0.30 * np.sin(2.0 * phase_sub)
        + 0.15 * np.sin(3.0 * phase_sub)
    )
    env_sub = adsr(t, 0.15, 0.4, 0.8, 0.35, dur)
    layer1 = sub_hum * env_sub

    # Layer 2: Ascending high-voltage charging FM tone
    carrier_freq = 350.0 + 1250.0 * (t / dur) ** 2.0
    mod_freq = 120.0 + 80.0 * (t / dur)
    mod_index = 1.5 + 4.0 * (t / dur)
    phase_mod = 2.0 * np.pi * np.cumsum(mod_freq) / SR
    phase_car = 2.0 * np.pi * np.cumsum(carrier_freq) / SR
    charging_tone = np.sin(phase_car + mod_index * np.sin(phase_mod))
    env_charge = adsr(t, 0.10, 0.5, 0.9, 0.30, dur)
    layer2 = charging_tone * env_charge * 0.45

    # Layer 3: Datacenter cooling surge and high-voltage spark hiss
    noise = np.random.normal(0, 1, n).astype(np.float32)
    spark_noise = fft_filter(noise, low_hz=1800.0, high_hz=7500.0, sr=SR)
    stutter = 0.5 + 0.5 * np.sin(2.0 * np.pi * 32.0 * t)
    env_surge = np.exp(-((t - 0.85) / 0.45) ** 2)
    layer3 = spark_noise * stutter * env_surge * 0.35

    mix = layer1 + layer2 + layer3
    return normalize(mix)


def synth_tesla() -> np.ndarray:
    """tesla (Rocket Launch): rocket booster ignition roar and rumble."""
    dur = 1.80
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: LOX cryogenic vent hiss (0.0s to 0.45s)
    noise1 = np.random.normal(0, 1, n).astype(np.float32)
    vent_hiss = fft_filter(noise1, low_hz=2200.0, high_hz=6000.0, sr=SR)
    env_vent = np.clip(1.0 - (t / 0.45), 0.0, 1.0) * (0.5 + 0.5 * np.sin(2.0 * np.pi * 40.0 * t))
    layer1 = vent_hiss * env_vent * 0.40

    # Layer 2: Main engine ignition blast at t = 0.42s
    t_blast = 0.42
    blast_pitch = 140.0 * np.exp(-8.0 * np.maximum(0.0, t - t_blast)) + 45.0
    blast_phase = 2.0 * np.pi * np.cumsum(blast_pitch) / SR
    blast_sub = np.sin(blast_phase) * envelope_decay(t, t_blast, 4.5)
    layer2 = blast_sub * 0.65

    # Layer 3: Sustained rocket booster roar (heavy turbulent rumble)
    noise2 = np.random.normal(0, 1, n).astype(np.float32)
    low_rumble = fft_filter(noise2, low_hz=35.0, high_hz=450.0, sr=SR)
    flutter = 0.6 + 0.4 * np.sin(2.0 * np.pi * 18.0 * t) * np.sin(2.0 * np.pi * 27.0 * t)
    env_roar = adsr(t, 0.45, 0.2, 0.9, 0.40, dur)
    layer3 = low_rumble * flutter * env_roar * 0.75

    # Layer 4: Supersonic jet exhaust scream & crackle
    noise3 = np.random.normal(0, 1, n).astype(np.float32)
    jet_scream = fft_filter(noise3, low_hz=600.0, high_hz=3000.0, sr=SR)
    spikes = (np.random.random(n) > 0.985).astype(np.float32) * np.random.normal(0, 1, n)
    spikes_filtered = fft_filter(spikes, low_hz=1500.0, high_hz=8000.0, sr=SR)
    layer4 = (jet_scream * 0.4 + spikes_filtered * 0.5) * env_roar * 0.50

    mix = layer1 + layer2 + layer3 + layer4
    return normalize(mix)


def synth_dario() -> np.ndarray:
    """dario (Constitutional Shield): resonant harmonic chime / defensive barrier hum."""
    dur = 1.65
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: Crystalline glass/bell chime chord (D-major: D4, F#4, A4, D5, F#5)
    chord_freqs = [293.66, 369.99, 440.00, 587.33, 739.99, 1174.66]
    bell_mix = np.zeros(n, dtype=np.float32)
    for freq in chord_freqs:
        # Fundamental and inharmonic crystal partials
        part1 = np.sin(2.0 * np.pi * freq * t) * envelope_decay(t, 0.05, 2.2)
        part2 = np.sin(2.0 * np.pi * freq * 2.756 * t) * envelope_decay(t, 0.05, 4.0) * 0.35
        part3 = np.sin(2.0 * np.pi * freq * 5.404 * t) * envelope_decay(t, 0.05, 6.5) * 0.15
        bell_mix += part1 + part2 + part3
    layer1 = bell_mix * 0.30

    # Layer 2: Warm defensive barrier hum (D3 146.83 Hz with slow chorus detune)
    hum_f1 = 146.83
    hum_f2 = 147.95
    hum_sub = 73.42
    drone = (
        0.50 * np.sin(2.0 * np.pi * hum_f1 * t)
        + 0.40 * np.sin(2.0 * np.pi * hum_f2 * t)
        + 0.30 * np.sin(2.0 * np.pi * hum_sub * t)
    )
    env_drone = adsr(t, 0.15, 0.3, 0.85, 0.35, dur)
    layer2 = drone * env_drone * 0.50

    # Layer 3: Shimmering protective resonance (high-frequency safety shimmer)
    shimmer_freq = 2349.32  # D7
    tremolo = 0.5 + 0.5 * np.sin(2.0 * np.pi * 5.5 * t)
    layer3 = np.sin(2.0 * np.pi * shimmer_freq * t) * tremolo * env_drone * 0.12

    mix = layer1 + layer2 + layer3
    return normalize(mix)


def synth_zuckerbot() -> np.ndarray:
    """zuckerbot (Metaverse Trap): digital modem chirp, VR spatial glitch, robotic bleeps."""
    dur = 1.75
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: 56k dialup modem handshake chirps (FSK bursts 0.0s to 0.65s)
    fsk = np.zeros(n, dtype=np.float32)
    step_samples = int(SR * 0.04)
    tones = [1200, 2400, 980, 1800, 2225, 1200, 2400, 3000, 1800, 2400, 1200, 980, 1800, 2400]
    for idx, tone in enumerate(tones):
        s_start = idx * step_samples
        s_end = min(n, s_start + step_samples)
        if s_start < n:
            tt = t[s_start:s_end] - t[s_start]
            fsk[s_start:s_end] = np.sin(2.0 * np.pi * tone * tt) * (0.8 + 0.2 * np.sign(np.sin(2.0 * np.pi * tone * tt)))
    layer1 = fsk * 0.40

    # Layer 2: Fast 8-bit VR glitch arpeggios (chiptune stepped scale)
    glitch = np.zeros(n, dtype=np.float32)
    arp_notes = [440, 554, 659, 880, 1108, 1318, 1760, 2217]
    arp_step = int(SR * 0.025)
    for i in range(int(0.65 * SR), int(1.40 * SR), arp_step):
        note = arp_notes[(i // arp_step) % len(arp_notes)]
        i_end = min(n, i + arp_step)
        tt = t[i:i_end] - t[i]
        glitch[i:i_end] = np.sign(np.sin(2.0 * np.pi * note * tt))  # square wave
    # 6-bit quantization (bitcrush)
    glitch_quant = np.round(glitch * 32.0) / 32.0
    layer2 = glitch_quant * 0.30

    # Layer 3: Robotic ring-modulator monotone
    carrier = np.sin(2.0 * np.pi * 125.0 * t)
    mod = np.sign(np.sin(2.0 * np.pi * 48.0 * t))
    env_bot = adsr(t, 0.05, 0.2, 0.7, 0.4, dur)
    layer3 = carrier * mod * env_bot * 0.35

    # Layer 4: Trap grab impact at t = 0.72s
    t_grab = 0.72
    thump = np.sin(2.0 * np.pi * 65.0 * t) * envelope_decay(t, t_grab, 8.0)
    layer4 = thump * 0.60

    mix = layer1 + layer2 + layer3 + layer4
    return normalize(mix)


def synth_jensen() -> np.ndarray:
    """jensen (GPU Rain): spooling turbine fans, high-frequency coil whine, electric spark."""
    dur = 1.70
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: Server turbine cooling fan spool-up (400 Hz -> 2600 Hz)
    fan_freq = 400.0 + 2200.0 * (t / dur) ** 2.2
    fan_phase = 2.0 * np.pi * np.cumsum(fan_freq) / SR
    fan_whine = (
        0.50 * np.sin(fan_phase)
        + 0.35 * np.sin(2.0 * fan_phase)
        + 0.20 * np.sin(3.0 * fan_phase)
    )
    noise_fan = np.random.normal(0, 1, n).astype(np.float32)
    fan_air = fft_filter(noise_fan, low_hz=600.0, high_hz=3200.0, sr=SR)
    env_fan = adsr(t, 0.15, 0.4, 0.85, 0.30, dur)
    layer1 = (fan_whine * 0.6 + fan_air * 0.4) * env_fan * 0.55

    # Layer 2: High-frequency GPU coil whine (6200 Hz & 7800 Hz with micro-ripple)
    ripple = 1.0 + 0.08 * np.sin(2.0 * np.pi * 120.0 * t)
    coil1 = np.sin(2.0 * np.pi * 6200.0 * t) * ripple
    coil2 = np.sin(2.0 * np.pi * 7800.0 * t) * ripple
    layer2 = (coil1 + coil2) * env_fan * 0.25

    # Layer 3: High-voltage electric spark arcs across 0.6s to 1.3s
    sparks = np.zeros(n, dtype=np.float32)
    spark_times = [0.62, 0.74, 0.85, 0.93, 1.05, 1.14, 1.25]
    for st in spark_times:
        s_idx = int(st * SR)
        s_len = int(0.02 * SR)
        if s_idx + s_len < n:
            burst = np.random.normal(0, 1, s_len) * np.exp(-np.linspace(0, 8, s_len))
            sparks[s_idx:s_idx + s_len] += burst
    sparks_filt = fft_filter(sparks, low_hz=2500.0, high_hz=10000.0, sr=SR)
    layer3 = sparks_filt * 0.45

    # Layer 4: Datacenter power sub-bass foundation
    sub = np.sin(2.0 * np.pi * 85.0 * t) * env_fan
    layer4 = sub * 0.40

    mix = layer1 + layer2 + layer3 + layer4
    return normalize(mix)


def synth_yann() -> np.ndarray:
    """yann (It's Just Autocomplete): rapid typewriter/keyboard clacks + dismissive synth buzz."""
    dur = 1.65
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: Rapid mechanical keyboard keypresses (8 rapid keystrokes)
    keys = np.zeros(n, dtype=np.float32)
    key_times = [0.06, 0.14, 0.21, 0.29, 0.36, 0.44, 0.51, 0.59]
    for kt in key_times:
        k_idx = int(kt * SR)
        k_len = int(0.035 * SR)
        if k_idx + k_len < n:
            kt_sub = np.linspace(0, 0.035, k_len, endpoint=False)
            click = np.random.normal(0, 1, k_len) * np.exp(-kt_sub * 250.0)
            ping = np.sin(2.0 * np.pi * 2100.0 * kt_sub) * np.exp(-kt_sub * 120.0)
            thud = np.sin(2.0 * np.pi * 320.0 * kt_sub) * np.exp(-kt_sub * 80.0)
            keys[k_idx:k_idx + k_len] += click * 0.6 + ping * 0.3 + thud * 0.4
    layer1 = keys * 0.70

    # Layer 2: Heavy spacebar / carriage return slam at t = 0.68s
    t_space = 0.68
    s_idx = int(t_space * SR)
    s_len = int(0.08 * SR)
    spacebar = np.zeros(n, dtype=np.float32)
    if s_idx + s_len < n:
        st_sub = np.linspace(0, 0.08, s_len, endpoint=False)
        slam_click = np.random.normal(0, 1, s_len) * np.exp(-st_sub * 150.0)
        slam_thump = np.sin(2.0 * np.pi * 120.0 * st_sub) * np.exp(-st_sub * 40.0)
        spacebar[s_idx:s_idx + s_len] = slam_click * 0.5 + slam_thump * 0.8
    layer2 = spacebar * 0.75

    # Layer 3: Dismissive "Bof!" scoff buzz (downward sliding filtered sawtooth)
    t_buzz = 0.75
    buzz_len = dur - t_buzz
    buzz_mask = t >= t_buzz
    tt_buzz = t[buzz_mask] - t_buzz
    # Descending frequency 280 Hz -> 85 Hz
    freq_buzz = 280.0 * np.exp(-tt_buzz * 2.8) + 85.0
    phase_buzz = 2.0 * np.pi * np.cumsum(freq_buzz) / SR
    # Sawtooth wave approximation
    saw = np.zeros_like(tt_buzz)
    for h in range(1, 12):
        saw += (1.0 / h) * np.sin(h * phase_buzz)
    # Formant filter around 800 Hz and 1300 Hz
    saw_filtered = fft_filter(saw, low_hz=300.0, high_hz=1600.0, sr=SR)
    env_buzz = np.exp(-tt_buzz * 2.5) * (1.0 - np.exp(-tt_buzz * 30.0))
    layer3 = np.zeros(n, dtype=np.float32)
    layer3[buzz_mask] = saw_filtered * env_buzz * 0.60

    mix = layer1 + layer2 + layer3
    return normalize(mix)


def synth_geoff() -> np.ndarray:
    """geoff (I Regret Nothing... Wait): pulsing existential Klaxon siren descending into hesitation tone."""
    dur = 1.80
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: Urgent existential Klaxon alarm (0.0s to 0.72s: alternating 880 / 660 Hz with fast warble)
    alarm_mask = t < 0.72
    alarm_sig = np.zeros(n, dtype=np.float32)
    t_alarm = t[alarm_mask]
    # Alternating high/low tone every 0.12s
    tone_step = (t_alarm / 0.12).astype(int) % 2
    carrier_freq = np.where(tone_step == 0, 880.0, 660.0)
    # 8 Hz warble modulation
    warble = 1.0 + 0.08 * np.sin(2.0 * np.pi * 8.0 * t_alarm)
    phase_alarm = 2.0 * np.pi * np.cumsum(carrier_freq * warble) / SR
    siren = (
        0.60 * np.sin(phase_alarm)
        + 0.30 * np.sin(2.0 * phase_alarm)
        + 0.15 * np.sin(3.0 * phase_alarm)
    )
    alarm_sig[alarm_mask] = siren * 0.65
    layer1 = alarm_sig

    # Layer 2: Abrupt stop & inquisitive hesitation downward glissando ("Wait...": 420 Hz -> 170 Hz)
    t_wait = 0.74
    wait_mask = t >= t_wait
    wait_sig = np.zeros(n, dtype=np.float32)
    tt_wait = t[wait_mask] - t_wait
    freq_wait = 420.0 * np.exp(-tt_wait * 1.8) + 160.0
    wobble = 1.0 + 0.04 * np.sin(2.0 * np.pi * 6.0 * tt_wait)
    phase_wait = 2.0 * np.pi * np.cumsum(freq_wait * wobble) / SR
    sine_wait = np.sin(phase_wait) + 0.25 * np.sin(2.0 * phase_wait)
    env_wait = np.exp(-tt_wait * 2.2) * (1.0 - np.exp(-tt_wait * 25.0))
    wait_sig[wait_mask] = sine_wait * env_wait * 0.55
    layer2 = wait_sig

    # Layer 3: Resigned sigh / low drone decay
    noise = np.random.normal(0, 1, n).astype(np.float32)
    sigh = fft_filter(noise, low_hz=200.0, high_hz=900.0, sr=SR)
    env_sigh = np.clip((t - 1.0) / 0.7, 0.0, 1.0) * np.exp(-(t - 1.0) * 2.0)
    layer3 = sigh * env_sigh * 0.25

    mix = layer1 + layer2 + layer3
    return normalize(mix)


def synth_sundar() -> np.ndarray:
    """sundar (Search Result): crisp multi-tone UI notification / clean upbeat search ding."""
    dur = 1.55
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: Pristine 4-note ascending marimba/chime arpeggio (C5, E5, G5, C6)
    arpeggio = np.zeros(n, dtype=np.float32)
    notes = [
        (0.00, 523.25),  # C5
        (0.12, 659.25),  # E5
        (0.24, 783.99),  # G5
        (0.36, 1046.50), # C6
    ]
    for start_t, freq in notes:
        s_idx = int(start_t * SR)
        tt = t[s_idx:] - start_t
        note_sig = (
            np.sin(2.0 * np.pi * freq * tt)
            + 0.35 * np.sin(2.0 * np.pi * freq * 2.0 * tt)
            + 0.12 * np.sin(2.0 * np.pi * freq * 3.0 * tt)
        ) * np.exp(-tt * 4.5)
        arpeggio[s_idx:] += note_sig
    layer1 = arpeggio * 0.45

    # Layer 2: "Search Complete" glass ding (E6 1318.5 Hz + overtone 1975.5 Hz)
    t_ding = 0.50
    d_idx = int(t_ding * SR)
    ding = np.zeros(n, dtype=np.float32)
    tt_ding = t[d_idx:] - t_ding
    ding_sig = (
        np.sin(2.0 * np.pi * 1318.5 * tt_ding)
        + 0.50 * np.sin(2.0 * np.pi * 1975.5 * tt_ding)
        + 0.25 * np.sin(2.0 * np.pi * 2637.0 * tt_ding)
    ) * np.exp(-tt_ding * 2.5)
    ding[d_idx:] = ding_sig
    layer2 = ding * 0.50

    # Layer 3: Warm corporate acoustic ripple foundation
    sub_c = np.sin(2.0 * np.pi * 261.63 * t) * adsr(t, 0.1, 0.4, 0.7, 0.4, dur)
    layer3 = sub_c * 0.30

    mix = layer1 + layer2 + layer3
    return normalize(mix)


def synth_donald() -> np.ndarray:
    """donald (Shower of Tariffs): heavy wooden gavel impact followed by metallic gold coin cascade."""
    dur = 1.80
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: Double courtroom wooden gavel strike (t = 0.08s, t = 0.32s)
    gavels = np.zeros(n, dtype=np.float32)
    for gt in [0.08, 0.32]:
        g_idx = int(gt * SR)
        g_len = int(0.06 * SR)
        if g_idx + g_len < n:
            tt = np.linspace(0, 0.06, g_len, endpoint=False)
            noise_burst = np.random.normal(0, 1, g_len) * np.exp(-tt * 180.0)
            noise_filt = fft_filter(noise_burst, low_hz=300.0, high_hz=1400.0, sr=SR)
            oak_thump = np.sin(2.0 * np.pi * 180.0 * tt) * np.exp(-tt * 60.0)
            desk_sub = np.sin(2.0 * np.pi * 65.0 * tt) * np.exp(-tt * 40.0)
            gavels[g_idx:g_idx + g_len] += noise_filt * 0.7 + oak_thump * 0.6 + desk_sub * 0.7
    layer1 = gavels * 0.70

    # Layer 2: Cash register bell chime at t = 0.42s
    t_bell = 0.42
    b_idx = int(t_bell * SR)
    bell = np.zeros(n, dtype=np.float32)
    tt_b = t[b_idx:] - t_bell
    bell_sig = (
        np.sin(2.0 * np.pi * 2200.0 * tt_b)
        + 0.50 * np.sin(2.0 * np.pi * 4400.0 * tt_b)
    ) * np.exp(-tt_b * 6.0)
    bell[b_idx:] = bell_sig
    layer2 = bell * 0.40

    # Layer 3: Shower of metallic gold coins cascading (hundreds of resonant metallic pings)
    coins = np.zeros(n, dtype=np.float32)
    rng = np.random.RandomState(42)  # reproducible deterministic cascade
    num_coins = 120
    coin_times = rng.uniform(0.48, 1.65, num_coins)
    coin_freqs = rng.choice([3200, 3600, 4100, 4800, 5400, 6200, 7100], num_coins)
    for ct, cf in zip(coin_times, coin_freqs):
        c_idx = int(ct * SR)
        c_len = int(0.04 * SR)
        if c_idx + c_len < n:
            tt_c = np.linspace(0, 0.04, c_len, endpoint=False)
            ping = np.sin(2.0 * np.pi * cf * tt_c) * np.exp(-tt_c * 100.0)
            coins[c_idx:c_idx + c_len] += ping * rng.uniform(0.2, 0.6)
    layer3 = coins * 0.45

    mix = layer1 + layer2 + layer3
    return normalize(mix)


def synth_xi() -> np.ndarray:
    """xi (Great Firewall): deep resonant temple gong and low hum barrier."""
    dur = 1.75
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: Resonant bronze temple gong at t = 0.04s
    t_gong = 0.04
    g_idx = int(t_gong * SR)
    gong = np.zeros(n, dtype=np.float32)
    tt_g = t[g_idx:] - t_gong
    # Gong physical inharmonic partials
    partials = [
        (108.0, 1.00, 1.8),
        (174.0, 0.65, 2.2),
        (276.0, 0.50, 2.8),
        (412.0, 0.40, 3.5),
        (650.0, 0.30, 4.2),
        (890.0, 0.20, 5.0),
        (1220.0, 0.15, 6.0),
    ]
    gong_sig = np.zeros_like(tt_g)
    for freq, amp, dec in partials:
        # Subtle modal beating
        beat = 1.0 + 0.15 * np.sin(2.0 * np.pi * 3.5 * tt_g)
        gong_sig += amp * np.sin(2.0 * np.pi * freq * tt_g) * np.exp(-tt_g * dec) * beat
    # Initial mallet strike transient
    strike = np.random.normal(0, 1, len(tt_g)) * np.exp(-tt_g * 45.0)
    strike_filt = fft_filter(strike, low_hz=80.0, high_hz=600.0, sr=SR)
    gong_sig += strike_filt * 0.5
    gong[g_idx:] = gong_sig
    layer1 = gong * 0.55

    # Layer 2: Imposing firewall perimeter bass hum (72 Hz + 144 Hz)
    f_hum = 72.0
    wall_hum = (
        0.55 * np.sin(2.0 * np.pi * f_hum * t)
        + 0.35 * np.sin(2.0 * np.pi * (2.0 * f_hum) * t)
        + 0.15 * np.sin(2.0 * np.pi * (3.0 * f_hum) * t)
    )
    env_wall = adsr(t, 0.10, 0.4, 0.85, 0.35, dur)
    layer2 = wall_hum * env_wall * 0.45

    # Layer 3: High-tech packet filter shimmer
    noise = np.random.normal(0, 1, n).astype(np.float32)
    packet_shimmer = fft_filter(noise, low_hz=3500.0, high_hz=9000.0, sr=SR)
    gate_flutter = 0.5 + 0.5 * np.sin(2.0 * np.pi * 25.0 * t)
    layer3 = packet_shimmer * gate_flutter * env_wall * 0.15

    mix = layer1 + layer2 + layer3
    return normalize(mix)


def synth_algorithm() -> np.ndarray:
    """algorithm (Engagement Loop): hypnotic Shepard-tone sweep and multi-layered dopamine notification ping."""
    dur = 1.75
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Layer 1: Hypnotic infinite ascending Shepard tone sweep across 5 octaves
    shepard = np.zeros(n, dtype=np.float32)
    # Pitch rises exponentially by one full octave over duration
    pitch_sweep = 2.0 ** (t / dur)
    base_freqs = [55.0, 110.0, 220.0, 440.0, 880.0, 1760.0]
    center_freq = 440.0
    sigma = 1.5  # octaves
    for f0 in base_freqs:
        current_freq = f0 * pitch_sweep
        phase = 2.0 * np.pi * np.cumsum(current_freq) / SR
        # Spectral bell envelope in octave distance from center
        octave_dist = np.log2(current_freq / center_freq)
        gain = np.exp(-0.5 * (octave_dist / sigma) ** 2)
        shepard += gain * np.sin(phase)
    env_shep = adsr(t, 0.2, 0.4, 0.85, 0.30, dur)
    layer1 = shepard * env_shep * 0.45

    # Layer 2: Dopamine push notification chimes (two bursts: t = 0.18s, t = 0.70s)
    pings = np.zeros(n, dtype=np.float32)
    for pt, amp in [(0.18, 0.45), (0.70, 0.65)]:
        p_idx = int(pt * SR)
        tt_p = t[p_idx:] - pt
        # Tri-tone modern chime: F#5 (740 Hz), B5 (988 Hz), D#6 (1245 Hz)
        c1 = np.sin(2.0 * np.pi * 739.99 * tt_p) * np.exp(-tt_p * 6.0)
        c2 = np.sin(2.0 * np.pi * 987.77 * tt_p) * np.exp(-tt_p * 5.0)
        c3 = np.sin(2.0 * np.pi * 1244.51 * tt_p) * np.exp(-tt_p * 4.0)
        pings[p_idx:] += (c1 * 0.4 + c2 * 0.4 + c3 * 0.5) * amp
    layer2 = pings * 0.55

    # Layer 3: Hypnotic entrainment sub-bass beat (50 Hz with 10 Hz alpha flutter)
    sub = np.sin(2.0 * np.pi * 50.0 * t) * (0.6 + 0.4 * np.sin(2.0 * np.pi * 10.0 * t))
    layer3 = sub * env_shep * 0.40

    mix = layer1 + layer2 + layer3
    return normalize(mix)


FIGHTER_SYNTHS = {
    "ram": synth_ram,
    "tesla": synth_tesla,
    "dario": synth_dario,
    "zuckerbot": synth_zuckerbot,
    "jensen": synth_jensen,
    "yann": synth_yann,
    "geoff": synth_geoff,
    "sundar": synth_sundar,
    "donald": synth_donald,
    "xi": synth_xi,
    "algorithm": synth_algorithm,
}


# --- Envelope Calculation Matching build_voice_envelopes.py ---

def compute_envelope(samples: np.ndarray, sr: int) -> list[int]:
    """Compute 60 FPS loudness envelope matching tools/build_voice_envelopes.py exactly."""
    # Resample to RATE = 12000
    duration = len(samples) / sr
    target_len = int(round(duration * RATE))
    orig_t = np.linspace(0, duration, len(samples), endpoint=False)
    target_t = np.linspace(0, duration, target_len, endpoint=False)
    samples_12k = np.interp(target_t, orig_t, samples).astype(np.float32)

    hop = RATE // FPS  # 200
    frames = len(samples_12k) // hop + 1
    padded = np.zeros(frames * hop, dtype=np.float32)
    padded[:len(samples_12k)] = samples_12k
    rms = np.sqrt(np.mean(padded.reshape(frames, hop) ** 2, axis=1))
    loud = np.percentile(rms, 95)
    if loud <= 0.0:
        return [0] * frames
    level = np.clip(rms / loud, 0.0, 1.0)
    level = np.clip((level - GATE) / (1.0 - GATE), 0.0, 1.0) ** 0.7
    out = []
    last = 0.0
    for value in level:
        last = max(value, last * RELEASE)
        out.append(int(round(last * 100)))
    return out


def main():
    print("=== Milestone 4 Audio Synthesis & Envelope Generator ===")
    VOICE_DIR.mkdir(parents=True, exist_ok=True)

    # 1. Load existing mouth.json if present
    envelopes = {}
    if MOUTH_JSON.exists():
        envelopes = json.loads(MOUTH_JSON.read_text(encoding="utf-8"))
        print(f"Loaded {len(envelopes)} existing envelopes from mouth.json")

    # 2. Synthesize each fighter's super shout
    for fighter_id, synth_fn in FIGHTER_SYNTHS.items():
        clip_name = f"{fighter_id}_super_1"
        out_path = VOICE_DIR / f"{clip_name}.ogg"

        print(f"Synthesizing {clip_name}...")
        audio = synth_fn()
        sf.write(str(out_path), audio, SR, format="OGG", subtype="VORBIS")

        # Read back written file to ensure exact Vorbis encoding is used for envelope
        read_samples, read_sr = sf.read(str(out_path))
        env = compute_envelope(read_samples, read_sr)
        envelopes[clip_name] = env
        print(f"  -> Wrote {out_path.name} ({len(read_samples)/read_sr:.2f}s, {len(env)} frames, peak {np.max(np.abs(read_samples)):.2f})")

    # 3. Sort keys and write back mouth.json
    sorted_envelopes = {k: envelopes[k] for k in sorted(envelopes.keys())}
    MOUTH_JSON.write_text(json.dumps(sorted_envelopes, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"\nUpdated mouth.json with {len(sorted_envelopes)} total entries.")

    # 4. Verify against all .ogg files in VOICE_DIR
    ogg_files = sorted(p.stem for p in VOICE_DIR.iterdir() if p.suffix == ".ogg")
    print(f"Total .ogg files in {VOICE_DIR}: {len(ogg_files)}")
    missing = set(ogg_files) - set(sorted_envelopes.keys())
    extra = set(sorted_envelopes.keys()) - set(ogg_files)
    if missing:
        print(f"ERROR: Missing envelopes for: {missing}")
    elif extra:
        print(f"ERROR: Extra envelopes not in ogg files: {extra}")
    else:
        print("VERIFICATION SUCCESS: All .ogg clips match mouth.json keys exactly!")


if __name__ == "__main__":
    main()
