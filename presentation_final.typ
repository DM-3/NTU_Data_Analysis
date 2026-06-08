#set page(
  paper: "presentation-16-9",
  margin: (top: 0.9cm, bottom: 0.9cm, left: 1.2cm, right: 1.2cm),
  fill: rgb("#0f1923"),
)

#set text(
  font: "New Computer Modern",
  size: 16pt,
  fill: rgb("#e8edf2"),
  lang: "en",
)

#set par(leading: 0.68em)

#let total-slides = 20

// ── Colour palette ──────────────────────────────────────────
#let accent   = rgb("#38bdf8")
#let accent2  = rgb("#f97316")
#let muted    = rgb("#94a3b8")
#let surface  = rgb("#1e2d3d")
#let good     = rgb("#4ade80")
#let bad      = rgb("#f87171")

// ── Helper components ────────────────────────────────────────

// Full-width horizontal rule
#let hrule = {
  v(0.22em)
  line(length: 100%, stroke: 0.35pt + muted)
  v(0.22em)
}

// Slide title bar
#let slide-title(t) = {
  rect(
    width: 100%,
    inset: (x: 12pt, y: 7pt),
    radius: 5pt,
    fill: surface,
    stroke: (left: 3pt + accent),
  )[
    #text(size: 20pt, weight: "bold", fill: accent)[#t]
  ]
  v(0.45em)
}

// Coloured badge
#let badge(content, color: accent) = {
  box(
    inset: (x: 7pt, y: 2.5pt),
    radius: 4pt,
    fill: color.lighten(80%),
    stroke: 0.5pt + color,
  )[
    #text(size: 12pt, fill: color, weight: "bold")[#content]
  ]
}

// Card box
#let card(content, width: 100%) = {
  rect(
    width: width,
    inset: 10pt,
    radius: 5pt,
    fill: surface,
    stroke: 0.5pt + muted.lighten(20%),
  )[#content]
}

// Bullet item with accent dot
#let item(content) = {
  grid(
    columns: (9pt, 1fr),
    column-gutter: 5pt,
    text(fill: accent, size: 13pt)[▸],
    content,
  )
  v(0.16em)
}

// Page counter helper
#let slide-num(n, total: total-slides) = {
  align(right)[
    #text(size: 10pt, fill: muted)[#n / #total]
  ]
}
// Optional: left-align image figures globally on these slides
#show figure.where(kind: image): set align(start)

// Helper for a right-side description card
#let desc-card(title, body) = card[
  #text(fill: accent, weight: "bold", size: 16pt)[#title]
  #v(0.4em)
  #text(size: 14pt, fill: rgb("#e8edf2"))[#body]
]

// Helper for stacked figures on left + description on right
#let training-slide(title, img1, cap1, img2, cap2, text-title, text-body, n) = [
  #slide-title[#title]

  #grid(
    columns: (1.4fr, 1fr),
    column-gutter: 18pt,
    align: (left, top),

    [
      #figure(
        image(img1, width: 55%),
        caption: [#cap1],
      )
      #figure(
        image(img2, width: 80%),
        caption: [#cap2],
      )
    ],

    [
      #desc-card(
        text-title,
        text-body,
      )
    ],
  )

  #slide-num(n)
  #pagebreak()
]

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
    Explainable AI-Based Wafer Map \
    Defect Diagnosis and Decision Support System
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
// ║  SLIDE 3 — Application Context                          ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[The Problem: Wafer Defect Diagnosis]

#grid(
  columns: (1.1fr, 0.9fr),
  column-gutter: 18pt,

  [
    #item[Chips manufactured on thin circular silicon discs — *wafers* — with hundreds of chips etched side-by-side]
    #item[After probe test, every die result is stored as a pixel: *0 = background, 1 = pass, 2 = fail*]
    #item[The *spatial pattern* of failures — not the count — identifies the responsible process step]
    #v(0.6em)
    #hrule
    #v(0.4em)
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 8pt,
      card(width: 100%)[
        #text(fill: accent2, weight: "bold")[Ring around edge]
        #v(0.2em)
        #text(size: 14pt)[→ RTP thermal non-uniformity]
      ],
      card(width: 100%)[
        #text(fill: accent2, weight: "bold")[Linear streak]
        #v(0.2em)
        #text(size: 14pt)[→ Robot arm damage / CMP]
      ],
    )
  ],

  card[
    #text(fill: accent, weight: "bold", size: 16pt)[Why speed matters]
    #v(0.5em)
    #item[Modern fabs produce *thousands of wafers per day*]
    #item[Every undetected fault processes *more wafers* under failure conditions]
    #figure(
  image("icons\chip.jpg", width: 60%)
) <my_fig_label>
#v(0.5em)
    
  ],
)

