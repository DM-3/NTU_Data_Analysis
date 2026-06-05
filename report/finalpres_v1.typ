// ============================================================
// WaferDX — Defence Presentation
// NTU Data Analysis and Machine Learning with Python
// ============================================================

#set page(
  paper: "presentation-16-9",
  margin: (top: 1.2cm, bottom: 1.2cm, left: 1.5cm, right: 1.5cm),
  fill: rgb("#0f1923"),
)

#set text(
  font: "New Computer Modern",
  size: 18pt,
  fill: rgb("#e8edf2"),
  lang: "en",
)

#set par(leading: 0.75em)

// ── Colour palette ──────────────────────────────────────────
#let accent   = rgb("#38bdf8")   // sky blue  — titles, highlights
#let accent2  = rgb("#f97316")   // orange    — warnings / key numbers
#let muted    = rgb("#94a3b8")   // slate     — captions, secondary text
#let surface  = rgb("#1e2d3d")   // card background
#let good     = rgb("#4ade80")   // green     — positive results
#let bad      = rgb("#f87171")   // red       — failure / limitation

// ── Helper components ────────────────────────────────────────

// Full-width horizontal rule
#let hrule = {
  v(0.3em)
  line(length: 100%, stroke: 0.4pt + muted)
  v(0.3em)
}

// Slide title bar
#let slide-title(t) = {
  rect(
    width: 100%,
    inset: (x: 14pt, y: 8pt),
    radius: 5pt,
    fill: surface,
    stroke: (left: 3pt + accent),
  )[
    #text(size: 22pt, weight: "bold", fill: accent)[#t]
  ]
  v(0.6em)
}

// Coloured badge
#let badge(content, color: accent) = {
  box(
    inset: (x: 8pt, y: 3pt),
    radius: 4pt,
    fill: color.lighten(80%),
    stroke: 0.5pt + color,
  )[
    #text(size: 13pt, fill: color, weight: "bold")[#content]
  ]
}

// Card box
#let card(content, width: 100%) = {
  rect(
    width: width,
    inset: 12pt,
    radius: 5pt,
    fill: surface,
    stroke: 0.5pt + muted.lighten(20%),
  )[#content]
}

// Bullet item with accent dot
#let item(content) = {
  grid(
    columns: (10pt, 1fr),
    column-gutter: 6pt,
    text(fill: accent)[▸],
    content,
  )
  v(0.25em)
}

// ── Page counter helper ──────────────────────────────────────
#let slide-num(n, total: 14) = {
  align(right)[
    #text(size: 11pt, fill: muted)[#n / #total]
  ]
}


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 1 — Title                                         ║
// ╚══════════════════════════════════════════════════════════╝
#align(center + horizon)[
  #v(1em)
  #text(size: 14pt, fill: muted)[NTU · Data Analysis and Machine Learning with Python · Spring 2026]
  #v(1.2em)
  #text(
    size: 30pt,
    weight: "bold",
    fill: accent,
  )[WaferDX]
  #v(0.4em)
  #text(size: 20pt, fill: rgb("#e8edf2"))[
    An Explainable AI Decision Support System \
    for Semiconductor Wafer Defect Diagnosis
  ]
  #v(1.6em)
  #hrule
  #v(0.6em)
  #text(size: 14pt, fill: muted)[
    Abhirup Sain · David Spickenheuer · Martin Werner · \
    Matti Lehmann · Staniya Thomas
  ]
  #v(0.4em)
  #text(size: 12pt, fill: muted)[June 2026]
]

#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 2 — Agenda                                        ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Presentation Outline]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,
  row-gutter: 10pt,

  card[
    #text(fill: accent, weight: "bold")[Problem & Motivation]
    #v(0.4em)
    #item[Semiconductor yield recovery bottleneck]
    #item[Limitations of existing tools]
    #item[What WaferDX solves]
  ],

  card[
    #text(fill: accent, weight: "bold")[System Design]
    #v(0.4em)
    #item[Architecture overview]
    #item[3 key design decisions]
    #item[Processing pipeline]
  ],

  card[
    #text(fill: accent, weight: "bold")[Evaluation]
    #v(0.4em)
    #item[4 model variants · 160 test images]
    #item[Per-class accuracy breakdown]
    #item[Critical failure cases]
  ],

  card[
    #text(fill: accent, weight: "bold")[Insights & Future Work]
    #v(0.4em)
    #item[Transferable design principles]
    #item[Governance risks]
    #item[Extensions with more resources]
  ],
)

