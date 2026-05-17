# ==================================================
# IMPORT LIBRARIES
# ==================================================
import streamlit as st
from PIL import Image
import numpy as np
from streamlit_drawable_canvas import st_canvas
import base64
import streamlit.components.v1 as components
from tensorflow.keras.models import load_model
import tensorflow as tf
from io import BytesIO

# Load trained model
@st.cache_resource
def load_my_model():
    return load_model("models/direct_classifier_cnn.keras")

model = load_my_model()

# ==================================================
# PAGE CONFIG
# ==================================================

# Configure Streamlit page settings
st.set_page_config(
    page_title="Wafer XAI System",
    layout="wide",
    initial_sidebar_state="collapsed",
)


# ==================================================
# SESSION STATE
# ==================================================

# Stores defect prediction results
if "predictions" not in st.session_state:
    st.session_state.predictions = None

# Stores uploaded or drawn wafer image
if "current_image" not in st.session_state:
    st.session_state.current_image = None

# Stores previous selected mode
# Used to detect mode switching
if "last_mode" not in st.session_state:
    st.session_state.last_mode = "Upload"

# ==================================================
# CSS
# ==================================================
st.markdown(
    """
<style>

/* FORCE TRUE WHITE BACKGROUND EVERYWHERE */
.stApp {
    background-color: #FFFFFF !important;
}

html, body, [class*="css"] {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

/* ALSO FORCE INNER CANVAS */
canvas {
    background: #FFFFFF !important;
}

/* ANALYZE BUTTON */
button[kind="primary"] {
    background: #0F172A !important;
    color: #FFFFFF !important;
    border-radius: 14px !important;
    border: none !important;
}

button[kind="primary"]:hover {
    background: #1E293B !important;
    color: #FFFFFF !important;
}


.block-container {
    padding-top: 0rem;
    padding-bottom: 0.5rem;
    max-width: 1500px;
}

/* HIDE STREAMLIT DEFAULTS */

header {
    visibility: hidden;
}

#MainMenu {
    visibility: hidden;
}

/* TITLES */

h1 {
    color: #0F172A !important;
    font-size: 52px !important;
    font-weight: 800 !important;
    letter-spacing: -1.5px;
}

h2 {
    color: #0F172A !important;
    font-size: 22px !important;
    font-weight: 650 !important;
}
/* RADIO BUTTON CONTAINER */
div[role="radiogroup"] {
    gap: 10px;
}

/* DEFAULT (UNSELECTED) */
div[role="radiogroup"] label {
    background: #FFFFFF !important;
    color: #64748B !important;
    border: 1px solid #E2E8F0 !important;
    border-radius: 12px !important;
    padding: 10px 18px !important;
    font-weight: 500;
    cursor: pointer;
}

/* TEXT INSIDE DEFAULT */
div[role="radiogroup"] label p {
    color: #64748B !important;
}

/* HOVER */
div[role="radiogroup"] label:hover {
    background: #F8FAFC !important;
    color: #0F172A !important;
}

/* SELECTED BUTTON */
div[role="radiogroup"] label[data-selected="true"] {
    background: #0F172A !important;
    border-color: #0F172A !important;
}

/* TEXT INSIDE SELECTED */
div[role="radiogroup"] label[data-selected="true"] p {
    color: #FFFFFF !important;
}

/* CANVAS TOOLBAR */

[data-testid="stCanvas"] button {
    background: #FFFFFF !important;
    color: #0F172A !important;
    border: 1px solid #E2E8F0 !important;
}

[data-testid="stCanvas"] button:hover {
    background: #F1F5F9 !important;
}

/* FIX ICON COLORS */
[data-testid="stCanvas"] svg {
    fill: #0F172A !important;
    stroke: #0F172A !important;
}

/* IMAGES */

img {
    border-radius: 18px;
}

</style>
""",
    unsafe_allow_html=True,
)

# ==================================================
# TITLE
# ==================================================

# Main application title
st.title("Explainable Wafer Defect Diagnosis")

# Subtitle below main title
st.markdown(
    """
<div style="
    color: #64748B;
    opacity: 0.9;
    font-size:18px;
    margin-top:-10px;
    margin-bottom:30px;
">
AI-powered wafer inspection and defect visualization system.
</div>
""",
    unsafe_allow_html=True,
)

# ==================================================
# MODE
# ==================================================

# Radio button to switch between
# Upload mode and Draw mode
mode = st.radio(
    "Input Mode",
    ["Upload", "Draw"],
    horizontal=True,
)


# ==================================================
# RESET WHEN SWITCHING MODES
# ==================================================

# Clear previous data whenever user switches modes
# Prevents old predictions from persisting

if mode != st.session_state.last_mode:
    # Reset prediction results
    st.session_state.predictions = None

    # Reset stored image
    st.session_state.current_image = None

    # Save current mode as last mode
    st.session_state.last_mode = mode


# ==================================================
# ICONS
# ==================================================