#slide-num(3)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 4 — WM-811K Dataset & Defect Classes             ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[WM-811K Dataset: 8 Defect Classes]


#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  column-gutter: 10pt,
  row-gutter: 10pt,

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Center]]
    #figure(
  image("icons\center.png", width: 60%)
) <my_fig_label>

  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Donut]]
    #figure(
  image("icons\donut.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Edge-Loc]]
    #figure(
  image("icons\edge-loc.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Edge-Ring]]
    #figure(
  image("icons\edge-ring.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Loc]]
    #figure(
  image("icons\local.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Random]]
    #figure(
  image("icons\zufall.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Scratch]]
    #figure(
  image("icons\scratch.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Near-full]]
    #figure(
  image("icons\fast.png", width: 60%)
) <my_fig_label>
  ],
)

#slide-num(4)
#pagebreak()

// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 4 — WM-811K Dataset & Defect Classes             ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[WM-811K Dataset: 8 Defect Classes]


#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  column-gutter: 10pt,
  row-gutter: 10pt,

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Center]]
    #figure(
  image("icons\center.png", width: 60%)
) <my_fig_label>

  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Donut]]
    #figure(
  image("icons\donut.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Edge-Loc]]
    #figure(
  image("icons\edge-loc.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Edge-Ring]]
    #figure(
  image("icons\edge-ring.png", width: 60%)
) <my_fig_label>
  ],

  card[
    
    #v(0.3em)
    #text(size: 14pt)[Failure cluster at wafer centre → CVD deposition drift / spin-coat blockage]
  ],

  card[
    
    #v(0.3em)
    #text(size: 14pt)[Ring-shaped failure band → non-uniform spin coating / CMP pressure ring]
  ],

  card[
    
    #v(0.3em)
    #text(size: 14pt)[Localised arc of failures on edge → edge-bead removal issue]
  ],

  card[
    
    #v(0.3em)
    #text(size: 14pt)[Full ring of failures at wafer perimeter → RTP thermal non-uniformity]
  ],
)

#slide-num(4)
#pagebreak()

// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 4 — WM-811K Dataset & Defect Classes             ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[WM-811K Dataset: 8 Defect Classes]


#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  column-gutter: 10pt,
  row-gutter: 10pt,

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Loc]]
    #figure(
  image("icons\local.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Random]]
    #figure(
  image("icons\zufall.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Scratch]]
    #figure(
  image("icons\scratch.png", width: 60%)
) <my_fig_label>
  ],

  card[
    #align(center)[#text(fill: accent2, weight: "bold")[Near-full]]
    #figure(
  image("icons\fast.png", width: 60%)
) <my_fig_label>
  ],

    card[
    
    #v(0.3em)
    #text(size: 14pt)[Localised cluster anywhere on wafer → particle contamination]
  ],

  card[
    
    #v(0.3em)
    #text(size: 14pt)[Scattered failures with no spatial pattern → random contamination events]
  ],

  card[
    
    #v(0.3em)
    #text(size: 14pt)[Linear streak of failures → robot end-effector damage / CMP over-polishing]
  ],

  card[
    
    #v(0.3em)
    #text(size: 14pt)[Almost all dies failing → catastrophic process excursion]
  ],
)

#v(0.5em)
#card[
  #text(fill: muted, size: 14pt)[
    *Dataset sparsity:* 811,457 total maps · only 12,822 labelled defects (~1.6%) · *None* class = clean wafer · three-valued pixel encoding {0, 1, 2} specific to probe test output format
  ]
]

