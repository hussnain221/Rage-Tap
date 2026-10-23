#!/usr/bin/env python3
"""
Procedural sound effect generator for Rage Tap per spec §13.1.
Uses Python standard library only (wave, math, random, struct, os, pathlib).
Produces mono, 16-bit PCM, 44100 Hz WAV files into assets/audio/.
"""

import math
import os
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
PEAK_TARGET = 0.80


def apply_fades(samples, sample_rate=SAMPLE_RATE, fade_in_ms=2.0, fade_out_ms=5.0):
    """Applies fade-in and fade-out to prevent clicks."""
    n = len(samples)
    fade_in_samples = max(1, int((fade_in_ms / 1000.0) * sample_rate))
    fade_out_samples = max(1, int((fade_out_ms / 1000.0) * sample_rate))

    out = list(samples)
    for i in range(min(fade_in_samples, n)):
        out[i] *= (i / fade_in_samples)

    for i in range(min(fade_out_samples, n)):
        idx = n - 1 - i
        out[idx] *= (i / fade_out_samples)

    return out


def normalize(samples, target_peak=PEAK_TARGET):
    """Normalizes sample peak amplitude to target_peak (e.g. ~0.8)."""
    max_amp = max(abs(s) for s in samples) if samples else 0
    if max_amp <= 1e-9:
        return samples
    gain = target_peak / max_amp
    return [s * gain for s in samples]


