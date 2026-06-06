# ==================================================
# STYLES — matching target UI
# ==================================================

def load_css():
    return """
<style>

/* =====================================================
   GOOGLE FONTS
===================================================== */
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&family=DM+Mono:wght@400;500&display=swap');

/* =====================================================
   GLOBAL RESET & BASE
===================================================== */
html, body, [class*="css"] {
    font-family: 'DM Sans', -apple-system, BlinkMacSystemFont, sans-serif !important;
}

.stApp {
    background-color: #F8FAFC !important;
}

.block-container {
    padding-top: 24px !important;
    padding-bottom: 40px !important;
    max-width: 1500px !important;
}

/* Hide streamlit chrome */
header { visibility: hidden; }
#MainMenu { visibility: hidden; }
footer { visibility: hidden; }

/* =====================================================
   TYPOGRAPHY
===================================================== */
h1 {
    color: #0F172A !important;
    font-size: 36px !important;
    font-weight: 800 !important;
    letter-spacing: -1px !important;
    line-height: 1.15 !important;
    margin-bottom: 4px !important;
}

h2, h3 {
    color: #0F172A !important;
}

/* =====================================================
   INPUT MODE RADIO — top right pill style
===================================================== */
div[role="radiogroup"] {
    gap: 6px;
    justify-content: flex-end;
}

div[role="radiogroup"] label {
    background: #FFFFFF !important;
    color: #64748B !important;
    border: 1px solid #E2E8F0 !important;
    border-radius: 10px !important;
    padding: 8px 20px !important;
    font-weight: 600 !important;
    font-size: 14px !important;
    cursor: pointer;
    transition: all 0.15s ease;
}

div[role="radiogroup"] label p {
    color: #64748B !important;
    font-weight: 600 !important;
}

div[role="radiogroup"] label:hover {
    background: #F1F5F9 !important;
}

div[role="radiogroup"] label[data-selected="true"] {
    background: #2563EB !important;
    border-color: #2563EB !important;
}

div[role="radiogroup"] label[data-selected="true"] p {
    color: #FFFFFF !important;
}

/* Radio label (the "Input Mode" text) */
div[data-testid="stRadio"] > label {
    font-weight: 600;
    font-size: 14px;
    color: #64748B;
}

/* =====================================================
   PANEL CARDS (white boxes with shadow)
===================================================== */
.panel-card {
    background: #FFFFFF;
    border: 1px solid #E2E8F0;
    border-radius: 16px;
    padding: 20px;
    margin-bottom: 16px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.panel-title {
    font-size: 17px;
    font-weight: 700;
    color: #0F172A;
    margin-bottom: 16px;
    padding-bottom: 10px;
    border-bottom: 1px solid #F1F5F9;
}

/* =====================================================
   WAFER IMAGE BOX
===================================================== */
.wafer-image-box {
    width: 100%;
    height: 280px;
    background: #F1F5F9;
    border-radius: 12px;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 12px;
}

.wafer-empty-box {
    width: 100%;
    height: 280px;
    border: 2px dashed #CBD5E1;
    border-radius: 12px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    background: #FAFAFA;
    margin-bottom: 12px;
}

/* Upload another zone */
.upload-another-zone {
    border: 1.5px dashed #CBD5E1;
    border-radius: 12px;
    padding: 14px 18px;
    display: flex;
    align-items: center;
    gap: 14px;
    background: #FAFAFA;
    cursor: pointer;
    margin-top: 6px;
}

/* =====================================================
   STATS BAR
===================================================== */
.stats-bar {
    display: flex;
    gap: 16px;
    margin: 16px 0;
    flex-wrap: wrap;
}

.stat-card {
    flex: 1;
    min-width: 180px;
    background: #FFFFFF;
    border: 1px solid #E2E8F0;
    border-radius: 14px;
    padding: 16px 20px;
    display: flex;
    align-items: center;
    gap: 14px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}

.stat-icon {
    font-size: 28px;
    line-height: 1;
}

.stat-label {
    font-size: 12px;
    font-weight: 600;
    color: #94A3B8;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 3px;
}

.stat-value {
    font-size: 20px;
    font-weight: 800;
    letter-spacing: -0.5px;
    line-height: 1.2;
}

/* =====================================================
   RCA GRID — 3 cards side by side
===================================================== */
.rca-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    margin-bottom: 20px;
}

.rca-card {
    background: #FFFFFF;
    border: 1px solid #E2E8F0;
    border-radius: 14px;
    overflow: hidden;
    box-shadow: 0 1px 4px rgba(0,0,0,0.05);
    display: flex;
    flex-direction: column;
}

/* ── Header row inside card ── */
.rca-card-header {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px 14px;
    border-bottom: 1px solid #F1F5F9;
    flex-wrap: wrap;
}

.rca-rank-badge {
    width: 26px;
    height: 26px;
    border-radius: 7px;
    color: white;
    font-weight: 800;
    font-size: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}

.rca-defect-name {
    font-size: 18px;
    font-weight: 800;
    color: #0F172A;
}

.rca-conf-pill {
    padding: 2px 10px;
    border-radius: 20px;
    font-weight: 700;
    font-size: 13px;
}

.rca-sev-group {
    margin-left: auto;
    display: flex;
    align-items: center;
    gap: 6px;
}

.rca-sev-label {
    font-size: 12px;
    color: #94A3B8;
    font-weight: 500;
}

.rca-sev-badge {
    padding: 2px 10px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 700;
}

/* ── Image + info row ── */
.rca-top-body {
    display: flex;
    gap: 12px;
    padding: 12px 14px;
    border-bottom: 1px solid #F1F5F9;
}

.rca-mask-wrap {
    flex: 0 0 38%;
}

.rca-mask-img {
    width: 100%;
    border-radius: 10px;
    display: block;
}

.rca-info-wrap {
    flex: 1;
    min-width: 0;
}

.rca-info-label {
    font-size: 11px;
    font-weight: 700;
    color: #94A3B8;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 3px;
}

.rca-info-value {
    font-size: 13px;
    color: #1E293B;
    line-height: 1.5;
}

/* ── 3-column bottom ── */
.rca-bottom-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0;
    flex: 1;
}

.rca-bottom-col {
    padding: 10px 12px;
    border-right: 1px solid #F1F5F9;
}

.rca-bottom-col:last-child {
    border-right: none;
}

.rca-col-title {
    font-size: 11px;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 8px;
    padding-bottom: 5px;
    border-bottom: 2px solid currentColor;
}

.rca-li {
    font-size: 12px;
    color: #374151;
    line-height: 1.55;
    margin-bottom: 3px;
}

/* =====================================================
   BADGES
===================================================== */
.badge {
    padding: 3px 10px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 700;
    display: inline-block;
}

.badge-critical {
    background: #FEE2E2;
    color: #B91C1C;
}

.badge-high {
    background: #FEF3C7;
    color: #B45309;
}

.badge-medium-high {
    background: #FEF3C7;
    color: #B45309;
}

.badge-medium {
    background: #DBEAFE;
    color: #1D4ED8;
}

.badge-variable {
    background: #E5E7EB;
    color: #374151;
}

/* =====================================================
   ANALYZE BUTTON
===================================================== */
button[kind="primary"] {
    background: #2563EB !important;
    color: #FFFFFF !important;
    border-radius: 10px !important;
    border: none !important;
    font-weight: 700 !important;
}

button[kind="primary"]:hover {
    background: #1D4ED8 !important;
}

/* =====================================================
   IMAGES (override border-radius for mask images)
===================================================== */
img {
    border-radius: 10px;
}

/* =====================================================
   FILE UPLOADER
===================================================== */
[data-testid="stFileUploader"] {
    border: none !important;
}

/* =====================================================
   CANVAS
===================================================== */
canvas {
    background: #FFFFFF !important;
    border-radius: 12px;
}

[data-testid="stCanvas"] button {
    background: #FFFFFF !important;
    color: #0F172A !important;
    border: 1px solid #E2E8F0 !important;
}

[data-testid="stCanvas"] button:hover {
    background: #F1F5F9 !important;
}

[data-testid="stCanvas"] svg {
    fill: #0F172A !important;
    stroke: #0F172A !important;
}

/* =====================================================
   FOOTER BAR
===================================================== */
.footer-bar {
    margin-top: 24px;
    padding: 12px 18px;
    background: #F1F5F9;
    border-radius: 10px;
    color: #64748B;
    font-size: 13px;
    display: flex;
    align-items: center;
    gap: 8px;
}

/* =====================================================
   SPINNER
===================================================== */
[data-testid="stSpinner"] {
    color: #2563EB !important;
}

/* =====================================================
   DIVIDER
===================================================== */
hr {
    border-color: #E2E8F0 !important;
    margin: 20px 0 !important;
}

</style>
"""