#slide-num(4)
#pagebreak()




// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 5 — Decision-Making Challenges                   ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Decision-Making Challenges Faced by Engineers]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: bad, weight: "bold")[Visual ambiguity]
    #v(0.4em)
    #item[*Edge-Loc* and *Edge-Ring* both cluster failures near the wafer perimeter - hard to tell apart]
    #item[Several defect types share visual features at *64×64 resolution* - difficult even for experts]
  ],

  card[
    #text(fill: bad, weight: "bold")[Co-occurring defects]
    #v(0.4em)
    #item[Contamination event → random scatter *and* process drift → edge failures *simultaneously*]
    #item[WM-811K provides *only single-defect labels* — real world is multi-defect]
  ],

  card[
    #text(fill: bad, weight: "bold")[Scale makes manual review impossible]
    #v(0.4em)
    #item[Modern fabs: *thousands of wafers per day*]
    #item[No bandwidth to hand-examine every map]
    #item[Existing tools return a category — *not* which spatial region drove it]
  ],

  card[
    #text(fill: bad, weight: "bold")[Existing tools: what but not where]
    #v(0.4em)
    #item[Single-label classifiers don't handle *co-occurring* defect types]
    #item[Grad-CAM only produces *one blended heatmap*, not per-class spatial breakdown]
    #item[All existing tools are *passive classifiers*]
  ],
)

#slide-num(5)
#pagebreak()

// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 7 — System Architecture Overview                 ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[System Architecture: Two-Stage Pipeline]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 18pt,

  [
    #card[
      #text(fill: accent, weight: "bold")[Stage 1 — Segmentation Model]
      #text(size: 12pt, fill: muted)[ (U-Net-inspired)] //· ~3.21 M parameters)]
          #figure(  image("plots\Unet.png", width: 75%)
) <my_fig_label>
      #item[Encoder: 4 conv blocks at filter depths *32, 64, 128, 256* + MaxPooling]
      //#item[Bottleneck: GlobalAveragePooling → two Dense layers → reshape + upsample]
      //#item[Skip connections let decoder recover spatial detail lost in bottleneck]
      //#item[Output: *8-channel map at 96×96 resolution* — one channel per defect class]
      #item[Acts as *spatial analyst*: translates raw wafer map into 8 spatial overlay maps]
    ]
    
  ],

  [
    #card[
      #text(fill: accent, weight: "bold")[Streamlit UI (app_best_wafer_cnn.py)]
      #v(0.4em)
      #item[Loads *best_wafer_cnn.keras* trained model]
      #item[*Upload mode*: engineer drags in a wafer map PNG/JPG/JPEG]
      #item[*Draw mode*: freehand canvas sketch for hypothesis testing]
      #item[Results: *3×3 grid of confidence cards* — defect name + percentage + colour-coded bar]
      #v(0.3em)
      #text(size: 13pt)[Cyan/blue: confidence above 70% · Grey: below 30% · Gradient in between]
    ]
      ],
)

#slide-num(7)
#pagebreak()

#slide-title[System Architecture: Two-Stage Pipeline]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 18pt,
[
  #card[
      #text(fill: accent, weight: "bold")[Stage 2 — Classification Model]
      #text(size: 12pt, fill: muted)[ (CNN)]
       #figure(  image("icons/cnn.png", width: 70%)
) <my_fig_label>
      #item[Input: segmentation output; 4 conv blocks each]
      #item[SpatialAttention: avg + max pool across channels → 7×7 conv → soft mask]
      #item[GlobalAveragePooling → 2 × Dense(512) + BatchNorm + Dropout]
      
    ]
],[



#card[
      #text(fill: accent2, weight: "bold")[Total Parameters: 5.68 M]
      #v(0.4em)
      #text(size: 14pt)[Segmentation: 3.21 M + Classification: 2.11 M]
      #v(0.4em)
      #text(fill: muted, size: 13pt)[Comparison baseline: *app_direct_classifier_cnn.py* — same UI experience wired to direct CNN classifier (simpler, no segmentation stage)]
    ]
    #v(0.5em)
    #card[
      #text(fill: accent, weight: "bold")[System Boundaries]
      #v(0.3em)
      #text(size: 13pt)[Works with: 2D PNG/JPEG wafer maps + freehand drawings]
      #v(0.2em)
      #text(size: 13pt)[Does NOT: write to databases, trigger alarms, flag wafers for scrap]
      #v(0.2em)
      #text(fill: accent2, size: 13pt, weight: "bold")[Role is entirely advisory — engineer decides]
      #item[Output: *8 sigmoid probabilities*]
    ]]
)

