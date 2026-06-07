# ==================================================
# MAIN STREAMLIT APP
# ==================================================
import streamlit as st
import matplotlib.cm as cm
from PIL import Image
import numpy as np
from streamlit_drawable_canvas import st_canvas
from io import BytesIO
import base64
import streamlit.components.v1 as components
import traceback
import os
import json
import tensorflow as tf

from config import LABELS, CURRENT_DIR
from datasets import WM_811K
from model import predict_defects



# =========================
# RCA Data
# =========================
@st.cache_data
def read_rca():
    with open(os.path.join(CURRENT_DIR, 'rca.json'), 'r') as file:
        return json.load(file)
    
RCA_DATA = read_rca()

# =========================
# PAGE CONFIG
# =========================
st.set_page_config(
    page_title="Wafer XAI System",
    layout="wide",
    initial_sidebar_state="collapsed",
)

# =========================
# CSS
# =========================
@st.cache_data
def read_styles():
    with open(os.path.join(CURRENT_DIR, 'styles.html'), 'r') as file:
        return file.read()

st.markdown(read_styles(), unsafe_allow_html=True)

# ==================================================
# HELPER — numpy mask → base64 PNG for HTML embedding
# ==================================================
def _mask_to_b64(mask_arr: np.ndarray, probability: float = 1.0) -> str:
    """Convert a 2-D float/uint8 numpy array to a base64 PNG string."""
    arr = mask_arr.copy().astype(np.float32)

    # Per-mask contrast stretch
    #mn, mx = arr.min(), arr.max()
    #if mx > mn:
    #    arr = (arr - mn) / (mx - mn)
    #else:
    #    arr = np.zeros_like(arr)

    # Weight by classifier probability so low-confidence masks stay dark
    #arr = arr * probability

    arr_uint8 = (arr * 255).clip(0, 255).astype(np.uint8)

    # Jet colormap
    colormap = cm.get_cmap('jet')
    colored = (colormap(arr)[:, :, :3] * 255).astype(np.uint8)

    # Navy background for near-zero pixels
    bg_mask = arr_uint8 < 15
    colored[bg_mask] = [15, 23, 42]

    img_pil = Image.fromarray(colored, mode="RGB")
    buf = BytesIO()
    img_pil.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode()

# =========================
# SESSION STATE
# =========================
defaults = {
    "predictions":        None,
    "current_image":      None,
    "last_mode":          "Upload",
    "image_bytes":        None,
    "uploaded_file_name": None,
}
for key, val in defaults.items():
    if key not in st.session_state:
        st.session_state[key] = val

# =========================
# HEADER ROW: Title left, Input Mode right
# =========================
header_left, header_right = st.columns([3, 1])

