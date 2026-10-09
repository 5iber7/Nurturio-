"""Original synthetic ambience and interaction cues, with no external samples."""
import math, wave, struct
from pathlib import Path
root = Path('apps/mobile/assets/audio')
root.mkdir(parents=True, exist_ok=True)
rate = 22050
for name, seconds in [('village', 12), ('discovery', .35)]:
    with wave.open(str(root / (name + '.wav')), 'w') as wav:
        wav.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        samples = []
        for n in range(int(seconds * rate)):
            t = n / rate
            if name == 'village':
                # Loop-aligned quiet harmonic bed, avoiding sudden transients.
                sample = .055 * (math.sin(2*math.pi*220*t) + .45*math.sin(2*math.pi*330*t)) * (.6+.4*math.sin(2*math.pi*t/12)**2)
            else:
                sample = .2 * math.sin(2*math.pi*(660+400*t)*t) * math.sin(math.pi*t/seconds)**2
            samples.append(struct.pack('<h', int(max(-1, min(1, sample)) * 32767)))
        wav.writeframes(b''.join(samples))
print('Original audio created.')