#slide-num(7)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 8 — Usage Workflow                               ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Usage Workflow: 4-Step Pipeline]

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

  #step("1", "Input", "Upload PNG/JPG/JPEG wafer map OR draw a freehand pattern on interactive canvas")
  #arrow
  #step("2", "Preprocess", "Convert to grayscale → normalise pixel values to {0, 1, 2} by rounding pixel/127.5 → resize to 64×64 with padding to preserve aspect ratio")
  #arrow
  #step("3", "Inference", "Image → Segmentation model → 8 spatial activation maps at 96×96 → Classification model → 8 sigmoid confidence scores")
  #arrow
  #rect(
    width: 88%,
    inset: (x: 14pt, y: 7pt),
    radius: 4pt,
    fill: accent.lighten(85%),
    stroke: (left: 3pt + good),
  )[
    #grid(
      columns: (28pt, 1fr),
      column-gutter: 8pt,
      align(center)[#badge("4", color: good)],
      [
        #text(weight: "bold", fill: good)[Display Results]
        #h(6pt)
        #text(size: 14pt, fill: muted)[Confidence cards in 3×3 grid · Bars cyan/blue above 70%, grey below 30%, gradient in between · Engineer inspects per-class activation maps · Engineer decides what to do]
      ],
    )
  ]
]

#slide-num(8)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 9 — Design Decision 1                            ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Design Decision 1: Two-Stage vs. Direct End-to-End Classification]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: good, weight: "bold")[Two-Stage (chosen)]
    #v(0.4em)
    #item[Segmentation output = *interpretable intermediate representation*]
    #item[When Edge-Ring activation lights up around wafer periphery, you can *see why* the model calls it Edge-Ring]
    #item[Multi-label capability baked into data design, not architectural add-on]
    //*Best when:* spatial interpretability matters — which for process fault diagnosis, it almost always does]
  ],

  card[
    #text(fill: accent2, weight: "bold")[Direct End-to-End]
    #v(0.4em)
    #item[Simpler to train and deploy]
    #item[Single end-to-end optimisation problem]
    #item[*Whenever it got something wrong*, it was genuinely hard to understand why]
    #item[Grad-CAM patches this partially — rough single blended heatmap, not per-class breakdown]

    //#text(fill: muted, size: 13pt)[*Best when:* fast binary answer needed and spatial explanation doesn't matter]
  ],
)

#v(0.5em)
#card[
  #text(fill: accent2, weight: "bold")[Trade-off:] #h(4pt)
  #text(size: 14pt)[Two-stage requires more upfront work — segmentation must stabilise before classifier pre-training starts. Pipeline is more complex to debug when both components are unfrozen during fine-tuning. Managed with *ModelCheckpoint* + *EarlyStopping* (patience 10–15 per phase).]
]

#slide-num(9)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 10 — Design Decisions 2 & 3                     ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Design Decisions 2 & 3: Spatial Attention + Synthetic Multi-Defect Data]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: accent, weight: "bold")[Spatial Attention in Every Conv Block]
    
    #text(size: 14pt, weight: "bold", fill: muted)[Why:]
    #item[Scratch defect may cover *less than 5%* of the image — treating all locations equally wastes capacity]
    #item[CBAM-inspired: pool features across channels → 7×7 conv → soft spatial mask → multiply back onto feature maps]
    #v(0.3em)
    #text(size: 14pt, weight: "bold", fill: muted)[Alternative considered:]
    #item[Channel attention (SE-Net) — focuses on *which feature channels* matter, not *where*; wrong emphasis for a geometry-defined task. ]
    //#text(fill: muted, size: 13pt)[*Best when:* defects are small and localised. Less critical for Near-full (covers most of wafer) but doesn't hurt.]
  ],

  card[
    #text(fill: accent, weight: "bold")[Synthetic Multi-Defect Sample Generation]

    #text(size: 14pt, weight: "bold", fill: muted)[Why:]
    #item[WM-811K *only has single-defect labels*. Real wafers can have co-occurring defects from simultaneous process problems.]
    #item[Method: element-wise *maximum blending*]
    #item[No additional human annotation required]
    #v(0.3em)
    #text(size: 14pt, weight: "bold", fill: muted)[Trade-off:]
    #item[Element-wise max is a simplification]
    #item[Hardest cases: *Donut + Near-full* (both cluster at wafer edge → merged activation blobs)]
    //#text(fill: muted, size: 13pt)[Works best when defect patterns are spatially non-overlapping]
  ],
)

