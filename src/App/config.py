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
# ✅ can now import from src dir

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, "..", ".."))

MODEL_DIR = os.path.join(PROJECT_ROOT, "models")

# Image size
TARGET_SIZE = (64, 64)