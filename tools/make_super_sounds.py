#!/usr/bin/env python3
"""
Procedural sound synthesizer for missing AI Showdown super-scene effects and opening stings.

Generates 44.1 kHz, 16-bit mono PCM WAV files normalized to -1 dBFS in
assets/audio/supers/<fighter>/. Uses only the Python standard library.
"""

from array import array
import math
import os
import random
import re
import wave

SAMPLE_RATE = 44100
TARGET_PEAK = 10.0 ** (-1.0 / 20.0)  # ~ -1.0 dBFS


def make_buffer(duration: float) -> list[float]:
    """Return a zero-initialized sample buffer for `duration` seconds."""
    return [0.0] * max(1, int(round(duration * SAMPLE_RATE)))


def add_into(dst: list[float], src: list[float], start_s: float, gain: float = 1.0) -> None:
    """Mix `src` into `dst` starting at `start_s` seconds."""
    offset = int(round(start_s * SAMPLE_RATE))
    limit = min(len(dst) - offset, len(src))
    for i in range(max(0, -offset), limit):
        dst[offset + i] += src[i] * gain


def normalize_and_fade(
    samples: list[float], fade_in_s: float = 0.006, fade_out_s: float = 0.015
) -> list[float]:
    """Apply endpoint fades to prevent clicks and peak-normalize to -1 dBFS."""
    n = len(samples)
    out = list(samples)
    att = min(n, int(round(fade_in_s * SAMPLE_RATE)))
    rel = min(n, int(round(fade_out_s * SAMPLE_RATE)))
    for i in range(att):
        out[i] *= i / max(1, att)
    for i in range(rel):
        out[n - 1 - i] *= i / max(1, rel)
    peak = max((abs(x) for x in out), default=0.0)
    if peak > 1e-9:
        scale = TARGET_PEAK / peak
        out = [x * scale for x in out]
    return out


def write_wav(path: str, samples: list[float]) -> None:
    """Normalize and write mono 16-bit 44.1 kHz PCM WAV to `path`."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    norm = normalize_and_fade(samples)
    pcm = array("h", (max(-32767, min(32767, int(round(x * 32767.0)))) for x in norm))
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm.tobytes())
    peak_db = 20.0 * math.log10(max((abs(x) for x in norm), default=1e-9))
    print(f"Generated {path} ({len(norm) / SAMPLE_RATE:.2f}s, peak {peak_db:.2f} dBFS)")


# --- DSP Building Blocks -------------------------------------------------------


def white_noise(duration: float, rng: random.Random) -> list[float]:
    """Generate uniform white noise in [-1, 1]."""
    n = max(1, int(round(duration * SAMPLE_RATE)))
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def pink_noise(duration: float, rng: random.Random) -> list[float]:
    """Generate approximate pink noise using Paul Kellet's filter."""
    n = max(1, int(round(duration * SAMPLE_RATE)))
    b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
    out = [0.0] * n
    for i in range(n):
        w = rng.uniform(-1.0, 1.0)
        b0 = 0.99886 * b0 + w * 0.0555179
        b1 = 0.99332 * b1 + w * 0.0750759
        b2 = 0.96900 * b2 + w * 0.1538520
        b3 = 0.86650 * b3 + w * 0.3104856
        b4 = 0.55000 * b4 + w * 0.5329522
        b5 = -0.7616 * b5 - w * 0.0168980
        out[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.11
        b6 = w * 0.115926
    return out


def one_pole_lowpass(samples: list[float], cutoff_hz: float) -> list[float]:
    """Simple 1-pole RC low-pass filter."""
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / SAMPLE_RATE)
    y = 0.0
    out = [0.0] * len(samples)
    for i, x in enumerate(samples):
        y += alpha * (x - y)
        out[i] = y
    return out


def one_pole_highpass(samples: list[float], cutoff_hz: float) -> list[float]:
    """Simple 1-pole RC high-pass filter."""
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    dt = 1.0 / SAMPLE_RATE
    alpha = rc / (rc + dt)
    out = [0.0] * len(samples)
    prev_x = 0.0
    prev_y = 0.0
    for i, x in enumerate(samples):
        y = alpha * (prev_y + x - prev_x)
        out[i] = y
        prev_x = x
        prev_y = y
    return out


