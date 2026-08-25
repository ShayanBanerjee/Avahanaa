"""Measure where each QR styling knob stops decoding.

The Avahanaa code is drawn with rounded modules, softened finder frames and a
centre logo. Exactly one of those can silently destroy scannability, and by the
time you find out it is glued to a windscreen. This finds the cliff.

    pip install opencv-python-headless numpy
    python3 tool/qr_style_sweep.py --emit > /tmp/sweep_variants.txt
    flutter test test/qr_style_sweep_test.dart
    python3 tool/qr_style_sweep.py /tmp/qrprobe

Each variant is decoded under the same degradation set the sticker harness
uses, so a value only counts as safe if it survives a distant, blurred, tilted,
glared and noisy scan.
"""
import sys, math, glob, os

EXPECTED = "https://avahanaa.com/n/qr-abc123def456"


def emit():
    """Print the sweep grid consumed by the Dart renderer."""
    rows = []
    for eye in [0.0, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28]:
        rows.append((f"eye{eye:.2f}", 0.30, eye, 0.34, 0.17))
    for mod in [0.0, 0.15, 0.25, 0.35, 0.45, 0.50]:
        rows.append((f"mod{mod:.2f}", mod, 0.12, 0.34, 0.17))
    for logo in [0.0, 0.14, 0.17, 0.20, 0.24, 0.28]:
        rows.append((f"logo{logo:.2f}", 0.30, 0.12, 0.34, logo))
    for name, m, e, i, l in rows:
        print(f"{name},{m},{e},{i},{l}")


if "--emit" in sys.argv:
    emit()
    sys.exit(0)

import cv2
import numpy as np

det = cv2.QRCodeDetector()


def decode(img):
    try:
        data, _, _ = det.detectAndDecode(img)
    except cv2.error:
        return None
    return data or None


def scale(im, w):
    h = int(im.shape[0] * w / im.shape[1])
    return cv2.resize(im, (w, h), interpolation=cv2.INTER_AREA)


def blur(im, k):
    return cv2.GaussianBlur(im, (k, k), 0)


def rotate(im, deg):
    h, w = im.shape[:2]
    r = math.radians(abs(deg))
    nw = int(w * math.cos(r) + h * math.sin(r))
    nh = int(w * math.sin(r) + h * math.cos(r))
    m = cv2.getRotationMatrix2D((w / 2, h / 2), deg, 1.0)
    m[0, 2] += (nw - w) / 2
    m[1, 2] += (nh - h) / 2
    return cv2.warpAffine(im, m, (nw, nh), borderValue=(255, 255, 255))


def low_contrast(im, f):
    return np.clip(im.astype(np.float32) * f + (255 * (1 - f)), 0, 255).astype(np.uint8)


def noise(im, sigma):
    n = np.random.normal(0, sigma, im.shape).astype(np.float32)
    return np.clip(im.astype(np.float32) + n, 0, 255).astype(np.uint8)


CASES = [
    ("clean", lambda i: i),
    ("500px", lambda i: scale(i, 500)),
    ("360px", lambda i: scale(i, 360)),
    ("blur5", lambda i: blur(i, 5)),
    ("blur9", lambda i: blur(i, 9)),
    ("tilt7", lambda i: rotate(i, 7)),
    ("tilt15", lambda i: rotate(i, 15)),
    ("glare", lambda i: low_contrast(i, 0.60)),
    ("noise", lambda i: noise(i, 14)),
    ("combo", lambda i: rotate(blur(scale(i, 480), 5), 6)),
]

directory = sys.argv[1] if len(sys.argv) > 1 else "/tmp/qrprobe"
files = sorted(glob.glob(os.path.join(directory, "*.png")))
if not files:
    sys.exit(f"No PNGs in {directory}. Run the Dart renderer first.")

print(f"{'variant':12s} {'pass':>5s}/{len(CASES)}   failing cases")
worst = 0
for path in files:
    base = cv2.imread(path, cv2.IMREAD_COLOR)
    ok, bad = 0, []
    for name, fn in CASES:
        if decode(fn(base.copy())) == EXPECTED:
            ok += 1
        else:
            bad.append(name)
    worst = max(worst, len(bad))
    print(f"{os.path.basename(path)[:-4]:12s} {ok:5d}/{len(CASES)}   {','.join(bad) or '-'}")

print("\nA value is only safe if it scores 10/10. Anything less reaches a "
      "windscreen as an intermittent failure, which is worse than an obvious one.")