#slide-num(10)
#pagebreak()





#training-slide(
  [Model Training],
  "plots/classification_pretrain_loss_curve.png",
  [Classifier pretraining loss / AUC curve],
  "plots/segmentation_sample_init.png",
  [Initial segmentation output before effective training],
  [Phase 1–2 interpretation],
  [
    Placeholder text: Describe what the audience should notice here.
    For example, explain whether the classifier stabilizes quickly, whether validation follows training closely,
    and how the untrained segmentation output still looks noisy or structurally weak.
    This box can later be replaced by 3–4 short bullet-style observations.
  ],
  11,
)

#training-slide(
  [Model Training],
  "plots/segmentation_loss_curve.png",
  [Segmentation training loss curve],
  "plots/segmentation_sample.png",
  [Segmentation output after training],
  [Segmentation learning outcome],
  [
    Placeholder text: Explain how the loss evolves over epochs and what visual improvement appears in the trained segmentation map.
    Mention whether class regions become sharper, whether irrelevant channels are suppressed,
    and why this matters for explainability in the next classifier stage.
  ],
  11,
)

#training-slide(
  [Model Training],
  "plots/fullstack_loss_curve.png",
  [End-to-end fine-tuning curve],
  "plots/segmentation_sample_100epochs.png",
  [Segmentation sample after extended training],
  [Full-stack fine-tuning],
  [
    Placeholder text: Summarize what changes after joint optimization.
    You can describe whether validation becomes more volatile, whether performance improves despite instability,
    and how the final spatial maps support the claim that the model is explainable by design.
  ],
  11,
)






#slide-title[Design Decision 4: Three-Phase Training Curriculum]

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 12pt,

  card[
    #text(fill: accent, weight: "bold")[1. Train Segmentation Model Alone]
    #v(0.1em)
    #item[100 epochs, 64 steps/epoch, batch size 16]
    #item[Loss: 0.140 → *≈ 0.017*]
    #item[Sharp drop first 5 epochs → slow decline]
    #item[Smooth convergence]
  ],

  card[
    #text(fill: accent, weight: "bold")[2. Freeze Seg, Pre-Train Classifier Head]
    #v(0.1em)
    #item[~32 epochs - segmentation frozen]
    #item[AUC: 0.65 → 0.86]
    #item[Loss: 0.82 → ~0.30]
    #item[Refined 20-epoch run: train AUC 0.93, *val AUC 0.94* at best epoch 19]
  ],

  card[
    #text(fill: accent, weight: "bold")[3. End-to-End Fine-Tuning]
    #v(0.1em)
    #item[50 epochs · batch size 64 · both models unfrozen]
    #item[Train AUC: 0.91 → ~0.95]
    #item[*Val AUC peaks above 0.96* · best epoch 40]
    #item[Train loss: 0.27 → ~0.20]
    #item[Validation more volatile]
  ],
)

#card[
  #text(fill: accent2, weight: "bold")[Why curriculum training?] #h(4pt)
  #text(size: 14pt)[End-to-end from scratch: classifier received random-noise segmentation outputs → erratic gradient flow. Training each stage to convergence before connecting reduces gradient interference. Broadly applicable pattern for any multi-stage deep learning pipeline.]
]