def svf_bandpass_sweep(
    samples: list[float], f_start: float, f_end: float, q: float = 2.2, exp_sweep: bool = True
) -> list[float]:
    """Apply a time-varying state-variable bandpass filter across `samples`."""
    n = len(samples)
    low = band = 0.0
    out = [0.0] * n
    damp = 1.0 / max(0.5, q)
    log_ratio = math.log(max(1.0, f_end) / max(1.0, f_start))
    for i, x in enumerate(samples):
        u = i / max(1, n - 1)
        freq = f_start * math.exp(log_ratio * u) if exp_sweep else f_start + (f_end - f_start) * u
        f = min(0.85, 2.0 * math.sin(math.pi * freq / SAMPLE_RATE))
        high = x - low - damp * band
        band += f * high
        low += f * band
        out[i] = band
    return out


def chirp(
    f_start: float,
    f_end: float,
    duration: float,
    exp_curve: bool = True,
    harmonics: tuple[float, ...] = (1.0,),
) -> list[float]:
    """Generate a phase-continuous frequency sweep with optional harmonics."""
    n = max(1, int(round(duration * SAMPLE_RATE)))
    out = [0.0] * n
    phase = 0.0
    log_ratio = math.log(max(1.0, f_end) / max(1.0, f_start))
    for i in range(n):
        u = i / max(1, n - 1)
        freq = f_start * math.exp(log_ratio * u) if exp_curve else f_start + (f_end - f_start) * u
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        val = 0.0
        for h_idx, amp in enumerate(harmonics, start=1):
            if amp:
                val += amp * math.sin(phase * h_idx)
        out[i] = val
    return out


def synth_note(
    freq: float,
    duration: float,
    harmonics: tuple[float, ...] = (1.0, 0.3, 0.1),
    attack_s: float = 0.012,
    decay_rate: float = 5.5,
    vibrato_hz: float = 0.0,
    vibrato_depth: float = 0.0,
) -> list[float]:
    """Synthesize a harmonic musical note with attack and exponential decay."""
    n = max(1, int(round(duration * SAMPLE_RATE)))
    out = [0.0] * n
    att_n = max(1, int(round(attack_s * SAMPLE_RATE)))
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        f_inst = freq * (1.0 + vibrato_depth * math.sin(2.0 * math.pi * vibrato_hz * t))
        phase += 2.0 * math.pi * f_inst / SAMPLE_RATE
        env = min(1.0, i / att_n) * math.exp(-decay_rate * t)
        val = sum(amp * math.sin(phase * k) for k, amp in enumerate(harmonics, start=1) if amp)
        out[i] = val * env
    return out


def synth_sting(
    notes: list[tuple[float, float, float]],
    duration: float,
    harmonics: tuple[float, ...] = (1.0, 0.35, 0.15),
    attack_s: float = 0.01,
    decay_rate: float = 5.0,
) -> list[float]:
    """Build a short musical sting from `(start_s, note_dur_s, freq_hz)` entries."""
    buf = make_buffer(duration)
    for start_s, note_dur, freq in notes:
        note = synth_note(freq, note_dur, harmonics=harmonics, attack_s=attack_s, decay_rate=decay_rate)
        add_into(buf, note, start_s)
    return buf


def synth_shockwave(
    duration: float,
    rng: random.Random,
    sub_start: float = 115.0,
    sub_end: float = 34.0,
    crack_cutoff: float = 950.0,
) -> list[float]:
    """Generate a punchy low-end shockwave impact with air blast tail."""
    n = max(1, int(round(duration * SAMPLE_RATE)))
    sub = chirp(sub_start, sub_end, duration, exp_curve=True, harmonics=(1.0, 0.25))
    blast = one_pole_lowpass(pink_noise(duration, rng), crack_cutoff)
    snap = one_pole_highpass(white_noise(0.08, rng), 1400.0)
    buf = make_buffer(duration)
    for i in range(n):
        t = i / SAMPLE_RATE
        att = min(1.0, t / 0.004)
        sub_env = att * math.exp(-4.8 * t)
        blast_env = att * math.exp(-3.6 * t)
        buf[i] = sub[i] * sub_env * 0.85 + blast[i] * blast_env * 0.55
    for i, s in enumerate(snap):
        t = i / SAMPLE_RATE
        buf[i] += s * math.exp(-45.0 * t) * 0.45
    return buf


