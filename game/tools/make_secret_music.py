"""Render an original, seamlessly looping industrial suspense cue (no external samples)."""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
BEAT = 0.625  # 96 BPM, eight bars
DURATION = BEAT * 32
COUNT = round(RATE * DURATION)
t = np.arange(COUNT) / RATE
rng = np.random.default_rng(1989)
mix = np.zeros((COUNT, 2))


def midi(note):
    return 440 * 2 ** ((note - 69) / 12)


def add(sound, start, gain, pan=0):
    idx = (round(start * RATE) + np.arange(len(sound))) % COUNT
    mix[idx, 0] += sound * gain * np.sqrt((1 - pan) / 2)
    mix[idx, 1] += sound * gain * np.sqrt((1 + pan) / 2)


# Slowly beating bass and bowed, detuned harmonics under a sparse minor ostinato.
for note, gain in [(26, 0.11), (38, 0.055), (45, 0.025), (51, 0.018)]:
    f = round(midi(note) * DURATION) / DURATION
    for detune in [-1, 0, 1]:
        detuned = f + detune / DURATION
        pad = sum(np.sin(2 * np.pi * detuned * harmonic * t + harmonic * 0.37) / harmonic ** 1.7 for harmonic in range(1, 7))
        motion = 0.65 + 0.15 * np.sin(2 * np.pi * t / DURATION + note)
        mix[:, 0] += pad * motion * gain / 3
        mix[:, 1] += np.roll(pad, round(0.009 * RATE)) * motion * gain / 3

pattern = [50, 57, 53, 63, 50, 60, 55, 51]
for step in range(64):
    u = np.arange(round(RATE * 0.8)) / RATE
    f = midi(pattern[step % len(pattern)])
    struck = (np.sin(2 * np.pi * f * u) + 0.32 * np.sin(2 * np.pi * f * 2.003 * u) + 0.13 * np.sin(2 * np.pi * f * 4.017 * u))
    struck *= (1 - np.exp(-u * 160)) * np.exp(-u * 7)
    add(struck, step * BEAT / 2, 0.065 if step % 4 == 0 else 0.035, -0.25 if step % 2 else 0.25)

for beat in range(32):
    u = np.arange(round(RATE * 0.45)) / RATE
    pulse = np.sin(2 * np.pi * (44 * u + 13 * (1 - np.exp(-u * 24)) / 24))
    pulse *= (1 - np.exp(-u * 220)) * np.exp(-u * 12)
    add(pulse, beat * BEAT, 0.16 if beat % 4 == 0 else 0.08)
    # Dry mechanical ticking; its noisy component is softened before mixing.
    u = np.arange(round(RATE * 0.12)) / RATE
    noise = rng.normal(0, 1, len(u))
    click = np.convolve(noise, np.ones(9) / 9, mode="same") * np.exp(-u * 65)
    add(click, beat * BEAT + BEAT / 2, 0.033, (-1) ** beat * 0.4)

for hit in range(8):
    u = np.arange(round(RATE * 1.8)) / RATE
    metal = sum(np.sin(2 * np.pi * f * u + f) * np.exp(-u * decay) for f, decay in [(173, 3.5), (419, 5), (731, 6), (1267, 9)])
    metal *= 1 - np.exp(-u * 300)
    add(metal, hit * 4 * BEAT, 0.024, -0.35 if hit % 2 else 0.35)

dry = mix.copy()
for delay, gain in [(0.11, 0.12), (0.23, 0.08), (0.41, 0.055)]:
    mix += np.roll(dry[:, ::-1], round(delay * RATE), axis=0) * gain
mix = np.tanh(mix * 1.4)
mix -= mix.mean(axis=0)
mix *= 0.76 / np.max(np.abs(mix))
pcm = np.round(np.clip(mix, -1, 1) * 32767).astype("<i2")
dest = Path(__file__).resolve().parents[1] / "assets/audio/secret_room_tension.wav"
with wave.open(str(dest), "wb") as output:
    output.setnchannels(2)
    output.setsampwidth(2)
    output.setframerate(RATE)
    output.writeframes(pcm.tobytes())
print(f"{dest.name}: {DURATION:.1f}s original stereo loop, peak {np.max(np.abs(mix)):.2f}")
