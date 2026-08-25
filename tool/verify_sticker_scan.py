"""Decode the exported Avahanaa stickers under simulated windscreen conditions.

The design system requires every sticker change to be scan-verified before it
ships. Doing that by eye with Google Lens catches only the happy path; this
catches the cases that actually break in Bangalore — a code printed small, seen
through dusty glass, at an angle, in glare.

Usage:

    pip install opencv-python-headless numpy
    STICKER_OUT=/tmp/stickers flutter test test/sticker_renderer_test.dart
    python3 tool/verify_sticker_scan.py /tmp/stickers

Exits non-zero if any style fails to decode to the expected URL under any
condition. Keep EXPECTED in sync with the qrData in the test fixture.
"""
import sys, math
import cv2
import numpy as np

EXPECTED = "https://avahanaa.com/n/qr-abc123def456"

# Discovered from the directory rather than hardcoded: the sticker test writes
# one PNG per StickerStyle, and a theme added in Dart has to be verified here
# without anyone remembering to edit this list.
import glob, os


def discover_styles(directory):
    names = sorted(
        os.path.basename(p)[len("sticker-"):-len(".png")]
        for p in glob.glob(os.path.join(directory, "sticker-*.png"))
    )
    if not names:
        sys.exit(f"No sticker-*.png found in {directory}. Run the render test first.")
    return names

det = cv2.QRCodeDetector()

def decode(img):
    try:
        data, pts, _ = det.detectAndDecode(img)
    except cv2.error:
        return None
    return data or None

def to_gray_bgr(img):
    if len(img.shape) == 2:
        return cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    return img

def scale(img, w):
    h = int(img.shape[0] * w / img.shape[1])
    return cv2.resize(img, (w, h), interpolation=cv2.INTER_AREA)

def blur(img, k):
    return cv2.GaussianBlur(img, (k, k), 0)

def rotate(img, deg):
    # Expand the canvas so the rotated sticker is never clipped. A camera held
    # at an angle still sees the whole sticker; clipping would be an artifact
    # of the harness, not of the design.
    h, w = img.shape[:2]
    rad = math.radians(abs(deg))
    nw = int(w * math.cos(rad) + h * math.sin(rad))
    nh = int(w * math.sin(rad) + h * math.cos(rad))
    m = cv2.getRotationMatrix2D((w / 2, h / 2), deg, 1.0)
    m[0, 2] += (nw - w) / 2
    m[1, 2] += (nh - h) / 2
    return cv2.warpAffine(img, m, (nw, nh), borderValue=(255, 255, 255))

def low_contrast(img, factor):
    # Simulates glare / faded toner: pull black up toward mid grey.
    return np.clip(img.astype(np.float32) * factor + (255 * (1 - factor)), 0, 255).astype(np.uint8)

def noise(img, sigma):
    # Seeded, so this is a gate and not a coin flip.
    #
    # It ran unseeded at first and failed roughly once in five hundred runs — a
    # rare tail draw, not a margin problem (480 further trials all passed). But
    # an intermittently red gate is one people learn to re-run rather than read,
    # and this one guards whether a printed sticker scans. A fixed seed makes a
    # failure here mean something actually changed.
    rng = np.random.default_rng(0xA1A)
    n = rng.normal(0, sigma, img.shape).astype(np.float32)
    return np.clip(img.astype(np.float32) + n, 0, 255).astype(np.uint8)

CASES = [
    ("as exported (900px)",            lambda im: im),
    ("scaled to 500px wide",           lambda im: scale(im, 500)),
    ("scaled to 360px (distant scan)", lambda im: scale(im, 360)),
    ("out of focus (blur 5)",          lambda im: blur(im, 5)),
    ("dirty glass (blur 9)",           lambda im: blur(im, 9)),
    ("held at 7 degrees",              lambda im: rotate(im, 7)),
    ("held at 15 degrees",             lambda im: rotate(im, 15)),
    ("glare / faded ink (60%)",        lambda im: low_contrast(im, 0.60)),
    ("sensor noise",                   lambda im: noise(im, 14)),
    ("small + blurred + tilted",       lambda im: rotate(blur(scale(im, 480), 5), 6)),
]

failures = 0
STYLES = discover_styles(sys.argv[1])
print(f"Verifying {len(STYLES)} styles: {', '.join(STYLES)}")

for style in STYLES:
    path = f"{sys.argv[1]}/sticker-{style}.png"
    base = cv2.imread(path, cv2.IMREAD_COLOR)
    if base is None:
        print(f"MISSING {path}")
        failures += 1
        continue
    print(f"\n=== {style} ({base.shape[1]}x{base.shape[0]}) ===")
    for name, fn in CASES:
        img = to_gray_bgr(fn(base.copy()))
        got = decode(img)
        ok = got == EXPECTED
        if not ok:
            failures += 1
        mark = "PASS" if ok else "FAIL"
        detail = "" if ok else f"  -> got {got!r}"
        print(f"  [{mark}] {name}{detail}")

print(f"\n{'ALL DECODED CORRECTLY' if failures == 0 else f'{failures} FAILURE(S)'}")
sys.exit(1 if failures else 0)
