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
import traceback
import os
import json

from config import CURRENT_DIR
from datasets import WM_811K
from model import predict_defects


# =========================
# RCA Data
# =========================
@st.cache_data
def read_rca():
    with open(os.path.join(CURRENT_DIR, 'rca.json'), 'r') as f:
        return json.load(f)

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
    with open(os.path.join(CURRENT_DIR, 'styles.html'), 'r') as f:
        return f.read()

st.markdown(read_styles(), unsafe_allow_html=True)


# ==================================================
# HELPERS
# ==================================================
def _mask_to_b64(mask_arr: np.ndarray) -> str:
    """Convert a 2-D float32 mask to a jet-colormap base64 PNG."""
    arr = np.asarray(mask_arr, dtype=np.float32)
    colored = (cm.get_cmap('jet')(arr)[:, :, :3] * 255).astype(np.uint8)
    buf = BytesIO()
    Image.fromarray(colored, mode="RGB").save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode()


def _bullets(items: list, symbol: str) -> str:
    LI = "font-size:12px;color:#374151;line-height:1.55;margin-bottom:3px;"
    return "".join(f'<div style="{LI}">{symbol} {item}</div>' for item in items)


def _sorted_preds(probs: np.ndarray) -> list[tuple[str, float]]:
    """Return [(defect_name, probability), ...] sorted descending."""
    pairs = [(WM_811K.defect_from_int[i], float(probs[i]))
             for i in range(WM_811K.n_classes - 1)]
    return sorted(pairs, key=lambda x: x[1], reverse=True)


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
# HEADER ROW
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
        "Input Mode", ["Upload", "Draw"],
        horizontal=True, label_visibility="visible",
    )

st.markdown("<div style='margin-bottom:16px;'></div>", unsafe_allow_html=True)

# Reset on mode switch
if mode != st.session_state.last_mode:
    st.session_state.update(
        predictions=None, current_image=None,
        image_bytes=None, uploaded_file_name=None,
        last_mode=mode,
    )


# =========================
# LAYOUT
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

    if mode == "Upload":
        uploaded_file = st.file_uploader(
            "Upload wafer image", type=["png", "jpg", "jpeg"],
            label_visibility="collapsed",
        )

        if uploaded_file is None:
            st.session_state.update(
                image_bytes=None, current_image=None,
                predictions=None, uploaded_file_name=None,
            )
        elif st.session_state.uploaded_file_name != uploaded_file.name:
            st.session_state.update(
                uploaded_file_name=uploaded_file.name,
                image_bytes=uploaded_file.getvalue(),
                current_image=None, predictions=None,
            )

        if st.session_state.image_bytes is not None:
            image = Image.open(BytesIO(st.session_state.image_bytes)).convert("RGB")
            st.session_state.current_image = image

            img_b64 = base64.b64encode(st.session_state.image_bytes).decode()
            st.markdown(
                f"""<div style="width:100%;height:280px;background:#F1F5F9;border-radius:12px;
                            overflow:hidden;display:flex;align-items:center;
                            justify-content:center;margin-bottom:12px;">
                    <img src="data:image/png;base64,{img_b64}"
                         style="width:100%;height:100%;object-fit:contain;border-radius:12px;"/>
                </div>""",
                unsafe_allow_html=True,
            )
            st.markdown(
                """<div style="border:1.5px dashed #CBD5E1;border-radius:12px;padding:14px 18px;
                            display:flex;align-items:center;gap:14px;background:#FAFAFA;margin-top:6px;">
                    <span style="font-size:22px;">☁️</span>
                    <div>
                        <div style="font-weight:600;color:#0F172A;font-size:14px;">Upload another wafer image</div>
                        <div style="color:#64748B;font-size:12px;">PNG, JPG, JPEG up to 10MB</div>
                    </div>
                </div>""",
                unsafe_allow_html=True,
            )

            if st.session_state.predictions is None:
                with st.spinner("Analyzing defects…"):
                    try:
                        st.session_state.predictions = predict_defects(image)
                    except Exception:
                        st.error("**Prediction failed.**")
                        st.code(traceback.format_exc())
                st.rerun()  # outside try so it only runs on success

        else:
            st.markdown(
                """<div style="width:100%;height:280px;border:2px dashed #CBD5E1;border-radius:12px;
                            display:flex;flex-direction:column;align-items:center;justify-content:center;
                            text-align:center;background:#FAFAFA;margin-bottom:12px;">
                    <div style="font-size:36px;margin-bottom:12px;">📤</div>
                    <div style="font-size:20px;font-weight:700;color:#0F172A;margin-bottom:6px;">Upload a wafer map</div>
                    <div style="color:#64748B;font-size:14px;">Drag &amp; drop or click to upload</div>
                </div>""",
                unsafe_allow_html=True,
            )

    elif mode == "Draw":
        canvas = st_canvas(
            display_toolbar=True,
            fill_color="rgba(255,255,255,0)",
            stroke_width=12,
            stroke_color="#FFFFFF",
            background_color="#000000",
            width=500, height=500,
            drawing_mode="freedraw",
            key="canvas_draw",
        )

        if canvas.image_data is not None and canvas.json_data is not None:
            if canvas.json_data.get("objects"):
                image = canvas.image_data[:, :, 0] / 255 + 1
                st.session_state.current_image = image
                try:
                    st.session_state.predictions = predict_defects(image)
                except Exception:
                    st.error("**Prediction failed.**")
                    st.code(traceback.format_exc())
            else:
                st.session_state.current_image = None
                st.session_state.predictions   = None

    st.markdown("</div>", unsafe_allow_html=True)