def synth_stamp_thud(duration: float, rng: random.Random, chime_hz: float = 0.0) -> list[float]:
    """Generate a heavy stamp/slab slam with optional metallic seal ring."""
    n = max(1, int(round(duration * SAMPLE_RATE)))
    thump = chirp(105.0, 36.0, duration, exp_curve=True, harmonics=(1.0, 0.35, 0.1))
    clack = one_pole_lowpass(white_noise(0.12, rng), 2400.0)
    rubble = one_pole_lowpass(pink_noise(duration, rng), 600.0)
    buf = make_buffer(duration)
    for i in range(n):
        t = i / SAMPLE_RATE
        att = min(1.0, t / 0.002)
        buf[i] = thump[i] * att * math.exp(-8.5 * t) * 0.9 + rubble[i] * att * math.exp(-6.5 * t) * 0.35
        if chime_hz > 0.0:
            ring = math.sin(2.0 * math.pi * chime_hz * t) * 0.6 + math.sin(2.0 * math.pi * chime_hz * 1.5 * t) * 0.4
            buf[i] += ring * att * math.exp(-6.0 * t) * 0.18
    for i, c in enumerate(clack):
        t = i / SAMPLE_RATE
        buf[i] += c * math.exp(-55.0 * t) * 0.65
    return buf


# --- Per-Fighter Super Sounds --------------------------------------------------


def make_dario(base_dir: str, rng: random.Random) -> None:
    out_dir = os.path.join(base_dir, "dario")
    # Short stately constitutional invocation sting ("ARTICLE 1: SAFETY!")
    opening = synth_sting(
        [
            (0.00, 0.25, 293.66),  # D4
            (0.10, 0.25, 369.99),  # F#4
            (0.20, 0.30, 440.00),  # A4
            (0.32, 0.40, 587.33),  # D5
        ],
        duration=0.72,
        harmonics=(1.0, 0.42, 0.22, 0.1),
        attack_s=0.015,
        decay_rate=4.8,
    )
    shimmer = one_pole_highpass(pink_noise(0.35, rng), 1800.0)
    add_into(opening, [s * math.exp(-9.0 * (i / SAMPLE_RATE)) for i, s in enumerate(shimmer)], 0.0, 0.12)
    write_wav(os.path.join(out_dir, "opening_sting.wav"), opening)

    # Heavy golden SAFE seal stamp slam
    stamp = synth_stamp_thud(0.75, rng, chime_hz=740.0)
    write_wav(os.path.join(out_dir, "stamp_thud.wav"), stamp)


def make_yann(base_dir: str, rng: random.Random) -> None:
    out_dir = os.path.join(base_dir, "yann")
    # Short cyber prompt-terminal activation sting ("PROMPT: PREDICT NEXT TOKEN")
    opening = synth_sting(
        [
            (0.00, 0.18, 523.25),  # C5
            (0.08, 0.18, 659.25),  # E5
            (0.16, 0.22, 783.99),  # G5
            (0.25, 0.38, 987.77),  # B5
        ],
        duration=0.65,
        harmonics=(1.0, 0.0, 0.32, 0.0, 0.12),  # warm hollow digital square-ish
        attack_s=0.006,
        decay_rate=6.2,
    )
    write_wav(os.path.join(out_dir, "opening_sting.wav"), opening)

    # Mechanical keyboard typing "> you lose_" (11 crisp tactile clicks + Enter clack)
    dur_type = 0.90
    buf_type = make_buffer(dur_type)
    click_times = [0.02, 0.09, 0.16, 0.24, 0.30, 0.38, 0.45, 0.52, 0.60, 0.68, 0.78]
    for idx, t_hit in enumerate(click_times):
        is_enter = idx == len(click_times) - 1
        c_dur = 0.045 if is_enter else 0.028
        n_c = int(round(c_dur * SAMPLE_RATE))
        body_hz = 260.0 if is_enter else rng.uniform(360.0, 480.0)
        ping_hz = 2400.0 if is_enter else rng.uniform(3100.0, 4400.0)
        raw = one_pole_highpass(white_noise(c_dur, rng), 1600.0)
        click = [0.0] * n_c
        for i in range(n_c):
            t = i / SAMPLE_RATE
            thock = math.sin(2.0 * math.pi * body_hz * t) * math.exp(-140.0 * t)
            ping = math.sin(2.0 * math.pi * ping_hz * t) * math.exp(-190.0 * t)
            burst = raw[i] * math.exp(-160.0 * t)
            click[i] = thock * 0.55 + ping * 0.35 + burst * 0.65
        add_into(buf_type, click, t_hit, gain=1.15 if is_enter else rng.uniform(0.7, 1.0))
    write_wav(os.path.join(out_dir, "keyboard_typing.wav"), buf_type)

    # Heavy concrete letter blocks crashing down ("Y O U L O S E")
    buf_slam = synth_stamp_thud(0.95, rng)
    for extra_t, gain in [(0.07, 0.45), (0.14, 0.30)]:
        add_into(buf_slam, synth_stamp_thud(0.45, rng), extra_t, gain=gain)
    write_wav(os.path.join(out_dir, "stamp_thud.wav"), buf_slam)