#slide-num(2)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 3 — Application Context                          ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[The Problem: Wafer Defect Diagnosis]

#grid(
  columns: (1.1fr, 0.9fr),
  column-gutter: 18pt,

  [
    #item[A 300mm fab lot contains *25 wafers*, each passing through *400–600 process steps*]
    #item[Electrical test produces a *binary die map*: pass / fail at every die location]
    #item[The *spatial pattern* of failures — not the count — identifies the responsible tool]
    #v(0.6em)
    #hrule
    #v(0.4em)
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 8pt,
      card(width: 100%)[
        #text(fill: accent2, weight: "bold")[Center cluster]
        #v(0.2em)
        #text(size: 14pt)[→ CVD deposition drift]
      ],
      card(width: 100%)[
        #text(fill: accent2, weight: "bold")[Linear scratch]
        #v(0.2em)
        #text(size: 14pt)[→ Robot arm damage]
      ],
    )
  ],

  card[
    #text(fill: accent, weight: "bold", size: 16pt)[Why speed matters]
    #v(0.5em)
    #item[Every undetected faulty step processes *more wafers under failure conditions*]
    #item[Manual map interpretation is *error-prone* and a yield-recovery *bottleneck*]
    #v(0.6em)
    #text(fill: muted, size: 14pt)[
      Existing tools either detect anomalies without classifying them, or classify without explaining
      *which spatial region* drove the decision.
    ]
  ],
)

#slide-num(3)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 4 — WaferDX Solution                             ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[WaferDX: What the System Does]

#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  column-gutter: 10pt,

  card[
    #align(center)[#text(size: 28pt)[🔍]]
    #align(center)[#text(fill: accent, weight: "bold", size: 14pt)[Classify]]
    #v(0.3em)
    #text(size: 14pt)[CNN classifies wafer map against *8 defect types* from WM-811K (811K maps)]
  ],

  card[
    #align(center)[#text(size: 28pt)[🗺️]]
    #align(center)[#text(fill: accent, weight: "bold", size: 14pt)[Explain]]
    #v(0.3em)
    #text(size: 14pt)[*Grad-CAM heatmap* shows which spatial region drove the prediction]
  ],

  card[
    #align(center)[#text(size: 28pt)[🔧]]
    #align(center)[#text(fill: accent, weight: "bold", size: 14pt)[Advise]]
    #v(0.3em)
    #text(size: 14pt)[*Knowledge-based RCA* maps defect class → process step → recommended action]
  ],

  card[
    #align(center)[#text(size: 28pt)[⚠️]]
    #align(center)[#text(fill: accent, weight: "bold", size: 14pt)[Warn]]
    #v(0.3em)
    #text(size: 14pt)[*Dual-hypothesis display* when confidence gap between top-1 and top-2 < 0.15]
  ],
)

#v(0.8em)
#card[
  #text(fill: muted, size: 15pt)[
    *Dataset:* WM-811K · 811,457 maps · 46,393 lots · 8 defect classes + None \
    *Stack:* TensorFlow/Keras (CNN) · Streamlit (UI) · Grad-CAM (explainability) · Python RCA lookup \
    *Input:* Upload PNG *or* draw directly on interactive canvas
  ]
]

#slide-num(4)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 5 — Processing Pipeline                          ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[System Pipeline]

