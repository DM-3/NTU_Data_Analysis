import os
import csv
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
from PIL import Image
from collections import defaultdict, Counter
import datetime

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
FOLDER     = "generated_images"
OUTPUT_CSV = "evaluation_results.csv"

LABEL_8 = ["Center", "Loc", "Edge-Ring", "Edge-Loc",
           "Scratch", "Random", "Donut",  "Near-full"]
LABEL_SET = set(LABEL_8)

# ─────────────────────────────────────────────────────────────────────────────
# LOAD MODELS
# ─────────────────────────────────────────────────────────────────────────────
import warnings, logging
warnings.filterwarnings("ignore")
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"
tf.get_logger().setLevel(logging.ERROR)

def load(path):
    if not os.path.exists(path):
        print(f"  ⚠️  NOT FOUND: {path}")
        return None
    return load_model(path)

print("Loading models…")
m_aug  = load("models/best_wafer_cnn_data_augmented.keras")
m_cnn  = load("models/best_wafer_cnn.keras")
m_full = load("models/multi_defect_fullstack.keras")
m_seg  = load("models/multi_defect_segmentation.keras")
m_clf  = load("models/multi_defect_classification.keras")

for name, m in [("best_aug", m_aug), ("best_cnn", m_cnn),
                ("fullstack", m_full), ("seg_model", m_seg), ("clf_model", m_clf)]:
    if m:
        print(f"  ✅ {name:<12} output={m.output_shape}")

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def preprocess(path, size, wm811k_encode=True):
    img = Image.open(path).convert("L")
    if img.size != (size, size):
        img = img.resize((size, size), Image.NEAREST)
    arr = np.array(img, dtype=np.float32)
    arr = np.round(arr / 127.5).clip(0, 2) / 2.0 if wm811k_encode \
          else np.round(arr / 127.5) / 2.0
    return arr[np.newaxis, ..., np.newaxis]

def parse_label(filename):
    stem       = os.path.splitext(filename)[0]
    tokens     = stem.split("_")
    candidates = list(tokens)
    for i in range(len(tokens) - 1):
        candidates.append(f"{tokens[i]}-{tokens[i+1]}")
    for c in candidates:
        if c in LABEL_SET:
            return c
    return None

def run_aug(path):
    preds = m_aug(preprocess(path, 96, False), training=False)[0].numpy()
    preds = preds[1:]          # drop "none" class at index 0
    idx   = int(np.argmax(preds))
    return LABEL_8[idx], preds[idx], [round(float(p), 4) for p in preds]

def run_cnn(path):
    preds = m_cnn(preprocess(path, 96, False), training=False)[0].numpy()
    preds = preds[1:]
    idx   = int(np.argmax(preds))
    return LABEL_8[idx], preds[idx], [round(float(p), 4) for p in preds]

def run_fullstack(path):
    preds = m_full(preprocess(path, 64, True), training=False)[0].numpy()
    idx   = int(np.argmax(preds))
    return LABEL_8[idx], preds[idx], [round(float(p), 4) for p in preds]

def run_seg_clf(path):
    seg      = m_seg(preprocess(path, 64, True), training=False).numpy()
    mean     = seg.mean(axis=-1, keepdims=True)
    std      = seg.std( axis=-1, keepdims=True) + 1e-6
    seg_norm = (seg - mean) / std
    preds    = m_clf(seg_norm, training=False)[0].numpy()
    idx      = int(np.argmax(preds))
    return LABEL_8[idx], preds[idx], [round(float(p), 4) for p in preds]

MODELS = [
    ("Best CNN + Aug",  run_aug,      m_aug  is not None),
    ("Best CNN",        run_cnn,      m_cnn  is not None),
    ("Fullstack",       run_fullstack, m_full is not None),
    ("Seg → CLF",       run_seg_clf,  m_seg  is not None and m_clf is not None),
]

# ─────────────────────────────────────────────────────────────────────────────
# EVALUATE & WRITE CSV
# ─────────────────────────────────────────────────────────────────────────────
png_files = sorted(f for f in os.listdir(FOLDER) if f.lower().endswith(".png"))
print(f"\nEvaluating {len(png_files)} images…")

# Per-model accumulators for summary
stats     = {n: {cls: {"c": 0, "t": 0} for cls in LABEL_8} for n, _, a in MODELS if a}
confusion = {n: defaultdict(list) for n, _, a in MODELS if a}

# CSV columns
# One row per (image × model) — easy to filter/pivot in Excel or pandas
fieldnames = [
    "image_file",           # e.g. 42_Scratch.png
    "image_index",          # numeric prefix
    "true_label",           # ground truth
    "model",                # model name
    "predicted_label",      # top-1 prediction
    "correct",              # TRUE / FALSE
    "confidence",           # softmax score of predicted class (0–1)
    "true_label_score",     # softmax score assigned to the correct class
    "confidence_gap",       # confidence - true_label_score (how wrong it was)
    "top1", "top2", "top3", # top-3 predicted classes with scores
] + [f"prob_{cls.replace('-','_')}" for cls in LABEL_8]   # full prob vector

rows = []
skipped = 0