# ==================================================
# RIGHT PANEL — Defect Analysis (All Classes)
# ==================================================
BAR_COLORS = [
    "#06B6D4",  # Center    – cyan
    "#3B82F6",  # Loc       – blue
    "#3B82F6",  # Edge-Ring – blue
    "#60A5FA",  # Edge-Loc  – light blue
    "#8B5CF6",  # Scratch   – purple
    "#6366F1",  # Random    – indigo
    "#6366F1",  # Donut     – indigo
    "#8B5CF6",  # Near-full – purple
]

PANEL_HDR = (
    '<div style="background:#FFFFFF;border:1px solid #E2E8F0;border-radius:16px;'
    'padding:20px;margin-bottom:16px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">'
    '<div style="font-size:17px;font-weight:700;color:#0F172A;margin-bottom:16px;'
    'padding-bottom:10px;border-bottom:1px solid #F1F5F9;">Defect Analysis (All Classes)</div>'
)

with right_col:
    if st.session_state.predictions is not None:
        results = st.session_state.predictions
        probs   = np.array(results["probabilities"]).flatten()
        masks   = results["masks"]

        grid_html = (
            PANEL_HDR +
            '<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px;'
            'font-family:-apple-system,BlinkMacSystemFont,sans-serif;">'
        )

        for idx, defect in [(i, d) for i, d in WM_811K.defect_from_int.items() if i != -1]:
            confidence = float(probs[idx])
            bar_color  = BAR_COLORS[idx % len(BAR_COLORS)]
            mask_b64   = _mask_to_b64(masks[:, :, idx])

            grid_html += (
                f'<div style="background:#FFFFFF;border:1px solid #E2E8F0;'
                f'border-radius:12px;overflow:hidden;">'
                f'<div style="text-align:center;font-weight:700;font-size:14px;'
                f'color:#0F172A;padding:8px 8px 6px 8px;">{defect}</div>'
                f'<div style="background:#0F172A;padding:4px;">'
                f'<img src="data:image/png;base64,{mask_b64}" '
                f'style="width:100%;object-fit:contain;display:block;"/></div>'
                f'<div style="background:{bar_color};padding:6px 0;text-align:center;'
                f'color:white;font-weight:700;font-size:13px;">{confidence*100:.1f}%</div>'
                f'</div>'
            )

        grid_html += '</div></div>'  # close grid + panel card
        st.markdown(grid_html, unsafe_allow_html=True)

    else:
        st.markdown(
            """<div style="background:#FFFFFF;border:1px solid #E2E8F0;border-radius:16px;
                        padding:20px;min-height:400px;display:flex;align-items:center;
                        justify-content:center;flex-direction:column;text-align:center;
                        box-shadow:0 1px 3px rgba(0,0,0,0.05);">
                <div style="font-size:48px;margin-bottom:16px;">🔬</div>
                <div style="font-size:22px;font-weight:700;color:#0F172A;margin-bottom:8px;">
                    Defect Analysis (All Classes)</div>
                <div style="color:#64748B;font-size:15px;">
                    Upload or draw a wafer map to see predictions.</div>
            </div>""",
            unsafe_allow_html=True,
        )