#align(center)[
  #let step(n, title, detail) = rect(
    width: 88%,
    inset: (x: 14pt, y: 7pt),
    radius: 4pt,
    fill: surface,
    stroke: (left: 3pt + accent),
  )[
    #grid(
      columns: (28pt, 1fr),
      column-gutter: 8pt,
      align(center)[#badge[#n]],
      [
        #text(weight: "bold", fill: accent)[#title]
        #h(6pt)
        #text(size: 14pt, fill: muted)[#detail]
      ],
    )
  ]

  #let arrow = align(center)[#text(size: 16pt, fill: muted)[↓]]

  #step("1", "Input", "Upload PNG or draw on canvas")
  #arrow
  #step("2", "Preprocess", "Grayscale → zero-pad → nearest-neighbour resize 96×96 → normalise to {0.0, 0.5, 1.0}")
  #arrow
  #step("3", "CNN Inference", "Softmax over 8 defect classes")
  #arrow
  #step("4", "Grad-CAM", "Gradient of top-class score w.r.t. final conv layer → weighted activation heatmap")
  #arrow
  #step("5", "Display", "Ranked probability bars + heatmap overlay")
  #arrow
  #step("6", "RCA Lookup", "Defect class → process hypothesis + recommended inspection action")
  #arrow
  #step("7", "Multi-hypothesis", [If confidence gap < 0.15 #text(fill: accent2)[→ show dual hypothesis panel]])
  #arrow
  #rect(
    width: 88%,
    inset: (x: 14pt, y: 7pt),
    radius: 4pt,
    fill: accent.lighten(85%),
    stroke: (left: 3pt + good),
  )[
    #text(weight: "bold", fill: good)[8 · Engineer Decides] #h(6pt)
    #text(size: 14pt, fill: muted)[WaferDX never issues a recommendation to act]
  ]
]

#slide-num(5)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 6 — Design Decision 1                            ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Design Decision 1: CNN vs. Segmentation Pipeline]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: bad, weight: "bold")[Seg → CLF Pipeline (rejected as primary)]
    #v(0.4em)
    #item[Segmentation network produces per-pixel activation maps per class]
    #item[Second classifier operates on those maps]
    #item[*Theoretically* more interpretable — spatial reasoning visible directly]
    #v(0.5em)
    #hrule
    #text(fill: bad, weight: "bold")[Result: 11.9% accuracy]
    #v(0.3em)
    #text(size: 14pt)[Classification head predicted *"Center" with confidence 1.0* for >90% of all inputs — regardless of true class. No discriminative signal from segmentation activations.]
  ],

  card[
    #text(fill: good, weight: "bold")[Direct CNN (chosen)]
    #v(0.4em)
    #item[Single end-to-end optimization problem]
    #item[Grad-CAM provides mathematically grounded post-hoc spatial attribution]
    #item[More stable training, simpler debugging]
    #v(0.5em)
    #hrule
    #text(fill: good, weight: "bold")[Result: 13.1% accuracy (Best CNN)]
    #v(0.3em)
    #text(size: 14pt, fill: muted)[Root cause of Seg → CLF failure: two components trained *independently*, no end-to-end gradient flow. Joint training would be correct long-term fix.]
  ],
)

#slide-num(6)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 7 — Design Decision 2                            ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Design Decision 2: Class-Agnostic vs. Selective Augmentation]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: accent, weight: "bold")[What happened]
    #v(0.5em)
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 6pt,
      align(center)[#text(fill: muted, size: 13pt)[Class]],
      align(center)[#text(fill: muted, size: 13pt)[No Aug]],
      align(center)[#text(fill: muted, size: 13pt)[+ Aug]],

      align(center)[Edge-Loc], align(center)[30%], align(center)[#text(fill: good, weight: "bold")[85%]],
      align(center)[Donut],    align(center)[65%], align(center)[#text(fill: bad, weight: "bold")[10%]],
    )
    #v(0.6em)
    #text(size: 14pt)[*Edge-Loc:* failure can appear at any angular position — orientation invariance *helps*]
    #v(0.3em)
    #text(size: 14pt)[*Donut:* radially symmetric ring — rotation removes orientation cues that define the class, *destroying accuracy*]
  ],

  card[
    #text(fill: accent, weight: "bold")[Lesson & correct approach]
    #v(0.5em)
    #item[Uniform augmentation is *not a safe default* when class identity is geometrically defined]
    #item[*Class-selective augmentation* is required:]
    #v(0.2em)
    #rect(inset: 8pt, fill: rgb("#0f1923"), radius: 4pt)[
      #text(size: 13pt)[
        Apply rotation/flip: Edge-Loc, Scratch, Random, Loc\
        #text(fill: bad)[Exclude:] Donut, Edge-Ring, Center, Near-full
      ]
    ]
    #v(0.4em)
    #text(size: 13pt, fill: muted)[Not implemented within project timeline — identified post-evaluation. Augmented model retained in UI for class distributions where it helps.]
  ],
)