# Dictionary mapping defect names
# to corresponding icon image paths
defect_icons = {
    "Center": "icons/center.png",
    "Donut": "icons/donut.png",
    "Edge-Loc": "icons/edge-loc.png",
    "Edge-Ring": "icons/edge-ring.png",
    "Loc": "icons/local.png",
    "Random": "icons/random.png",
    "Scratch": "icons/scratch.png",
    "Near-full": "icons/near-full.png",
    "None": "icons/none.png",
}


# ==================================================
# IMAGE -> BASE64
# ==================================================

# Converts local image file into base64 string
# so it can be embedded directly into HTML
def get_base64_image(image_path):
    with open(image_path, "rb") as img_file:
        return base64.b64encode(img_file.read()).decode()


TARGET_SIZE = (64, 64)

def preprocess_image(pil_image):
    # convert to grayscale
    img = pil_image.convert("L")

    # convert to numpy
    arr = np.array(img).astype(np.float32)

    # normalize (important)
    arr = np.round(arr / 127.5)

    # add channel dimension
    arr = np.expand_dims(arr, axis=-1)

    # resize same as training
    tensor = tf.convert_to_tensor(arr)
    resized = tf.image.resize_with_pad(
        tensor,
        TARGET_SIZE[0],
        TARGET_SIZE[1],
        method=tf.image.ResizeMethod.NEAREST_NEIGHBOR
    )

    return resized.numpy()

# ==================================================
# DUMMY MODEL
# ==================================================

# Temporary AI prediction function
# Replace later with real ML model inference
label_names = [
    "Center",
    "Donut",
    "Edge-Loc",
    "Edge-Ring",
    "Loc",
    "Random",
    "Scratch",
    "Near-full",
    "None",
]

def predict_defects(image):

    img = preprocess_image(image)
    # add batch dimension
    img = np.expand_dims(img, axis=0)
    preds = model.predict(img)[0]
    return {
        label_names[i]: float(preds[i])
        for i in range(len(label_names))
    }


# ==================================================
# LAYOUT
# ==================================================

# Create two-column layout
# Left side = input
# Right side = predictions
left_col, right_col = st.columns([1.6, 1.0])


# ==================================================
# LEFT SIDE
# ==================================================

with left_col:

    st.markdown(
    """
    <h2 style="color: #0F172A; margin-bottom:6px;">
    Input Wafer Map
    </h2>
    """,
    unsafe_allow_html=True,
)

    # ============================
    # UPLOAD MODE
    # ============================
    if mode == "Upload":

        wrapper = st.container()

        wrapper.markdown(
            """
            <style>
            div[data-testid="stVerticalBlock"] > div:has(.upload-anchor) {
                position: relative;
                height: 300px;
            }

            div[data-testid="stVerticalBlock"] > div:has(.upload-anchor) [data-testid="stFileUploader"] {
                position: absolute;
                inset: 0;
                opacity: 0;
                z-index: 10;
            }

            div[data-testid="stVerticalBlock"] > div:has(.upload-anchor) [data-testid="stFileUploader"] > div {
                height: 100% !important;
            }

            div[data-testid="stVerticalBlock"] > div:has(.upload-anchor) [data-testid="stFileUploader"] section {
                height: 100% !important;
            }
            </style>
            """,
            unsafe_allow_html=True
        )

        with wrapper:
            uploaded_file = st.file_uploader(
                "",
                type=["png", "jpg", "jpeg"],
                label_visibility="collapsed",
                key="hidden_uploader"
            )

            if uploaded_file is not None:
                st.session_state.current_image = Image.open(uploaded_file).convert("RGB")
                st.session_state.predictions = predict_defects(
                    st.session_state.current_image
                )
            else:
                # 👇 THIS FIXES YOUR ISSUE
                st.session_state.current_image = None
                st.session_state.predictions = None
                
            st.markdown('<div class="upload-box">', unsafe_allow_html=True)

            if st.session_state.current_image is None:

                st.markdown("""
                <div style="
                    height:300px;
                    border:2px dashed #CBD5E1;
                    border-radius:28px;
                    display:flex;
                    flex-direction:column;
                    justify-content:center;
                    align-items:center;
                    text-align:center;
                    background: #FFFFFF;
                    padding:40px;
                ">
                    <div style="font-size:28px; margin-bottom:20px;">📤</div>
                    <div style="font-size:28px; font-weight:700; color:#0F172A;">Upload a wafer map</div>
                    <div style="color: #64748B;opacity:0.9;">Drag & drop or click to upload</div>
                </div>
                """, unsafe_allow_html=True)

            else:
                buffered = BytesIO()
                st.session_state.current_image.save(buffered, format="PNG")
                img_base64 = base64.b64encode(buffered.getvalue()).decode()

                st.markdown(f"""
                <div style="
                    height:300px;
                    border-radius:28px;
                    overflow:hidden;
                    background: #FFFFFF;
                    display:flex;
                    align-items:center;
                    justify-content:center;
                ">
                    <img src="data:image/png;base64,{img_base64}"
                        style="
                            width:100%;
                            height:100%;
                            object-fit:contain;
                        "
                    />
                </div>
                """, unsafe_allow_html=True)
            st.markdown('</div>', unsafe_allow_html=True)

    # ============================
    # DRAW MODE
    # ============================
    elif mode == "Draw":
        theme = st.get_option("theme.base")
        is_dark = theme == "dark"
        stroke = "#E5E7EB" if is_dark else "#0F172A"
        canvas_result = st_canvas(
        display_toolbar=True,
        fill_color="rgba(255,255,255,0)",
        stroke_width=4,
        stroke_color=stroke,
        background_color="#FFFFFF",
        width=900,
        height=300,
        drawing_mode="freedraw",
        key="canvas_draw",
    )

        if canvas_result.image_data is not None and canvas_result.json_data is not None:
            objects = canvas_result.json_data.get("objects", [])

            if len(objects) > 0:
                drawn_image = canvas_result.image_data[:, :, :3]
                drawn_image = np.mean(drawn_image, axis=2)

                st.session_state.current_image = Image.fromarray(
                    drawn_image.astype(np.uint8)
                )
            else:
                # 👇 THIS IS THE FIX
                st.session_state.current_image = None
                st.session_state.predictions = None 

        if st.session_state.current_image is not None:
            if st.button("Analyze Defect", type="primary", use_container_width=True):
                st.session_state.predictions = predict_defects(
                    st.session_state.current_image
                )