#slide-num(11)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 12 — AI Role & System Autonomy                  ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[AI Role and System Autonomy]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: accent, weight: "bold")[The AI's Two Roles]
    #v(0.2em)
    #text(size: 14pt, weight: "bold")[Segmentation model = Analyst]
    #item[From raw wafer map → 8 spatial overlay maps]
    #item[Translates greyscale image into *where each defect type appears*]
    #v(0.2em)
    #text(size: 14pt, weight: "bold")[Classification model = Interpreter]
    #item[Reads spatial maps → outputs *calibrated probabilities* per class]
    #item[Converts spatial evidence into 8 sigmoid confidence scores]
    #v(0.2em)
  ],

  card[
    #text(fill: accent, weight: "bold")[Level of Automation]
    #v(0.4em)
    #item[Preprocessing, segmentation, classification: fully automatic]
    #v(0.4em)
    #text(fill: bad, weight: "bold", size: 14pt)[System does NOT:]
    #item[Flag a wafer for scrap]
    #item[Raise a process alarm]
    #item[Notify a supervisor]
    #item[Update any external database]
    #v(0.3em)
    #text(fill: good, size: 13pt)[*Draw mode* turns the system into an active exploration tool]
  ],
)

#slide-num(12)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 13 — Evaluation Setup                           ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Evaluation Setup and Results: Training Phases]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: accent, weight: "bold")[Evaluation Goals]
    
    #item[Did segmentation model learn to *localise defect regions* (or just produce plausible noise)?]
    #item[Did classification model reach a *practically useful AUC*?]
    #item[Does two-stage pipeline produce *better/more interpretable* results than direct classifier?]
    #v(0.4em)
  ],

  card[
    #text(fill: accent, weight: "bold")[Phase 2 Extended — 50 Epochs]
    
    #item[Training AUC: 0.91 → 0.96 by epoch 50]
    #item[Validation AUC: volatile 0.92–*0.98*, best at epoch 47 (ModelCheckpoint saved)]
    #item[Volatility: segmentation backbone gets gradient updates → feature space shifting under classifier]
    #item[Train loss: 0.27 → ~0.175, Val loss minimum ~0.15]
  ],
)

#v(0.5em)
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 12pt,

  card[
    #text(fill: accent, weight: "bold", size: 14pt)[Seg. Model Convergence]
    #v(0.3em)
    #text(size: 14pt)[MSE loss 0.140 → *0.017* over 100 epochs]
    #v(0.2em)
    //#text(size: 13pt, fill: muted)[After training: Center activates centre; Edge-Ring shows circular ring; Scratch traces linear streak; irrelevant channels stay near zero]
  ],

  card[
    #text(fill: accent, weight: "bold", size: 14pt)[Phase 2 Best Checkpoint]
    #v(0.3em)
    #text(size: 14pt)[Val AUC *0.94* at epoch 19/20]
    #v(0.2em)
    //#text(size: 13pt, fill: muted)[Training and validation loss both converge near 0.23 with no meaningful gap — no overfitting]
  ],

  card[
    #text(fill: accent, weight: "bold", size: 14pt)[Phase 3 Best Checkpoint]
    #v(0.3em)
    #text(size: 14pt)[Val AUC *above 0.96*, best epoch 40/50]
    #v(0.2em)
    //#text(size: 13pt, fill: muted)[Fullstack fine-tuning (10 epochs): AUC 0.61 → 0.70; Loss 0.60 → 0.45 with brief plateau at epoch 6]
  ],
)

#slide-num(13)
#pagebreak()



// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 15 — Model Comparison Results                   ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Model Comparison: 4 Architectures on 160 Test Images]

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
    text(fill: accent, weight: "bold")[Best CNN\n(no aug)],
    text(fill: accent, weight: "bold")[Best CNN\n(+ aug)],
    text(fill: accent, weight: "bold")[Fullstack],
    text(fill: accent, weight: "bold")[Seg → CLF],

    [Center],    text(fill: bad)[0%],  text(fill: bad)[0%],  text(fill: bad)[0%], text(fill: good)[95%],
    [Donut],     text(fill: good)[65%], text(fill: bad)[10%], text(fill: bad)[0%], text(fill: bad)[0%],
    [Edge-Loc],  [30%],  text(fill: good)[85%], [—], text(fill: bad)[0%],
    [Edge-Ring], text(fill: bad)[0%],  text(fill: bad)[0%],  text(fill: bad)[0%], text(fill: bad)[0%],
    [Loc],       text(fill: bad)[0%],  text(fill: bad)[0%],  text(fill: bad)[0%], text(fill: bad)[0%],
    [Near-full], [5%],   [15%],  text(fill: good)[100%], text(fill: bad)[0%],
    [Random],    [5%],   text(fill: bad)[0%],   [35%], text(fill: bad)[0%],
    [Scratch],   text(fill: bad)[0%],  text(fill: bad)[0%],  text(fill: bad)[0%], text(fill: bad)[0%],

    text(weight: "bold")[Overall],
    text(fill: accent2, weight: "bold")[13.1%],
    text(fill: accent2, weight: "bold")[13.8%],
    text(fill: good, weight: "bold")[17.5%],
    [11.9%],
  )
]

#v(0.3em)
#text(size: 13pt, fill: muted)[*Random chance on 8-class balanced test = 12.5%.* All models near random on most classes. Test images: 20 samples per class × 8 classes = 160 PNG images from WM-811K via generate_images.py (fixed seed, {0,1,2} → {0,128,255} pixel scaling for visualisation only).]

#slide-num(15)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 16 — Failure Cases                              ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Critical Failure Cases and Unexpected Outcomes]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: bad, weight: "bold")[Per-class accuracy collapse (all models)]
    #item[Every architecture collapses to high accuracy on 1–2 dominant classes while failing on the rest]
    #item[Sign of class imbalance + class-specific shortcuts rather than general spatial representations]
    #item[No single architecture achieved balanced performance across all 8 classes]
  ],

  card[
    #text(fill: bad, weight: "bold")[Spatial ambiguity on overlapping synthetic defects]
    #item[Donut + Near-full: both cluster near wafer edge → segmentation model produced *merged activation blobs*]
    #item[Recognised that something was happening at the edge, but not *which* specific pattern]
    #item[Known limitation — would require real labelled multi-defect data to address properly]
  ]
)

#slide-num(16)
#pagebreak()

#slide-title[Critical Failure Cases and Unexpected Outcomes]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: bad, weight: "bold")[Draw mode distribution shift]
    #item[Drawn strokes are *sharper and higher-contrast* than real wafer map greyscale gradients]
    #item[Direct classifier sometimes less confident on drawn inputs than uploaded ones]
    #item[Creates distribution mismatch between draw mode and training data]
  ],

  card[
    #text(fill: bad, weight: "bold")[Early Phase 3 instability + sparse labels]
    #item[Validation loss spiked in first 2–3 fine-tuning epochs before settling — differential learning rates not implemented (time constraint)]
    #item[Only ~12,800 of 811,000 maps labelled — thin supervision signal likely causing gaps for rare morphologies]
    #item[Seg → CLF pipeline: classifier overfit to "Center" class (confidence 1.0 for over 90% of all inputs regardless of true class)]
  ],
)

#slide-num(17)
#pagebreak()
// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 17 — What Evaluation Cannot Tell Us             ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[What the Evaluation Cannot Tell Us]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,

  card[
    #text(fill: accent2, weight: "bold")[Multi-label evaluation is entirely qualitative]
    #v(0.4em)
    #item[No held-out test set with genuine multi-label ground truth — WM-811K *does not provide one*]
    #item[Multi-defect evaluation = looking at outputs and judging if they "looked right"]
    #item[Useful but not rigorous]
    
    //#text(fill: muted, size: 13pt)[Proper evaluation against real multi-defect wafer maps labelled by process engineers = *next necessary step before production use*]
  ],

  card[
    #text(fill: accent2, weight: "bold")[No real-world fab validation]
    #v(0.4em)
    #item[WM-811K comes from one fab environment with its own process conditions, tool fleet, wafer sizes]
    #item[Model may not generalise to a different fab without recalibration]
    #item[Production deployment requires *periodic retraining* on locally collected labelled data]
    
    //#text(fill: muted, size: 13pt)[Synthetic multi-defect training data *not validated* against real co-occurring defects — multi-label behaviour is promising but unconfirmed]
  ],
)