#slide-num(7)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 8 — Design Decision 3                            ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Design Decision 3: Knowledge-Based vs. Learned RCA]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: accent, weight: "bold")[Why no learned RCA?]
    #v(0.4em)
    #item[Requires labeled causal chains: *wafer map → confirmed tool failure*]
    #item[No public dataset links WM-811K labels to confirmed fab process failures]
    #item[SECOM (UCI): sensor data, no spatial maps or defect labels]
    #item[LLM-generated hypotheses: plausible-sounding but *unverifiable* — rejected]
  ],

  card[
    #text(fill: good, weight: "bold")[Knowledge-based lookup (chosen)]
    #v(0.4em)
    #grid(
      columns: (auto, 1fr),
      column-gutter: 8pt,
      row-gutter: 5pt,
      text(fill: accent2, size: 13pt)[Center],   text(size: 13pt)[CVD deposition drift; spin-coat blockage],
      text(fill: accent2, size: 13pt)[Donut],    text(size: 13pt)[Non-uniform spin coating; CMP pressure ring],
      text(fill: accent2, size: 13pt)[Edge-Ring], text(size: 13pt)[RTP thermal non-uniformity],
      text(fill: accent2, size: 13pt)[Scratch],  text(size: 13pt)[Robot end-effector; CMP over-polishing],
      text(fill: accent2, size: 13pt)[Near-full], text(size: 13pt)[Catastrophic process excursion],
    )
    #v(0.4em)
    #text(size: 13pt, fill: muted)[Updating for a new failure mode = *edit one dictionary*. No retraining required.]
  ],
)

#v(0.5em)
#card[
  #text(fill: accent2, weight: "bold")[Scope limit:] #h(4pt)
  #text(size: 14pt)[Mappings calibrated for standard bulk CMOS FEOL. Not applicable to III-V, MEMS, or advanced packaging without revision. All UI outputs labelled as *"pattern hypothesis"*, not "diagnosis".]
]

#slide-num(8)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 9 — Evaluation Setup                             ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Evaluation Setup]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: accent, weight: "bold")[Test set]
    #v(0.4em)
    #item[160 PNG images generated from WM-811K via `generate_images.py`]
    #item[*Balanced:* 20 images per class × 8 classes]
    #item[Single-class only (no multi-defect maps)]
    #v(0.5em)
    #text(fill: muted, size: 14pt)[Evaluation baseline: random chance on an 8-class balanced set = *12.5%*]
  ],

  card[
    #text(fill: accent, weight: "bold")[4 model variants tested]
    #v(0.4em)
    #item[*Best CNN* — direct classifier, no augmentation]
    #item[*Best CNN + Aug* — rotation + flip augmentation]
    #item[*Fullstack* — CNN with full preprocessing pipeline]
    #item[*Seg → CLF* — segmentation-then-classify pipeline]
    #v(0.4em)
    #text(size: 14pt, fill: muted)[`test.py` records: full softmax vector, top-3 labels, correctness flag → `evaluation_results.csv`]
  ],
)

#slide-num(9)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 10 — Accuracy Results                            ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Evaluation Results: Per-Class Accuracy]