def make_geoff(base_dir: str, rng: random.Random) -> None:
    out_dir = os.path.join(base_dir, "geoff")
    # 1986 VHS rewind whir + warm analog synth chord stab ("<< 1986: BACKPROPAGATION")
    dur_open = 0.80
    buf_open = make_buffer(dur_open)
    rewind_dur = 0.34
    whir = chirp(420.0, 1950.0, rewind_dur, exp_curve=True, harmonics=(1.0, 0.35))
    flutter = one_pole_highpass(pink_noise(rewind_dur, rng), 1100.0)
    rewind = [
        (whir[i] * 0.5 + flutter[i] * 0.4) * math.sin(math.pi * i / len(whir))
        for i in range(len(whir))
    ]
    add_into(buf_open, rewind, 0.0, 0.55)
    chord = synth_sting(
        [(0.32, 0.48, 220.0), (0.32, 0.48, 329.63), (0.32, 0.48, 440.0)],
        duration=dur_open,
        harmonics=(1.0, 0.45, 0.25, 0.12),
        attack_s=0.015,
        decay_rate=4.5,
    )
    add_into(buf_open, chord, 0.0, 0.85)
    write_wav(os.path.join(out_dir, "opening_sting.wav"), buf_open)

    # Synaptic electric shockwave blast
    buf_shock = synth_shockwave(0.90, rng, sub_start=120.0, sub_end=38.0, crack_cutoff=1300.0)
    arc = chirp(2200.0, 210.0, 0.38, exp_curve=True, harmonics=(1.0, 0.4, 0.2))
    arc_env = [arc[i] * math.exp(-7.5 * (i / SAMPLE_RATE)) for i in range(len(arc))]
    add_into(buf_shock, arc_env, 0.0, 0.45)
    buzz = [
        (math.sin(2.0 * math.pi * 120.0 * (i / SAMPLE_RATE)) * 0.5 + math.sin(2.0 * math.pi * 240.0 * (i / SAMPLE_RATE)) * 0.3)
        * math.exp(-5.0 * (i / SAMPLE_RATE))
        for i in range(int(0.55 * SAMPLE_RATE))
    ]
    add_into(buf_shock, buzz, 0.02, 0.25)
    write_wav(os.path.join(out_dir, "shockwave.wav"), buf_shock)


def make_ram(base_dir: str, rng: random.Random) -> None:
    out_dir = os.path.join(base_dir, "ram")
    # Sleek keynote reveal sting ("SCALING LAWS DO NOT STOP")
    opening = synth_sting(
        [
            (0.00, 0.20, 329.63),  # E4
            (0.09, 0.20, 493.88),  # B4
            (0.18, 0.55, 659.25),  # E5
            (0.18, 0.55, 987.77),  # B5
        ],
        duration=0.75,
        harmonics=(1.0, 0.3, 0.15),
        attack_s=0.01,
        decay_rate=4.2,
    )
    write_wav(os.path.join(out_dir, "opening_sting.wav"), opening)

    # Exponential upward Scaling Law whoosh
    dur_w = 1.10
    n_w = int(round(dur_w * SAMPLE_RATE))
    raw_wind = pink_noise(dur_w, rng)
    swept = svf_bandpass_sweep(raw_wind, 180.0, 3400.0, q=2.5, exp_sweep=True)
    tone_rise = chirp(110.0, 1320.0, dur_w, exp_curve=True, harmonics=(1.0, 0.25))
    buf_w = make_buffer(dur_w)
    for i in range(n_w):
        u = i / max(1, n_w - 1)
        # Exponentially accelerating loudness peaking around u=0.82 then fading cleanly
        env = (u ** 1.4) * math.sin(math.pi * (u ** 0.85))
        buf_w[i] = swept[i] * env * 1.6 + tone_rise[i] * env * 0.28
    write_wav(os.path.join(out_dir, "space_whoosh.wav"), buf_w)

    # Heavy plummet crash shockwave ("7 TRILLION DOLLARS PLEASE.")
    buf_shock = synth_shockwave(0.95, rng, sub_start=135.0, sub_end=30.0, crack_cutoff=850.0)
    write_wav(os.path.join(out_dir, "shockwave.wav"), buf_shock)


