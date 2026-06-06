# ==================================================
# CONFIGURATION FILE
# ==================================================
import os
import sys

# Add src folder to Python path
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.abspath(os.path.join(CURRENT_DIR, ".."))

if SRC_DIR not in sys.path:
    sys.path.append(SRC_DIR)

# ✅ NOW import
from datasets import WM_811K
LABELS = [
    label for label, idx in sorted(WM_811K.defect_to_int.items(), key=lambda x: x[1])
    if idx != -1
]
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, "..", ".."))

MODEL_DIR = os.path.join(PROJECT_ROOT, "models")

# Image size
TARGET_SIZE = (64, 64)