# ==================================================
# STATS BAR + RCA — only rendered when predictions exist
# ==================================================
if st.session_state.predictions is not None:
    results      = st.session_state.predictions
    probs        = np.array(results["probabilities"]).flatten()
    masks        = results["masks"]
    sorted_preds = _sorted_preds(probs)

    top_defect, top_conf = sorted_preds[0]
    top_rca  = RCA_DATA.get(top_defect, {})
    severity = top_rca.get("severity", "—")
    process  = top_rca.get("process", "—")
    sev_color = "#EF4444" if "High" in severity else ("#F59E0B" if "Medium" in severity else "#3B82F6")

    # ── Stats bar ──
    st.markdown(
        f"""<div style="display:flex;gap:16px;margin:16px 0;flex-wrap:wrap;
                    font-family:-apple-system,BlinkMacSystemFont,sans-serif;">
            <div style="flex:1;min-width:180px;background:#FFFFFF;border:1px solid #E2E8F0;
                        border-radius:14px;padding:16px 20px;display:flex;align-items:center;
                        gap:14px;box-shadow:0 1px 3px rgba(0,0,0,0.04);">
                <div style="font-size:28px;">🏆</div>
                <div><div style="font-size:11px;font-weight:600;color:#94A3B8;text-transform:uppercase;
                            letter-spacing:0.5px;margin-bottom:3px;">Top Defect</div>
                    <div style="font-size:20px;font-weight:800;color:#8B5CF6;">{top_defect}</div></div>
            </div>
            <div style="flex:1;min-width:180px;background:#FFFFFF;border:1px solid #E2E8F0;
                        border-radius:14px;padding:16px 20px;display:flex;align-items:center;
                        gap:14px;box-shadow:0 1px 3px rgba(0,0,0,0.04);">
                <div style="font-size:28px;">📈</div>
                <div><div style="font-size:11px;font-weight:600;color:#94A3B8;text-transform:uppercase;
                            letter-spacing:0.5px;margin-bottom:3px;">Top Confidence</div>
                    <div style="font-size:20px;font-weight:800;color:#10B981;">{top_conf*100:.1f}%</div></div>
            </div>
            <div style="flex:1;min-width:180px;background:#FFFFFF;border:1px solid #E2E8F0;
                        border-radius:14px;padding:16px 20px;display:flex;align-items:center;
                        gap:14px;box-shadow:0 1px 3px rgba(0,0,0,0.04);">
                <div style="font-size:28px;">🛡️</div>
                <div><div style="font-size:11px;font-weight:600;color:#94A3B8;text-transform:uppercase;
                            letter-spacing:0.5px;margin-bottom:3px;">Severity</div>
                    <div style="font-size:20px;font-weight:800;color:{sev_color};">{severity}</div></div>
            </div>
            <div style="flex:1;min-width:180px;background:#FFFFFF;border:1px solid #E2E8F0;
                        border-radius:14px;padding:16px 20px;display:flex;align-items:center;
                        gap:14px;box-shadow:0 1px 3px rgba(0,0,0,0.04);">
                <div style="font-size:28px;">⚙️</div>
                <div><div style="font-size:11px;font-weight:600;color:#94A3B8;text-transform:uppercase;
                            letter-spacing:0.5px;margin-bottom:3px;">Affected Process</div>
                    <div style="font-size:20px;font-weight:800;color:#3B82F6;">{process}</div></div>
            </div>
        </div>""",
        unsafe_allow_html=True,
    )

    # ── RCA ──
    st.markdown(
        '<div style="font-size:22px;font-weight:700;color:#0F172A;'
        'margin-top:8px;margin-bottom:16px;">Root Cause Analysis (Top 3 Predictions)</div>',
        unsafe_allow_html=True,
    )

    RANK_COLORS = ["#8B5CF6", "#4F46E5", "#2563EB"]
    SEV_BADGE_STYLE = {
        "High":        "background:#FEE2E2;color:#B91C1C;",
        "Medium-High": "background:#FEF3C7;color:#B45309;",
        "Medium":      "background:#DBEAFE;color:#1D4ED8;",
        "Variable":    "background:#E5E7EB;color:#374151;",
    }
    LABEL_S = "font-size:11px;font-weight:700;color:#94A3B8;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:3px;"
    VALUE_S = "font-size:13px;color:#1E293B;line-height:1.5;margin-bottom:0;"
    COL_BDR = "border-right:1px solid #F1F5F9;"

    cards_html = (
        '<div style="display:grid;grid-template-columns:repeat(3,1fr);'
        'gap:16px;margin-bottom:20px;font-family:-apple-system,BlinkMacSystemFont,sans-serif;">'
    )

    for rank, (defect, confidence) in enumerate(sorted_preds[:3]):
        rca = RCA_DATA.get(defect, {})
        if not rca:
            continue

        rank_color  = RANK_COLORS[rank]
        sev_raw     = rca.get("severity", "")
        badge_style = SEV_BADGE_STYLE.get(sev_raw, "background:#E5E7EB;color:#374151;")
        conf_str    = f"{confidence*100:.1f}%"

        mask_b64 = _mask_to_b64(masks[:, :, WM_811K.defect_to_int[defect]])
        mask_html = (
            f'<div style="background:#0F172A;border-radius:8px;overflow:hidden;padding:2px;">'
            f'<img src="data:image/png;base64,{mask_b64}" style="width:100%;display:block;"/>'
            f'</div>'
        )

        cards_html += (
            f'<div style="background:#FFFFFF;border:1px solid #E2E8F0;border-radius:14px;'
            f'border-top:3px solid {rank_color};overflow:hidden;'
            f'box-shadow:0 1px 4px rgba(0,0,0,0.05);display:flex;flex-direction:column;">'

            # Header
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

            # Image + info
            f'<div style="display:flex;gap:12px;padding:12px 14px;border-bottom:1px solid #F1F5F9;">'
            f'<div style="flex:0 0 38%;">{mask_html}</div>'
            f'<div style="flex:1;min-width:0;">'
            f'<div style="{LABEL_S}">Process</div>'
            f'<div style="{VALUE_S}">\u2022 {rca.get("process","—")}</div>'
            f'<div style="{LABEL_S}margin-top:10px;">Summary</div>'
            f'<div style="{VALUE_S}">\u2022 {rca.get("summary","—")}</div>'
            f'</div></div>'

            # 3-col bottom
            f'<div style="display:grid;grid-template-columns:repeat(3,1fr);flex:1;">'
            f'<div style="padding:10px 12px;{COL_BDR}">'
            f'<div style="font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:0.5px;'
            f'color:#EF4444;margin-bottom:8px;padding-bottom:5px;border-bottom:2px solid #EF4444;">'
            f'Top Root Causes</div>{_bullets(rca.get("root_cause",[]),"•")}</div>'

            f'<div style="padding:10px 12px;{COL_BDR}">'
            f'<div style="font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:0.5px;'
            f'color:#F59E0B;margin-bottom:8px;padding-bottom:5px;border-bottom:2px solid #F59E0B;">'
            f'Inspection Tools</div>{_bullets(rca.get("tools",[]),"✓")}</div>'

            f'<div style="padding:10px 12px;">'
            f'<div style="font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:0.5px;'
            f'color:#10B981;margin-bottom:8px;padding-bottom:5px;border-bottom:2px solid #10B981;">'
            f'Recommended Actions</div>{_bullets(rca.get("actions",[]),"✓")}</div>'

            f'</div></div>'
        )

    cards_html += '</div>'
    st.markdown(cards_html, unsafe_allow_html=True)


# ==================================================
# FOOTER
# ==================================================
st.markdown(
    """<div style="margin-top:24px;padding:12px 18px;background:#F1F5F9;border-radius:10px;
                color:#64748B;font-size:13px;">
        ℹ️ Percentages indicate the model's confidence for each defect class. Higher values mean higher likelihood.
    </div>""",
    unsafe_allow_html=True,
)