#align(center)[
  #table(
    columns: (auto, auto, auto, auto, auto),
    inset: 8pt,
    align: (left, center, center, center, center),
    stroke: 0.4pt + muted,
    fill: (col, row) => {
      if row == 0 { surface }
      else if row == 9 { surface }
      else { rgb("#0f1923") }
    },

    text(fill: accent, weight: "bold")[Class],
    text(fill: accent, weight: "bold")[Best CNN],
    text(fill: accent, weight: "bold")[+ Aug],
    text(fill: accent, weight: "bold")[Fullstack],
    text(fill: accent, weight: "bold")[Seg→CLF],

    [Center],    text(fill: bad)[0%],  text(fill: bad)[0%],  [—], [—],
    [Donut],     text(fill: good)[65%], text(fill: bad)[10%], [—], [—],
    [Edge-Loc],  [30%],  text(fill: good)[85%], [—], [—],
    [Edge-Ring], text(fill: bad)[0%],  text(fill: bad)[0%],  [—], [—],
    [Loc],       text(fill: bad)[0%],  text(fill: bad)[0%],  [—], [—],
    [Near-full], [5%],   [15%],  [—], [—],
    [Random],    [5%],   text(fill: bad)[0%],   [—], [—],
    [Scratch],   text(fill: bad)[0%],  text(fill: bad)[0%],  [—], [—],

    text(weight: "bold")[Overall],
    text(fill: accent2, weight: "bold")[13.1%],
    text(fill: accent2, weight: "bold")[13.8%],
    text(fill: good, weight: "bold")[17.5%],
    [11.9%],
  )
]

#v(0.3em)
#text(size: 14pt, fill: muted)[All models cluster *near random chance (12.5%)* on the balanced test set. High training accuracy does not generalise to rare classes (Scratch: \<300 samples in full WM-811K).]

#slide-num(10)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 11 — Critical Failure Cases                      ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Critical Failure Cases]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: bad, weight: "bold")[Failure 1: Center / Near-full Confusion]
    #v(0.4em)
    #item[Best CNN assigns Near-full confidence *0.90–0.98* to Center inputs]
    #item[*18 out of 20* Center images predicted as Near-full]
    #v(0.4em)
    #hrule
    #text(fill: accent2, weight: "bold")[Operational consequence:]
    #v(0.2em)
    #text(size: 14pt)[
      Center → routine CVD calibration drift\
      Near-full → *catastrophic failure, immediate lot quarantine*\
      A top-1-only UI would trigger a drastic response for a routine issue *90% of the time.*
    ]
    #v(0.3em)
    #text(size: 13pt, fill: muted)[High confidence + wrong answer is *more dangerous* than low confidence + wrong answer — the warning threshold would not fire.]
  ],

  card[
    #text(fill: bad, weight: "bold")[Failure 2: Augmentation Destroys Donut]
    #v(0.4em)
    #item[Adding rotation/flip: Donut drops *65% → 10%*]
    #item[Edge-Loc jumps *30% → 85%* in the same run]
    #v(0.4em)
    #hrule
    #text(fill: muted, size: 14pt)[Rotation teaches the model a *partial ring is a valid Donut* — conflicting with the class definition.]
    #v(0.6em)
    #text(fill: bad, weight: "bold")[Failure 3: Seg → CLF Collapse]
    #v(0.3em)
    #text(size: 14pt)[Pipeline predicts "Center" confidence 1.0 for *>90% of all inputs* regardless of true class — classification head overfit to dominant training class, ignoring segmentation features.]
  ],
)

#slide-num(11)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 12 — Safeguards in the UI                        ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[How WaferDX Handles Model Uncertainty]

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 12pt,

  card[
    #align(center)[#text(size: 26pt)[📊]]
    #align(center)[#text(fill: accent, weight: "bold")[Full Distribution]]
    #v(0.4em)
    #text(size: 14pt)[Always shows *all 8 class probabilities* as a ranked bar chart — not just top-1 label + confidence]
    #v(0.3em)
    #text(size: 13pt, fill: muted)[Engineer sees: "Donut 57%, Edge-Loc 38%" and can judge calibration before acting]
  ],

  card[
    #align(center)[#text(size: 26pt)[🔥]]
    #align(center)[#text(fill: accent, weight: "bold")[Grad-CAM Heatmap]]
    #v(0.4em)
    #text(size: 14pt)[Overlaid on input image — engineer can verify whether the model is *attending to the actual defect region* or to wafer-edge artifacts]
    #v(0.3em)
    #text(size: 13pt, fill: muted)[Visual sanity check before initiating any tool inspection]
  ],

  card[
    #align(center)[#text(size: 26pt)[⚖️]]
    #align(center)[#text(fill: accent, weight: "bold")[Dual Hypothesis]]
    #v(0.4em)
    #text(size: 14pt)[Auto-triggered when *confidence gap < 0.15* — displays both process hypotheses side-by-side with confidence scores]
    #v(0.3em)
    #text(size: 13pt, fill: muted)["This map is ambiguous between Edge-Ring and Donut — here is what each implies for your process"]
  ],
)