# ==================================================
# RIGHT SIDE
# ==================================================

with right_col:

    text_color = "#0F172A"
    card_bg = "#FFFFFF"
    border_color = "#E2E8F0"
    progress_bg = "#E2E8F0"

    theme = st.get_option("theme.base")
    is_dark = theme == "dark"
    # ==============================================
    # UPLOAD EMPTY STATE
    # ==============================================
    if mode == "Upload" and st.session_state.predictions is None:
        st.markdown(
            "<div style='height:650px;'></div>",
            unsafe_allow_html=True,
        )

    # ==============================================
    # DRAW EMPTY STATE
    # ==============================================
    elif mode == "Draw" and st.session_state.predictions is None:
        components.html(
            f"""
        <div style='
            margin-top:65px;
            padding:42px 32px;
            background:{card_bg};
            border:1px solid {border_color};
            border-radius:28px;
            text-align:center;
        '>

            <div style='font-size:64px; margin-bottom:16px;'>✏️</div>

            <div style='
                color:{text_color};
                font-size:34px;
                font-weight:700;
                margin-bottom:14px;
            '>
                Draw a wafer defect
            </div>

            <div style='
                color:{text_color};
                opacity:0.6;
                font-size:17px;
                line-height:1.8;
            '>
                Start drawing on the canvas to generate predictions.
            </div>

        </div>
        """,
            height=360,
        )

    # ==============================================
    # RESULTS
    # ==============================================
    elif st.session_state.predictions is not None:

        st.markdown(
            f"""
        <h2 style="
            color:{text_color};
            margin-bottom:22px;
            font-size:30px;
            font-weight:700;
        ">
            Detected Defects
        </h2>
        """,
            unsafe_allow_html=True,
        )

        defect_order = [
            "Center", "Donut", "Edge-Loc", "Edge-Ring",
            "Loc", "Random", "Scratch", "Near-full", "None",
        ]

        for row in range(0, len(defect_order), 3):

            cols = st.columns(3)

            for col_idx in range(3):

                idx = row + col_idx
                if idx >= len(defect_order):
                    continue

                defect = defect_order[idx]
                confidence = st.session_state.predictions.get(defect, 0.0)

                # Accent colors
                if confidence > 0.7:
                    accent = "#38BDF8" if is_dark else "#0891B2"
                elif confidence > 0.3:
                    accent = "#2563EB"
                else:
                    accent = "#64748B"

                bar_width = int(confidence * 100)

                with cols[col_idx]:

                    icon_base64 = get_base64_image(defect_icons[defect])

                    components.html(
                        f"""
                    <div style="
                        padding:10px;
                        border-radius:18px;
                        border:1px solid {border_color};
                        background:{card_bg};
                        height:100px;
                        margin-bottom:10px;
                    ">

                        <div style="display:flex; gap:8px; margin-bottom:10px;">

                            <img src="data:image/png;base64,{icon_base64}"
                                width="50"
                                height="50"
                                style="border-radius:50%; flex-shrink:0;"
                            />

                            <div style="flex:1;">

                                <div style="
                                    color:{text_color};
                                    font-size:13px;
                                    margin-bottom:4px;
                                ">
                                    {defect}
                                </div>

                                <div style="
                                    color:{accent};
                                    font-size:20px;
                                    font-weight:600;
                                ">
                                    {confidence*100:.0f}%
                                </div>

                            </div>
                        </div>

                        <div style="
                            width:100%;
                            height:8px;
                            background:{progress_bg};
                            border-radius:999px;
                        ">

                            <div style="
                                width:{bar_width}%;
                                height:100%;
                                background:{accent};
                                border-radius:999px;
                            "></div>

                        </div>

                    </div>
                    """,
                        height=130,
                    )

# ==================================================
# FOOTER
# ==================================================

# Footer section at bottom of page
st.markdown(
    """
<div style="
    margin-top:18px;
    color: #64748B; opacity: 0.6;
    font-size:15px;
">
Wafer Diagnosis Project
</div>
""",
    unsafe_allow_html=True,
)