def write_wav(file_path: Path, samples, sample_rate=SAMPLE_RATE):
    """Writes mono 16-bit PCM WAV file."""
    file_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(file_path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        packed = bytearray()
        for s in samples:
            val = int(max(-1.0, min(1.0, s)) * 32767.0)
            packed.extend(struct.pack("<h", val))
        wav.writeframes(packed)


def gen_jump():
    """Sine sweep 400->800 Hz over 0.12 s, exponential decay."""
    duration = 0.12
    num_samples = int(duration * SAMPLE_RATE)
    f_start = 400.0
    f_end = 800.0
    k = (f_end - f_start) / duration  # df/dt

    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # phase = 2 * pi * (f_start * t + 0.5 * k * t^2)
        phase = 2.0 * math.pi * (f_start * t + 0.5 * k * t * t)
        decay = math.exp(-3.5 * (t / duration))
        samples.append(math.sin(phase) * decay)

    samples = apply_fades(samples, fade_in_ms=2.0, fade_out_ms=6.0)
    return normalize(samples, target_peak=PEAK_TARGET)


def gen_land():
    """120 Hz sine thump, 0.05 s, fast decay (volume low)."""
    duration = 0.05
    num_samples = int(duration * SAMPLE_RATE)
    freq = 120.0

    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        phase = 2.0 * math.pi * freq * t
        decay = math.exp(-12.0 * (t / duration))
        samples.append(math.sin(phase) * decay)

    samples = apply_fades(samples, fade_in_ms=2.0, fade_out_ms=5.0)
    # Land is spec'd as "volume low" -> peak ~ 0.45
    return normalize(samples, target_peak=0.45)


def gen_hit():
    """White-noise burst + 90 Hz sine, 0.35 s, decaying."""
    duration = 0.35
    num_samples = int(duration * SAMPLE_RATE)
    rng = random.Random(42)  # Deterministic seed for reproducible asset builds

    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        noise = (rng.random() * 2.0 - 1.0)
        sine = math.sin(2.0 * math.pi * 90.0 * t)
        # Combined punch
        mix = 0.65 * noise + 0.35 * sine
        decay = math.exp(-5.5 * (t / duration))
        samples.append(mix * decay)

    samples = apply_fades(samples, fade_in_ms=2.0, fade_out_ms=10.0)
    return normalize(samples, target_peak=PEAK_TARGET)


def gen_near_miss():
    """Two sine tones 880 Hz then 1320 Hz, 0.07 s each, bright."""
    tone_duration = 0.07
    num_samples_per_tone = int(tone_duration * SAMPLE_RATE)

    samples = []
    # Tone 1: 880 Hz
    t1_samples = []
    for i in range(num_samples_per_tone):
        t = i / SAMPLE_RATE
        decay = math.exp(-2.0 * (t / tone_duration))
        # Add slight 2nd harmonic (1760 Hz) for brightness
        tone = math.sin(2.0 * math.pi * 880.0 * t) + 0.25 * math.sin(2.0 * math.pi * 1760.0 * t)
        t1_samples.append(tone * decay)
    t1_samples = apply_fades(t1_samples, fade_in_ms=2.0, fade_out_ms=3.0)
    samples.extend(t1_samples)

    # Tone 2: 1320 Hz
    t2_samples = []
    for i in range(num_samples_per_tone):
        t = i / SAMPLE_RATE
        decay = math.exp(-3.0 * (t / tone_duration))
        tone = math.sin(2.0 * math.pi * 1320.0 * t) + 0.20 * math.sin(2.0 * math.pi * 2640.0 * t)
        t2_samples.append(tone * decay)
    t2_samples = apply_fades(t2_samples, fade_in_ms=2.0, fade_out_ms=5.0)
    samples.extend(t2_samples)

    return normalize(samples, target_peak=PEAK_TARGET)


def gen_new_best():
    """Arpeggio C5, E5, G5, C6 (523, 659, 784, 1047 Hz), 0.09 s each."""
    notes = [523.25, 659.25, 783.99, 1046.50]
    note_duration = 0.09
    num_samples_per_note = int(note_duration * SAMPLE_RATE)

    samples = []
    for freq in notes:
        note_samples = []
        for i in range(num_samples_per_note):
            t = i / SAMPLE_RATE
            decay = math.exp(-4.0 * (t / note_duration))
            # Sine with gentle chime harmonics
            chime = (
                math.sin(2.0 * math.pi * freq * t)
                + 0.20 * math.sin(2.0 * math.pi * freq * 2.0 * t)
            )
            note_samples.append(chime * decay)
        note_samples = apply_fades(note_samples, fade_in_ms=2.0, fade_out_ms=4.0)
        samples.extend(note_samples)

    return normalize(samples, target_peak=PEAK_TARGET)


def gen_click():
    """1000 Hz sine 0.03 s."""
    duration = 0.03
    num_samples = int(duration * SAMPLE_RATE)
    freq = 1000.0

    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        decay = math.exp(-6.0 * (t / duration))
        samples.append(math.sin(2.0 * math.pi * freq * t) * decay)

    samples = apply_fades(samples, fade_in_ms=2.0, fade_out_ms=3.0)
    return normalize(samples, target_peak=0.65)


def gen_fall():
    """Sine sweep 700->90 Hz over 0.45 s with decay and fades (peak ~0.8)."""
    duration = 0.45
    num_samples = int(duration * SAMPLE_RATE)
    f_start = 700.0
    f_end = 90.0
    k = (f_end - f_start) / duration  # df/dt (negative)

    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        phase = 2.0 * math.pi * (f_start * t + 0.5 * k * t * t)
        decay = math.exp(-2.5 * (t / duration))
        samples.append(math.sin(phase) * decay)

    samples = apply_fades(samples, fade_in_ms=2.0, fade_out_ms=10.0)
    return normalize(samples, target_peak=PEAK_TARGET)


def main():
    root_dir = Path(__file__).resolve().parent.parent
    output_dir = root_dir / "assets" / "audio"
    output_dir.mkdir(parents=True, exist_ok=True)

    generators = {
        "jump.wav": gen_jump,
        "land.wav": gen_land,
        "hit.wav": gen_hit,
        "near_miss.wav": gen_near_miss,
        "new_best.wav": gen_new_best,
        "click.wav": gen_click,
        "fall.wav": gen_fall,
    }

    print(f"Generating SFX in {output_dir}...")
    for filename, gen_fn in generators.items():
        samples = gen_fn()
        out_path = output_dir / filename
        write_wav(out_path, samples)
        size_bytes = out_path.stat().st_size
        print(f"  [OK] {filename:14s} -> {size_bytes:6d} bytes ({len(samples)/SAMPLE_RATE:.3f}s)")

    print("All audio files generated successfully.")


if __name__ == "__main__":
    main()