with header_left:
    st.markdown(
        """
        <div style="padding-top:8px;">
            <h1 style="margin-bottom:2px;">Explainable Wafer Defect Diagnosis</h1>
            <div style="color:#64748B;font-size:16px;margin-bottom:0;">
                AI-powered wafer inspection and defect visualization system.
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

with header_right:
    st.markdown("<div style='padding-top:22px;'></div>", unsafe_allow_html=True)
    mode = st.radio(
        "Input Mode",
        ["Upload", "Draw"],
        horizontal=True,
        label_visibility="visible",
    )

st.markdown("<div style='margin-bottom:16px;'></div>", unsafe_allow_html=True)

# =========================
# RESET ON MODE SWITCH
# =========================
if mode != st.session_state.last_mode:
    st.session_state.predictions        = None
    st.session_state.current_image      = None
    st.session_state.image_bytes        = None
    st.session_state.uploaded_file_name = None
    st.session_state.last_mode          = mode

# =========================
# LAYOUT: Left (input) + Right (defect analysis)
# =========================
left_col, right_col = st.columns([1, 1.8])

# ==================================================
# LEFT PANEL — Input Wafer Map
# ==================================================
with left_col:
    st.markdown(
        """<div style="background:#FFFFFF;border:1px solid #E2E8F0;border-radius:16px;
                       padding:20px;margin-bottom:16px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <div style="font-size:17px;font-weight:700;color:#0F172A;margin-bottom:16px;
                        padding-bottom:10px;border-bottom:1px solid #F1F5F9;">Input Wafer Map</div>
        """,
        unsafe_allow_html=True,
    )

    # ============================
    # UPLOAD MODE
    # ============================
    if mode == "Upload":

        uploaded_file = st.file_uploader(
            "Upload wafer image",
            type=["png", "jpg", "jpeg"],
            label_visibility="collapsed",
        )

        if uploaded_file is None:
            st.session_state.image_bytes        = None
            st.session_state.current_image      = None
            st.session_state.predictions        = None
            st.session_state.uploaded_file_name = None
        else:
            if st.session_state.uploaded_file_name != uploaded_file.name:
                st.session_state.uploaded_file_name = uploaded_file.name
                st.session_state.image_bytes         = uploaded_file.getvalue()
                st.session_state.current_image       = None
                st.session_state.predictions         = None

        # ── Render from session state ──
        if st.session_state.image_bytes is not None:
            image = Image.open(BytesIO(st.session_state.image_bytes)).convert("RGB")
            st.session_state.current_image = image

            img_b64 = base64.b64encode(st.session_state.image_bytes).decode()
            st.markdown(
                f"""
                <div style="width:100%;height:280px;background:#F1F5F9;border-radius:12px;
                            overflow:hidden;display:flex;align-items:center;
                            justify-content:center;margin-bottom:12px;">
                    <img src="data:image/png;base64,{img_b64}"
                         style="width:100%;height:100%;object-fit:contain;border-radius:12px;"/>
                </div>""",
                unsafe_allow_html=True,
            )

            # Upload another zone
            st.markdown(
                """
                <div style="border:1.5px dashed #CBD5E1;border-radius:12px;padding:14px 18px;
                            display:flex;align-items:center;gap:14px;background:#FAFAFA;margin-top:6px;">
                    <span style="font-size:22px;">☁️</span>
                    <div>
                        <div style="font-weight:600;color:#0F172A;font-size:14px;">Upload another wafer image</div>
                        <div style="color:#64748B;font-size:12px;">PNG, JPG, JPEG up to 10MB</div>
                    </div>
                </div>
                """,
                unsafe_allow_html=True,
            )

            # ── Run inference ──
            if st.session_state.predictions is None:
                with st.spinner("Analyzing defects…"):
                    try:
                        st.session_state.predictions = predict_defects(image)
                        # ── Temporary debug ──
                        results = st.session_state.predictions
                        masks = results["masks"]
                        probs = np.array(results["probabilities"]).flatten()
                        for i, label in enumerate(LABELS):
                            ch = masks[:, :, i]
                            st.write(f"{label} (prob={probs[i]:.3f}): min={ch.min():.4f} max={ch.max():.4f} mean={ch.mean():.4f}")
                        st.rerun()
                    except Exception:
                        st.error("**Prediction failed.** Full traceback:")
                        st.code(traceback.format_exc())

        else:
            st.markdown(
                """
                <div style="width:100%;height:280px;border:2px dashed #CBD5E1;border-radius:12px;
                            display:flex;flex-direction:column;align-items:center;justify-content:center;
                            text-align:center;background:#FAFAFA;margin-bottom:12px;">
                    <div style="font-size:36px;margin-bottom:12px;">📤</div>
                    <div style="font-size:20px;font-weight:700;color:#0F172A;margin-bottom:6px;">Upload a wafer map</div>
                    <div style="color:#64748B;font-size:14px;">Drag &amp; drop or click to upload</div>
                </div>""",
                unsafe_allow_html=True,
            )

    # ============================
    # DRAW MODE
    # ============================
    elif mode == "Draw":
        theme   = st.get_option("theme.base")

        canvas = st_canvas(
            display_toolbar=True,
            fill_color="rgba(255,255,255,0)",
            stroke_width=4,
            stroke_color="#FFFFFF",
            background_color="#000000",
            width=500,
            height=500,
            drawing_mode="freedraw",
            key="canvas_draw",
        )

        if canvas.image_data is not None and canvas.json_data is not None:
            objects = canvas.json_data.get("objects", [])
            if len(objects) > 0:
                image = canvas.image_data[:,:,0] / 255 + 1
                st.session_state.current_image = image
                try:
                    st.session_state.predictions = predict_defects(image)
                except Exception:
                    st.error("**Prediction failed.** Full traceback:")
                    st.code(traceback.format_exc())
            else:
                st.session_state.current_image = None
                st.session_state.predictions   = None

    st.markdown("</div>", unsafe_allow_html=True)


# ==================================================
# RIGHT PANEL — Defect Analysis (All Classes)
# ==================================================
with right_col:

    if st.session_state.predictions is not None:
        results = st.session_state.predictions
        probs   = np.array(results["probabilities"]).flatten()
        masks   = results["masks"]

        sorted_preds = sorted(
            zip(LABELS, probs),
            key=lambda x: x[1],
            reverse=True,
        )

        # Confidence bar color per defect index
        BAR_COLORS = [
            "#06B6D4",  # Center   – cyan
            "#3B82F6",  # Loc      – blue
            "#3B82F6",  # Edge-Ring– blue
            "#60A5FA",  # Edge-Loc – light blue
            "#8B5CF6",  # Scratch  – purple
            "#6366F1",  # Random   – indigo
            "#6366F1",  # Donut    – indigo
            "#8B5CF6",  # Near-full– purple
        ]

        PANEL_STYLE = ("background:#FFFFFF;border:1px solid #E2E8F0;border-radius:16px;"
                       "padding:20px;margin-bottom:16px;box-shadow:0 1px 3px rgba(0,0,0,0.05);")
        TITLE_STYLE = ("font-size:17px;font-weight:700;color:#0F172A;margin-bottom:16px;"
                       "padding-bottom:10px;border-bottom:1px solid #F1F5F9;")

        st.markdown(
            f'<div style="{PANEL_STYLE}"><div style="{TITLE_STYLE}">Defect Analysis (All Classes)</div></div>',
            unsafe_allow_html=True,
        )

        # Build the entire 2×4 grid as one HTML block so label/image/bar stay together
        grid_html = (
            '<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px;'
            'font-family:-apple-system,BlinkMacSystemFont,sans-serif;">'
        )

        for idx in range(len(LABELS)):
            defect     = LABELS[idx]
            confidence = float(probs[idx])
            mask_arr   = masks[:, :, idx]
            bar_color  = BAR_COLORS[idx % len(BAR_COLORS)]

            # Base64-encode mask for inline img
            mask_b64_grid = _mask_to_b64(mask_arr, probability=float(probs[idx]))

            grid_html += (
                f'<div style="background:#FFFFFF;border:1px solid #E2E8F0;border-radius:12px;'
                f'overflow:hidden;">'

                # Label
                f'<div style="text-align:center;font-weight:700;font-size:14px;'
                f'color:#0F172A;padding:8px 8px 6px 8px;">{defect}</div>'

                # mask image
                f'<div style="background:#0F172A;padding:4px;">'
                f'<img src="data:image/png;base64,{mask_b64_grid}" '
                f'style="width:100%;object-fit:contain;display:block;"/>'
                f'</div>'

                # Confidence bar
                f'<div style="background:{bar_color};padding:6px 0;'
                f'text-align:center;color:white;font-weight:700;font-size:13px;">'
                f'{confidence*100:.1f}%</div>'

                f'</div>'
            )

        grid_html += '</div>'
        st.markdown(grid_html, unsafe_allow_html=True)

    else:
        # Empty state for right panel
        st.markdown(
            """
            <div style="background:#FFFFFF;border:1px solid #E2E8F0;border-radius:16px;
                        padding:20px;min-height:400px;display:flex;align-items:center;
                        justify-content:center;flex-direction:column;text-align:center;
                        box-shadow:0 1px 3px rgba(0,0,0,0.05);">
                <div style="font-size:48px;margin-bottom:16px;">🔬</div>
                <div style="font-size:22px;font-weight:700;color:#0F172A;margin-bottom:8px;">
                    Defect Analysis (All Classes)
                </div>
                <div style="color:#64748B;font-size:15px;">
                    Upload or draw a wafer map to see predictions.
                </div>
            </div>
            """,
            unsafe_allow_html=True,
        )


# _mask_to_b64 moved to top — see definition after page config


# ==================================================
# STATS BAR (full width, 4 cards) — pure HTML
# ==================================================
if st.session_state.predictions is not None:

    results      = st.session_state.predictions
    probs        = np.array(results["probabilities"]).flatten()
    sorted_preds = sorted(zip(LABELS, probs), key=lambda x: x[1], reverse=True)

    top_defect, top_conf = sorted_preds[0]
    top_rca  = RCA_DATA.get(top_defect, {})
    severity = top_rca.get("severity", "—")
    process  = top_rca.get("process", "—")

    sev_color = "#EF4444" if "High" in severity else ("#F59E0B" if "Medium" in severity else "#3B82F6")

    st.markdown(
        f"""
        <div style="display:flex;gap:16px;margin:16px 0;flex-wrap:wrap;
                    font-family:-apple-system,BlinkMacSystemFont,sans-serif;">
            <div style="flex:1;min-width:180px;background:#FFFFFF;border:1px solid #E2E8F0;
                        border-radius:14px;padding:16px 20px;display:flex;align-items:center;
                        gap:14px;box-shadow:0 1px 3px rgba(0,0,0,0.04);">
                <div style="font-size:28px;line-height:1;">🏆</div>
                <div>
                    <div style="font-size:11px;font-weight:600;color:#94A3B8;text-transform:uppercase;
                                letter-spacing:0.5px;margin-bottom:3px;">Top Defect</div>
                    <div style="font-size:20px;font-weight:800;color:#8B5CF6;">{top_defect}</div>
                </div>
            </div>
            <div style="flex:1;min-width:180px;background:#FFFFFF;border:1px solid #E2E8F0;
                        border-radius:14px;padding:16px 20px;display:flex;align-items:center;
                        gap:14px;box-shadow:0 1px 3px rgba(0,0,0,0.04);">
                <div style="font-size:28px;line-height:1;">📈</div>
                <div>
                    <div style="font-size:11px;font-weight:600;color:#94A3B8;text-transform:uppercase;
                                letter-spacing:0.5px;margin-bottom:3px;">Top Confidence</div>
                    <div style="font-size:20px;font-weight:800;color:#10B981;">{top_conf*100:.1f}%</div>
                </div>
            </div>
            <div style="flex:1;min-width:180px;background:#FFFFFF;border:1px solid #E2E8F0;
                        border-radius:14px;padding:16px 20px;display:flex;align-items:center;
                        gap:14px;box-shadow:0 1px 3px rgba(0,0,0,0.04);">
                <div style="font-size:28px;line-height:1;">🛡️</div>
                <div>
                    <div style="font-size:11px;font-weight:600;color:#94A3B8;text-transform:uppercase;
                                letter-spacing:0.5px;margin-bottom:3px;">Severity</div>
                    <div style="font-size:20px;font-weight:800;color:{sev_color};">{severity}</div>
                </div>
            </div>
            <div style="flex:1;min-width:180px;background:#FFFFFF;border:1px solid #E2E8F0;
                        border-radius:14px;padding:16px 20px;display:flex;align-items:center;
                        gap:14px;box-shadow:0 1px 3px rgba(0,0,0,0.04);">
                <div style="font-size:28px;line-height:1;">⚙️</div>
                <div>
                    <div style="font-size:11px;font-weight:600;color:#94A3B8;text-transform:uppercase;
                                letter-spacing:0.5px;margin-bottom:3px;">Affected Process</div>
                    <div style="font-size:20px;font-weight:800;color:#3B82F6;">{process}</div>
                </div>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )


