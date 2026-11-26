#!/usr/bin/env python3
"""Gera efeitos sonoros arcade curtos para Iferno, sem dependências externas."""

import math
import random
import struct
import wave
from pathlib import Path


RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "sfx"


def env(t: float, attack: float, decay: float, sustain: float, release: float, length: float) -> float:
    if t < attack:
        return t / max(attack, 1e-6)
    if t < attack + decay:
        return 1.0 - (1.0 - sustain) * (t - attack) / max(decay, 1e-6)
    if t < length - release:
        return sustain
    return sustain * max(0.0, (length - t) / max(release, 1e-6))


def render(name: str, length: float, voice, seed: int) -> None:
    rng = random.Random(seed)
    count = int(RATE * length)
    samples = []
    phase = 0.0
    phase2 = 0.0
    noise_smooth = 0.0

    for i in range(count):
        t = i / RATE
        p = t / length
        phase += 2 * math.pi * voice["freq"](p) / RATE
        phase2 += 2 * math.pi * voice.get("freq2", lambda _p: 0)(p) / RATE
        wave_kind = voice.get("wave", "sine")
        if wave_kind == "square":
            tone = 1.0 if math.sin(phase) >= 0 else -1.0
        elif wave_kind == "saw":
            tone = 2.0 * ((phase / (2 * math.pi)) % 1.0) - 1.0
        elif wave_kind == "triangle":
            tone = 2.0 / math.pi * math.asin(math.sin(phase))
        else:
            tone = math.sin(phase)

        tone *= env(t, *voice.get("envelope", (0.003, 0.04, 0.0, 0.02, length)))
        tone *= voice.get("volume", 0.5)

        if "freq2" in voice:
            tone += math.sin(phase2) * voice.get("volume2", 0.15) * env(
                t, *voice.get("envelope2", (0.002, 0.025, 0.0, 0.03, length))
            )

        noise = rng.uniform(-1.0, 1.0)
        # A one-pole low-pass keeps noise layers from sounding harsh and fizzy.
        cutoff = voice.get("noise_cutoff", 1.0)
        noise_smooth += cutoff * (noise - noise_smooth)
        noise = noise_smooth
        noise *= voice.get("noise", 0.0) * env(
            t, *voice.get("noise_envelope", (0.001, 0.025, 0.0, 0.02, length))
        )
        value = max(-0.95, min(0.95, tone + noise))
        samples.append(struct.pack("<h", int(value * 32767)))

    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(samples))


def linear(start: float, end: float):
    return lambda p: start + (end - start) * p


def main() -> None:
    render("shoot", 0.095, {
        "freq": linear(1120, 330), "wave": "sine", "volume": 0.348,
        "envelope": (0.001, 0.018, 0.0, 0.035, 0.095),
        "noise": 0.168, "noise_cutoff": 0.42,
        "noise_envelope": (0.001, 0.012, 0.0, 0.025, 0.095),
    }, 11)
    render("roll", 0.22, {
        "freq": lambda p: 260 - 110 * math.sin(p * math.pi), "wave": "triangle",
        "volume": 0.18, "envelope": (0.015, 0.07, 0.18, 0.08, 0.22),
        "noise": 0.4, "noise_cutoff": 0.22,
        "noise_envelope": (0.02, 0.08, 0.35, 0.07, 0.22),
    }, 22)
    render("hit", 0.075, {
        "freq": linear(460, 125), "wave": "triangle", "volume": 0.42,
        "envelope": (0.001, 0.018, 0.0, 0.03, 0.075),
        "noise": 0.42, "noise_cutoff": 0.52,
        "noise_envelope": (0.001, 0.012, 0.0, 0.025, 0.075),
    }, 33)
    render("hurt", 0.24, {
        "freq": lambda p: 330 - 95 * p + 22 * math.sin(p * 34), "wave": "square",
        "volume": 0.168, "envelope": (0.006, 0.04, 0.35, 0.08, 0.24),
        "freq2": linear(180, 85), "volume2": 0.126,
        "envelope2": (0.002, 0.06, 0.1, 0.09, 0.24),
        "noise": 0.126, "noise_cutoff": 0.45,
        "noise_envelope": (0.001, 0.025, 0.05, 0.08, 0.24),
    }, 44)
    render("kill", 0.31, {
        "freq": lambda p: (430 + 520 * min(p * 2.3, 1.0)) if p < 0.57 else 950 - 160 * (p - 0.57),
        "wave": "triangle", "volume": 0.37,
        "envelope": (0.003, 0.045, 0.22, 0.12, 0.31),
        "freq2": lambda p: 660 + 330 * min(p * 2.0, 1.0), "volume2": 0.16,
        "envelope2": (0.008, 0.05, 0.0, 0.1, 0.31),
        "noise": 0.2, "noise_cutoff": 0.48,
        "noise_envelope": (0.001, 0.014, 0.0, 0.04, 0.31),
    }, 55)
    render("die", 0.62, {
        "freq": lambda p: 300 - 220 * p + 18 * math.sin(p * 23), "wave": "triangle",
        "volume": 0.37, "envelope": (0.008, 0.12, 0.35, 0.22, 0.62),
        "freq2": linear(150, 48), "volume2": 0.2,
        "envelope2": (0.01, 0.13, 0.25, 0.2, 0.62),
        "noise": 0.17, "noise_cutoff": 0.25,
        "noise_envelope": (0.004, 0.1, 0.1, 0.18, 0.62),
    }, 66)


if __name__ == "__main__":
    main()