#v(0.5em)
#card[
  #text(fill: accent, weight: "bold")[Deployment risk: automation complacency] #v(0.2em)
  #text(size: 14pt)[When system shows 94% confidence for Edge-Ring, real risk that engineer accepts it *without checking spatial maps* — opposite of intended behaviour. Interface shows all 8 class probabilities simultaneously to make uncertainty visible and encourage critical engagement.]
]

#slide-num(17)
#pagebreak()




// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 19 — Future Extensions                          ║
// ╚══════════════════════════════════════════════════════════╝
#slide-title[Future Extensions]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 16pt,
  row-gutter: 10pt,

  card[
    #text(fill: accent, weight: "bold")[Higher Resolution Inputs]
    #v(0.3em)
    #item[Move from 64×64 to *128×128 or 256×256*]
    #item[Especially important for *Scratch* defects — often only a few pixels wide at current resolution]
    #item[Better spatial detail: Edge-Loc vs. Edge-Ring]
  ],

  card[
    #text(fill: accent, weight: "bold")[Calibrated Uncertainty]
    #v(0.3em)
    #item[Add *Monte Carlo Dropout* or *conformal prediction*]
    #item[Give system a principled way to say "I am not sure about this one"]
  ],

  card[
    #text(fill: accent, weight: "bold")[Real Multi-Label Annotations]
    #v(0.3em)
    #item[*Most important single improvement*: multi-defect wafer maps labelled by process engineers]
    #item[Enable rigorous multi-class F1 evaluation]
  ],

  card[
    #text(fill: accent, weight: "bold")[Integration with Fab Systems]
    #v(0.3em)
    #item[Connect to *manufacturing execution system*]
    #item[Raise *SPC alerts* directly when high-confidence defect calls are made]
    #item[Cenncts diagnosis and process control]
  ],
)


#slide-num(19)
#pagebreak()


// ╔══════════════════════════════════════════════════════════╗
// ║  SLIDE 20 — Conclusion                                  ║
// ╚══════════════════════════════════════════════════════════╝
#align(center + horizon)[
  #text(size: 22pt, weight: "bold", fill: accent)[Conclusion]
  #hrule

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,

    card[
      #v(0.3em)
      #text(size: 14pt)[5.68 M parameters, Two-stage U-Net + CNN + Spatial Attention, Streamlit UI with Upload + Draw modes]
    ],

    card[
      #v(0.3em)
      #text(size: 14pt)[MSE loss ≈ 0.017 · Val AUC peaks *0.98* at epoch 47 · Fullstack: 17.5% test accuracy (best of 4)]
    ],
  )

  #rect(
    width: 80%,
    inset: 12pt,
    radius: 6pt,
    fill: surface,
    stroke: 2pt + accent,
  )[
    #text(size: 15pt)[
      We wanted a tool telling engineers not just *what* is wrong with a wafer, but *where*\
      The system is designed to support critical engagement, not discourage it.
    ]
  ]

#text(size: 22pt, weight: "bold", fill: accent)[Work Distribution]
#grid(
  columns: (1fr, 1fr),
  column-gutter: 8pt,
  row-gutter: 12pt,

  card[
    #text(fill: accent, weight: "bold")[David Spickenheuer]
        #v(0.01em)
    #text(size: 14pt)[Classification model design, training, and evaluation.]
  ],

  card[
    #text(fill: accent, weight: "bold")[Martin Werner]
    #v(0.01em)
    #text(size: 14pt)[Segmentation model development.]
  ],

  card[
    #text(fill: accent, weight: "bold")[Abhirup Sain]
    #v(0.01em)
    #text(size: 14pt)[Data preprocessing, input pipeline preparation.]
  ],

  card[
    #text(fill: accent, weight: "bold")[Staniya Thomas, Matti Lehmann]
    #v(0.01em)
    #text(size: 14pt)[Streamlit UI design, user-facing integration.]
  ],
)
]

#slide-num(20)