def make_algorithm(base_dir: str, rng: random.Random) -> None:
    out_dir = os.path.join(base_dir, "algorithm")
    # Cold algorithmic notification sting ("RECOMMENDED FOR YOU")
    opening = synth_sting(
        [
            (0.00, 0.20, 587.33),  # D5
            (0.10, 0.20, 880.00),  # A5
            (0.22, 0.50, 1174.66),  # D6
            (0.22, 0.50, 146.83),   # D3 sub anchor
        ],
        duration=0.75,
        harmonics=(1.0, 0.2, 0.15, 0.08),
        attack_s=0.006,
        decay_rate=4.6,
    )
    write_wav(os.path.join(out_dir, "opening_sting.wav"), opening)

    # Digital suction teleport zap (pulled into the giant phone screen)
    dur_tp = 0.75
    n_tp = int(round(dur_tp * SAMPLE_RATE))
    warp_down = chirp(1500.0, 190.0, 0.42, exp_curve=True, harmonics=(1.0, 0.4, 0.2))
    warp_up = chirp(220.0, 1850.0, 0.33, exp_curve=True, harmonics=(1.0, 0.35))
    buf_tp = make_buffer(dur_tp)
    add_into(buf_tp, [warp_down[i] * math.exp(-3.0 * (i / SAMPLE_RATE)) for i in range(len(warp_down))], 0.0, 0.8)
    add_into(buf_tp, [warp_up[i] * math.exp(-5.0 * (i / SAMPLE_RATE)) for i in range(len(warp_up))], 0.38, 0.85)
    # Stepped digital packet shimmer
    for step in range(9):
        f_step = 500.0 + ((step * 370) % 1400)
        blip = synth_note(f_step, 0.05, harmonics=(1.0, 0.0, 0.4), attack_s=0.002, decay_rate=25.0)
        add_into(buf_tp, blip, step * 0.055, 0.25)
    # Gate noise zap
    zap = one_pole_highpass(white_noise(0.14, rng), 1800.0)
    add_into(buf_tp, [zap[i] * math.exp(-18.0 * (i / SAMPLE_RATE)) for i in range(len(zap))], 0.36, 0.35)
    for i in range(n_tp):
        buf_tp[i] *= min(1.0, i / (0.005 * SAMPLE_RATE))
    write_wav(os.path.join(out_dir, "teleport.wav"), buf_tp)

    # Digital slam shockwave ("SCREEN TIME LIMIT EXCEEDED.")
    buf_shock = synth_shockwave(0.95, rng, sub_start=110.0, sub_end=32.0, crack_cutoff=1150.0)
    glass_ping = synth_note(1320.0, 0.45, harmonics=(1.0, 0.5, 0.25), attack_s=0.003, decay_rate=8.5)
    add_into(buf_shock, glass_ping, 0.0, 0.28)
    write_wav(os.path.join(out_dir, "shockwave.wav"), buf_shock)


def verify_super_sounds(base_dir: str) -> None:
    """Verify every sound() call in scripts/supers/{scenes,victory}/ resolves to an audio file."""
    scene_owner = {
        "autocomplete.gd": "yann",
        "constitution_scroll.gd": "dario",
        "infinite_scroll.gd": "algorithm",
        "jacket_tornado.gd": "jensen",
        "lecture_hall.gd": "geoff",
        "metaverse_trap.gd": "zuckerbot",
        "not_found.gd": "sundar",
        "open_source_squad.gd": "xi",
        "rocket_launch.gd": "tesla",
        "scaling_law.gd": "ram",
        "tariff_stamp.gd": "donald",
    }
    missing = []
    checked = 0
    for root, _, files in os.walk("scripts/supers"):
        for fname in sorted(files):
            if not fname.endswith(".gd"):
                continue
            rel = root.replace("\\", "/")
            if rel.endswith("/scenes"):
                fighter = scene_owner[fname]
            elif rel.endswith("/victory"):
                fighter = fname[:-3]
            else:
                continue
            path = os.path.join(root, fname)
            with open(path, encoding="utf-8") as fh:
                txt = fh.read()
            for match in re.finditer(r'sound\("([^"]+)"', txt):
                sound_name = match.group(1)
                checked += 1
                wav = os.path.join(base_dir, fighter, f"{sound_name}.wav")
                ogg = os.path.join(base_dir, fighter, f"{sound_name}.ogg")
                if not (os.path.exists(wav) or os.path.exists(ogg)):
                    missing.append((path, fighter, sound_name))
    if missing:
        raise RuntimeError(f"Missing super sounds: {missing}")
    print(f"Verified {checked} sound() calls across scripts/supers/scenes and victory: 0 missing.")


def main() -> None:
    rng = random.Random(20261125)
    base_dir = "assets/audio/supers"
    make_dario(base_dir, rng)
    make_yann(base_dir, rng)
    make_geoff(base_dir, rng)
    make_ram(base_dir, rng)
    make_algorithm(base_dir, rng)
    verify_super_sounds(base_dir)
    print("All missing super sounds and opening stings generated.")


if __name__ == "__main__":
    main()