#v(0.8em)
#card[
  #text(fill: muted, size: 14pt)[All RCA outputs are labelled as #text(fill: accent2, weight: "bold")["pattern hypothesis"] throughout the UI — not "diagnosis" or "root cause". *The engineer decides what to do next.*]
]

#slide-num(12)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 13 — Transferable Insights & Limitations         ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Transferable Insights & Governance Risks]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: good, weight: "bold")[Transferable design principles]
    #v(0.4em)
    #item[*Augmentation must respect class geometry* — applies to satellite imaging, histopathology, PCB inspection, any spatially structured classification]
    #item[*Calibration > accuracy for decision support* — high confidence + wrong answer is the most dangerous failure mode; temperature/isotonic scaling should be mandatory]
    #item[*Separate classification from domain reasoning* — RCA lookup table updated without model retraining; modularity scales to new failure modes]
  ],

  card[
    #text(fill: bad, weight: "bold")[Governance risks]
    #v(0.4em)
    #item[*Calibration failure* — Center/Near-full case shows the confidence-gap warning does not protect against overconfident wrong predictions; per-class calibration on held-out set required]
    #item[*Over-reliance on RCA* — knowledge-based mappings are heuristics, not verified causal chains; cross-check with tool logs mandatory before action]
    #item[*Scope drift* — mappings only valid for standard bulk CMOS FEOL; III-V, MEMS, advanced packaging require different tables]
  ],
)

#slide-num(13)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 14 — Future Work & Closing                       ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Future Extensions]

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 12pt,

  card[
    #badge("1 · Near-term")
    #v(0.4em)
    #text(fill: accent, weight: "bold")[Per-class calibration]
    #v(0.3em)
    #text(size: 14pt)[~500 samples/class calibration set from WM-811K + isotonic regression → fix Center/Near-full overconfidence so threshold warnings fire correctly]
  ],

  card[
    #badge("2 · Medium-term")
    #v(0.4em)
    #text(fill: accent, weight: "bold")[Multi-defect maps]
    #v(0.3em)
    #text(size: 14pt)[Synthetic multi-label maps via logical union of single-class samples → multi-label loss (binary cross-entropy per class) + per-class F1 evaluation]
  ],

  card[
    #badge("3 · Long-term")
    #v(0.4em)
    #text(fill: accent, weight: "bold")[Learned RCA]
    #v(0.3em)
    #text(size: 14pt)[Integrate proprietary fab process logs (tool IDs, chamber sensors, run timestamps) to partially replace heuristic mappings with empirically validated causal associations]
  ],
)

#v(1em)
#align(center)[
  #rect(
    width: 75%,
    inset: 14pt,
    radius: 6pt,
    fill: surface,
    stroke: 2pt + accent,
  )[
    #text(size: 16pt, weight: "bold", fill: accent)[Core Contribution]
    #v(0.4em)
    #text(size: 14pt)[
      WaferDX shows that explainable decision support requires *more than appending Grad-CAM to a CNN*. \
      Transparency about model limitations — full distributions, spatial attribution, explicit dual-hypothesis display — \
      is itself a design feature, not a fallback for low accuracy.
    ]
  ]
]

#v(0.6em)
#align(center)[#text(size: 14pt, fill: muted)[Thank you — questions welcome]]

#slide-num(14)