for file in png_files:
    true_label = parse_label(file)
    if true_label is None:
        skipped += 1
        continue

    # Extract numeric index from filename prefix
    try:
        img_index = int(file.split("_")[0])
    except ValueError:
        img_index = -1

    path = os.path.join(FOLDER, file)

    for model_name, predict_fn, available in MODELS:
        if not available:
            continue

        try:
            pred_label, confidence, prob_vec = predict_fn(path)
        except Exception as e:
            rows.append({
                "image_file"      : file,
                "image_index"     : img_index,
                "true_label"      : true_label,
                "model"           : model_name,
                "predicted_label" : "ERROR",
                "correct"         : "ERROR",
                "confidence"      : "",
                "true_label_score": "",
                "confidence_gap"  : "",
                "top1": "", "top2": "", "top3": "",
                **{f"prob_{cls.replace('-','_')}": "" for cls in LABEL_8},
            })
            continue

        correct          = pred_label == true_label
        true_cls_idx     = LABEL_8.index(true_label) if true_label in LABEL_8 else -1
        true_label_score = round(float(prob_vec[true_cls_idx]), 4) if true_cls_idx >= 0 else ""
        confidence_gap   = round(float(confidence) - float(true_label_score), 4) \
                           if true_label_score != "" else ""

        # Top-3
        sorted_idx = sorted(range(len(prob_vec)), key=lambda i: -prob_vec[i])
        top_k = [f"{LABEL_8[i]}({prob_vec[i]:.3f})" for i in sorted_idx[:3]]

        # Update accumulators
        stats[model_name][true_label]["t"] += 1
        confusion[model_name][true_label].append(pred_label)
        if correct:
            stats[model_name][true_label]["c"] += 1

        row = {
            "image_file"      : file,
            "image_index"     : img_index,
            "true_label"      : true_label,
            "model"           : model_name,
            "predicted_label" : pred_label,
            "correct"         : correct,
            "confidence"      : round(float(confidence), 4),
            "true_label_score": true_label_score,
            "confidence_gap"  : confidence_gap,
            "top1"            : top_k[0],
            "top2"            : top_k[1] if len(top_k) > 1 else "",
            "top3"            : top_k[2] if len(top_k) > 2 else "",
        }
        for i, cls in enumerate(LABEL_8):
            row[f"prob_{cls.replace('-','_')}"] = prob_vec[i]

        rows.append(row)

with open(OUTPUT_CSV, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print(f"  ✅ Saved {len(rows)} rows → {OUTPUT_CSV}")

# ─────────────────────────────────────────────────────────────────────────────
# CONSOLE REPORT
# ─────────────────────────────────────────────────────────────────────────────
def overall(s):
    c = sum(v["c"] for v in s.values())
    t = sum(v["t"] for v in s.values())
    return c, t, (c / t if t else 0)

active = [n for n, _, a in MODELS if a]
W = 16

print("\n" + "=" * 80)
print("  WAFER DEFECT CLASSIFICATION — EVALUATION REPORT")
print(f"  {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}  |  "
      f"{len(png_files)} images  |  {len(active)} models")
print("=" * 80)

# Per-class table
header = f"  {'Class':<12}" + "".join(f"  {n:>{W}}" for n in active)
print(f"\n{header}")
print("  " + "─" * (12 + (W + 2) * len(active)))
for cls in LABEL_8:
    row = f"  {cls:<12}"
    for name in active:
        t = stats[name][cls]["t"]
        c = stats[name][cls]["c"]
        row += f"  {(c/t):>{W}.3f}" if t else f"  {'—':>{W}}"
    print(row)
print("  " + "─" * (12 + (W + 2) * len(active)))

# Overall row
row = f"  {'OVERALL':<12}"
for name in active:
    c, t, acc = overall(stats[name])
    row += f"  {acc:>{W}.3f}"
print(row)

row = f"  {'(n samples)':<12}"
for name in active:
    _, t, _ = overall(stats[name])
    row += f"  {t:>{W}}"
print(row)

# Ranked summary
print(f"\n  {'Model':<22}  {'Acc':>6}  Bar")
print("  " + "─" * 50)
for name, acc in sorted([(n, overall(stats[n])[2]) for n in active], key=lambda x: -x[1]):
    c, t, _ = overall(stats[name])
    print(f"  {name:<22}  {acc:>6.4f}  {'█' * int(acc * 20)}  ({c}/{t})")

# Confusion
print(f"\n  CONFUSION SUMMARY")
print("  " + "─" * 50)
for name in active:
    errors = {cls: [p for p in confusion[name][cls] if p != cls]
              for cls in LABEL_8
              if any(p != cls for p in confusion[name][cls])}
    if not errors:
        continue
    print(f"\n  [{name}]")
    for cls, wrong in errors.items():
        t = stats[name][cls]["t"]
        c = stats[name][cls]["c"]
        top = Counter(wrong).most_common(2)
        err_str = ", ".join(f"{p}×{n}" for p, n in top)
        print(f"    {cls:<12}  {c}/{t} correct  confused with: {err_str}")

if skipped:
    print(f"\n  ⚠️  {skipped} file(s) skipped (unrecognised label)")

print(f"\n  CSV saved to: {os.path.abspath(OUTPUT_CSV)}")
print("=" * 80)