# ==================================================
# ROOT CAUSE ANALYSIS — Top 3  (pure HTML, no nested st.columns)
# ==================================================
if st.session_state.predictions is not None:

    results      = st.session_state.predictions
    probs        = np.array(results["probabilities"]).flatten()
    masks        = results["masks"]
    sorted_preds = sorted(zip(LABELS, probs), key=lambda x: x[1], reverse=True)

    st.markdown(
        '<div style="font-size:22px;font-weight:700;color:#0F172A;margin-top:8px;margin-bottom:16px;">'
        'Root Cause Analysis (Top 3 Predictions)</div>',
        unsafe_allow_html=True,
    )

    RANK_COLORS = ["#8B5CF6", "#4F46E5", "#2563EB"]
    SEV_BADGE_STYLE = {
        "High":        "background:#FEE2E2;color:#B91C1C;",
        "Medium-High": "background:#FEF3C7;color:#B45309;",
        "Medium":      "background:#DBEAFE;color:#1D4ED8;",
        "Variable":    "background:#E5E7EB;color:#374151;",
    }

    top3 = sorted_preds[:3]

    # Build one big HTML block — ALL inline styles, no class attributes on content divs
    # (Streamlit sanitizer strips class= from injected HTML; only inline styles survive)
    cards_html = (
        '<div style="display:grid;grid-template-columns:repeat(3,1fr);'
        'gap:16px;margin-bottom:20px;font-family:-apple-system,BlinkMacSystemFont,sans-serif;">'
    )

    LI_STYLE   = "font-size:12px;color:#374151;line-height:1.55;margin-bottom:3px;"
    LABEL_STYLE = "font-size:11px;font-weight:700;color:#94A3B8;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:3px;"
    VALUE_STYLE = "font-size:13px;color:#1E293B;line-height:1.5;margin-bottom:0;"

    for rank, (defect, confidence) in enumerate(top3):
        rca = RCA_DATA.get(defect, {})
        if not rca:
            continue

        rank_color  = RANK_COLORS[rank]
        sev_raw     = rca.get("severity", "")
        badge_style = SEV_BADGE_STYLE.get(sev_raw, "background:#E5E7EB;color:#374151;")

        # Encode mask image
        defect_idx = LABELS.index(defect) if defect in LABELS else None
        defect_prob = float(probs[defect_idx]) if defect_idx is not None else 1.0
        mask_b64 = _mask_to_b64(masks[:, :, defect_idx], probability=defect_prob) if defect_idx is not None else None
        mask_html = (
        f'<div style="background:#0F172A;border-radius:8px;overflow:hidden;padding:2px;">'
        f'<img src="data:image/png;base64,{mask_b64}" '
        f'style="width:100%;border-radius:6px;display:block;"/>'
        f'</div>'
        if mask_b64 else
        '<div style="width:100%;height:80px;background:#0F172A;border-radius:8px;"></div>'
    )

        def _bullets(items, symbol, color):
            return "".join(
                f'<div style="{LI_STYLE}">{symbol} {item}</div>'
                for item in items
            )

        causes_html  = _bullets(rca.get("root_cause", []), "•", "#374151")
        tools_html   = _bullets(rca.get("tools",       []), "✓", "#374151")
        actions_html = _bullets(rca.get("actions",     []), "✓", "#374151")

        process_val = rca.get("process", "—")
        summary_val = rca.get("summary", "—")
        conf_str    = f"{confidence*100:.1f}%"

        col_border = "border-right:1px solid #F1F5F9;"

        cards_html += (
            # Card wrapper
            f'<div style="background:#FFFFFF;border:1px solid #E2E8F0;border-radius:14px;'
            f'border-top:3px solid {rank_color};overflow:hidden;'
            f'box-shadow:0 1px 4px rgba(0,0,0,0.05);display:flex;flex-direction:column;">'

            # ── Header ──
            f'<div style="display:flex;align-items:center;gap:8px;padding:12px 14px;'
            f'border-bottom:1px solid #F1F5F9;flex-wrap:wrap;">'
            f'<div style="width:26px;height:26px;border-radius:7px;background:{rank_color};'
            f'color:white;font-weight:800;font-size:14px;display:flex;align-items:center;'
            f'justify-content:center;flex-shrink:0;">{rank+1}</div>'
            f'<span style="font-size:18px;font-weight:800;color:#0F172A;">{defect}</span>'
            f'<span style="padding:2px 10px;border-radius:20px;font-weight:700;font-size:13px;'
            f'background:{rank_color}22;color:{rank_color};">{conf_str}</span>'
            f'<div style="margin-left:auto;display:flex;align-items:center;gap:6px;">'
            f'<span style="font-size:12px;color:#94A3B8;">Severity:</span>'
            f'<span style="padding:2px 10px;border-radius:20px;font-size:12px;font-weight:700;{badge_style}">'
            f'{sev_raw}</span></div></div>'

            # ── Image + info ──
            f'<div style="display:flex;gap:12px;padding:12px 14px;border-bottom:1px solid #F1F5F9;">'
            f'<div style="flex:0 0 38%;">{mask_html}</div>'
            f'<div style="flex:1;min-width:0;">'
            f'<div style="{LABEL_STYLE}">Process</div>'
            f'<div style="{VALUE_STYLE}">\u2022 {process_val}</div>'
            f'<div style="{LABEL_STYLE}margin-top:10px;">Summary</div>'
            f'<div style="{VALUE_STYLE}">\u2022 {summary_val}</div>'
            f'</div></div>'

            # ── 3-column bottom ──
            f'<div style="display:grid;grid-template-columns:repeat(3,1fr);flex:1;">'

            f'<div style="padding:10px 12px;{col_border}">'
            f'<div style="font-size:11px;font-weight:800;text-transform:uppercase;'
            f'letter-spacing:0.5px;color:#EF4444;margin-bottom:8px;padding-bottom:5px;'
            f'border-bottom:2px solid #EF4444;">Top Root Causes</div>'
            f'{causes_html}</div>'

            f'<div style="padding:10px 12px;{col_border}">'
            f'<div style="font-size:11px;font-weight:800;text-transform:uppercase;'
            f'letter-spacing:0.5px;color:#F59E0B;margin-bottom:8px;padding-bottom:5px;'
            f'border-bottom:2px solid #F59E0B;">Inspection Tools</div>'
            f'{tools_html}</div>'

            f'<div style="padding:10px 12px;">'
            f'<div style="font-size:11px;font-weight:800;text-transform:uppercase;'
            f'letter-spacing:0.5px;color:#10B981;margin-bottom:8px;padding-bottom:5px;'
            f'border-bottom:2px solid #10B981;">Recommended Actions</div>'
            f'{actions_html}</div>'

            f'</div>'  # end bottom grid
            f'</div>'  # end card
        )

    cards_html += '</div>'  # end rca-grid
    st.markdown(cards_html, unsafe_allow_html=True)


# ==================================================
# FOOTER
# ==================================================
st.markdown(
    """
    <div style="margin-top:24px;padding:12px 18px;background:#F1F5F9;border-radius:10px;
                color:#64748B;font-size:13px;display:flex;align-items:center;gap:8px;">
        ℹ️ Percentages indicate the model's confidence for each defect class. Higher values mean higher likelihood.
    </div>
    """,
    unsafe_allow_html=True,
)
