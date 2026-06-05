// ============================================================
// WaferDX — Final Project Report
// NTU Data Analysis and Machine Learning with Python
// ============================================================

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  numbering: "1",
)
#set text(
  font: "New Computer Modern",
  size: 11pt,
  lang: "en",
  hyphenate: true,
)
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "I.")

// ── Title Block ──────────────────────────────────────────────
#align(center)[
  #v(1.5em)
  #text(size: 16pt, weight: "bold")[
    WaferDX: An Explainable AI Decision Support System \
    for Semiconductor Wafer Defect Diagnosis \
    and Process Root Cause Analysis
  ]
  #v(1em)
  #text(size: 11pt)[
    Abhirup Sain (T14H06318) ·
    David Spickenheuer (T14H06329) ·
    Martin Werner (T14H06319) ·
    Matti Lehmann (T14H06309) ·
    Staniya Thomas (T14H06310)
  ]
  #v(0.4em)
  #text(size: 10pt, style: "italic")[
    National Taiwan University — Data Analysis and Machine Learning with Python, Spring 2026
  ]
  #v(2em)
  #line(length: 100%, stroke: 0.5pt)
  #v(1em)
]

// ── Abstract ─────────────────────────────────────────────────
#align(center)[#text(weight: "bold")[Abstract]]
#v(0.5em)

#text(style: "italic")[
In semiconductor manufacturing, a silicon wafer passes through 400–600 process steps before
electrical testing produces a spatial map of passing and failing dies. The pattern of those
failures encodes the identity of the process tool that caused them: a center-cluster pattern
implicates CVD deposition drift; a linear scratch track points to robotic handling damage.
Manually interpreting these maps is both error-prone and a bottleneck in yield recovery. Existing
automated systems either flag anomalies without classifying them, or classify without explaining
which spatial region drove the decision — leaving engineers no better informed about root cause.

WaferDX is an explainable AI decision support system that accepts a wafer map image, classifies
it against eight defect pattern types from the WM-811K dataset (811,457 maps, 46,393 lots), and
pairs each prediction with a Grad-CAM spatial attribution heatmap and a knowledge-based root
cause hypothesis. The system is implemented in Python using TensorFlow/Keras for the CNN
backbone and Streamlit for the interactive interface, allowing engineers to upload a wafer image
or draw one directly on a canvas.

Three design trade-offs shaped the final architecture. First, a direct CNN classifier (96×96
input) was retained over a segmentation-then-classify pipeline after comparative evaluation
showed the pipeline collapsing to a single dominant class prediction on the 160-sample balanced
test set, achieving only 11.9% accuracy. Second, data augmentation via rotation and flipping was
evaluated as a separate model variant; it improved Edge-Loc accuracy from 30% to 85% but
destroyed Donut accuracy, dropping it from 65% to 10%, because rotation augmentation removes
the orientation cues that distinguish radially symmetric defect types. Third, a knowledge-based
root cause mapping was used instead of a learned one, since no public dataset links WM-811K
labels to confirmed fab process failures.

Evaluation tested four model variants on 160 generated wafer images — 20 per class across
Center, Donut, Edge-Loc, Edge-Ring, Loc, Near-full, Random, and Scratch. The Fullstack model
achieved the highest overall accuracy at 17.5%, while the Best CNN reached 13.1% and the
augmented variant 13.8%. Per-class results reveal severe calibration failures: the Best CNN
scores 65% on Donut but 0% on Center, Edge-Ring, Loc, and Scratch. These numbers drove the
system's core advisory design: all outputs display the full probability distribution across all
eight classes, the Grad-CAM heatmap for visual verification, and an explicit multi-hypothesis
panel when the confidence gap between top-1 and top-2 falls below 0.15.
]

#v(1em)
#line(length: 100%, stroke: 0.5pt)
#v(1.5em)

// ── Section I ────────────────────────────────────────────────
= Application Context and Decision Problem

== System Application Scenario

In a 300mm semiconductor fab, a single production lot contains 25 wafers. After front-end
electrical testing, each wafer produces a binary die map: pass (1) or fail (2) at every die
location on the circular substrate. The spatial distribution of failures — not their total count
— is what matters for process diagnosis. A "Center" pattern (a dense cluster of failing dies in
the wafer center) implicates CVD deposition rate non-uniformity at the center of the reactor
chamber. A "Scratch" pattern (a linear diagonal track of failing dies) points to mechanical
contact during wafer handling between process steps, most commonly at the robot arm end-effector
or inside a wafer boat. Identifying the correct pattern quickly and correctly determines how fast
a yield engineer can isolate the faulty tool and prevent additional wafers from being processed
under the same failure condition.

== Decision-Making Challenges

Engineers face three compounding difficulties. First, several defect patterns are visually
ambiguous: Donut (a hollow annular ring of failures) and Edge-Ring (a continuous ring of failures
concentrated at the wafer perimeter) both produce annular distributions but implicate different
process steps — CMP pressure ring effect versus RTP thermal non-uniformity, respectively. Second,
real production wafers can exhibit multiple overlapping defect patterns simultaneously, a scenario
the WM-811K dataset labels as single-class but which engineers encounter routinely. Third, when a
classification system outputs only a label without a spatial explanation of where it found the
evidence, engineers have no way to verify whether the result is trustworthy or driven by image
artifacts at the wafer edge.

== Limitations of Existing Approaches

Current fab-floor inspection tools fall into two categories. Automated Optical Inspection (AOI)
systems like KLA's Klarity detect individual die failures and flag their locations, but do not
classify the aggregate spatial pattern and provide no process hypothesis. Academic models trained
on WM-811K — such as the ResNet-50 ensemble reported by Shim et al. (2020) achieving 98.7% on
the standard test split — optimize for benchmark accuracy on a class-balanced subset that does
not reflect production class distributions, where fewer than 300 Scratch samples exist in the
full 811K labeled set. Neither type of system provides the spatial explanation that would let an
engineer validate a classification decision before acting on it.

== What WaferDX Supports

WaferDX supports one primary decision: _which process tool or step is most likely responsible
for the observed die failure pattern on this wafer?_ The system does not make this call
automatically. It outputs a ranked probability distribution over all eight defect classes, a
Grad-CAM heatmap showing which spatial regions of the wafer most influenced the top prediction,
a root cause mapping from defect class to process step, and — when the confidence gap between
the top-1 and top-2 predictions is less than 0.15 — an explicit dual-hypothesis display that
tells the engineer "this map is ambiguous between Edge-Ring and Donut; here is what each
implies for your process." The engineer decides what to do next.

// ── Section II ───────────────────────────────────────────────
= Related Design Approaches

== Single-Label End-to-End CNN Classifiers

The dominant published approach trains a convolutional neural network end-to-end on WM-811K
with a softmax output layer across nine classes (eight defect types plus "None"). Published
accuracy numbers are high: Wu et al. (2015) achieved 92.4% using a combined hand-crafted feature
and k-nearest-neighbor approach, and Shim et al. (2020) reported 98.7% using an ensemble of
three CNNs on the standard test split. The critical limitation is not the model architecture but
the evaluation setup. The standard WM-811K split samples proportionally from the original
distribution, in which 47.8% of all labeled wafers belong to the "None" class and "Scratch"
accounts for only 1.1% of labeled samples. A model that predicts "None" for every ambiguous
input can appear highly accurate while providing zero utility to an engineer who needs to
distinguish between Scratch and Edge-Loc. None of these published systems generate spatial
explanations or confidence-aware multi-hypothesis outputs.

== Segmentation-Then-Classify Pipelines

A more interpretable design separates detection from classification: a segmentation network first
produces per-pixel activation maps for each defect class, and a second classifier operates on
those maps rather than on the raw wafer image. The appeal is that the intermediate segmentation
output is inherently spatial and interpretable — engineers can see which pixel regions activate
for each class hypothesis. This architecture (labeled "Seg → CLF" in our evaluation) was
implemented and evaluated alongside the direct CNN. The practical result was 11.9% overall
accuracy on the 160-sample balanced test set, compared to 13.1% for the direct CNN without
augmentation. More diagnostically, the Seg → CLF pipeline predicted "Center" with confidence 1.0
for over 90% of all inputs regardless of true class, indicating that the classification head
overfit to the dominant class in its training distribution rather than learning from the
segmentation activation features.

== Where WaferDX Differs

WaferDX does not treat accuracy as the only criterion for system usefulness. A model that
achieves 65% on Donut but 0% on Center, Edge-Ring, Loc, and Scratch is not appropriate for
single-hypothesis output — and the system makes this explicit. Rather than presenting a single
classification label, the UI always shows the full 8-class probability distribution and flags
outputs where model behavior is known to be unreliable. The Grad-CAM spatial attribution layer
provides the visual explanation that benchmark-focused systems omit entirely, allowing engineers
to sanity-check whether the model is attending to the actual defect region or to irrelevant
image structure at the wafer boundary.

// ── Section III ──────────────────────────────────────────────
= Artifact Overview

== Overall System Functions

WaferDX performs four distinct functions:

+ *Input handling* — accepts a wafer map as either an uploaded PNG file or as a user-drawn image on an interactive canvas widget (`streamlit-drawable-canvas`), supporting both raw fab export images and synthetic defect sketches for testing.

+ *Classification* — runs the trained CNN (TensorFlow/Keras, 96×96 input, trained on a WM-811K subset) and produces a softmax probability vector across 8 defect classes. Both the Best CNN and the augmented variant are available in the codebase.

+ *Spatial explainability* — computes a Grad-CAM heatmap from the final convolutional layer by computing the gradient of the top predicted class score with respect to layer activations, globally average-pooling to obtain per-channel weights, and linearly combining the resulting activation maps. The heatmap is upsampled to 96×96 and overlaid on the input image as a red-to-blue color map.

+ *Root Cause Advisory* — maps the top predicted defect class to a process-level hypothesis using a hand-curated knowledge base. Output includes the likely process step, the implicated tool type, and a concrete recommended inspection action (e.g., for a Scratch prediction: _"Inspect robot arm end-effector and CMP pad condition"_).

== System Boundaries

WaferDX processes single wafer map images. It does not connect to fab MES systems, lot history
databases, or real-time tool sensor feeds. Input images are not stored between sessions. The
system does not model lot-to-lot or wafer-to-wafer trends, does not account for grade curves or
inspection tool calibration state, and does not produce scrap or rework recommendations. The root
cause mappings are knowledge-based heuristics from standard CMOS process engineering literature —
they are advisory hypotheses, not confirmed diagnoses. Multi-defect wafer maps (two or more
overlapping defect patterns) are a known out-of-scope case; the system outputs the single
most-probable class rather than a multi-label prediction.

== Usage Workflow

#figure(
  align(center)[
    #rect(
      width: 88%,
      inset: 12pt,
      radius: 4pt,
      stroke: 0.6pt,
    )[
      #set text(size: 9.5pt)
      #grid(
        columns: 1,
        row-gutter: 6pt,
        align(center)[*[1] User uploads PNG or draws wafer on canvas*],
        align(center)[↓],
        align(center)[*[2] Preprocessing pipeline*\ grayscale → zero-pad to square → nearest-neighbor resize to 96×96\ normalize: `round(arr / 127.5) / 2.0` → values ∈ {0.0, 0.5, 1.0}],
        align(center)[↓],
        align(center)[*[3] CNN forward pass* → softmax over 8 defect classes],
        align(center)[↓],
        align(center)[*[4] Grad-CAM* — gradient of top class score w.r.t. final conv layer activations\ → weighted activation sum → upsample to 96×96 → overlay heatmap],
        align(center)[↓],
        align(center)[*[5] Display* — ranked probability bars + heatmap overlay on input image],
        align(center)[↓],
        align(center)[*[6] RCA lookup* — defect class → process hypothesis + recommended action],
        align(center)[↓],
        align(center)[*[7] Multi-hypothesis view* if top-1 confidence gap < 0.15 or confidence < 0.5],
        align(center)[↓],
        align(center)[*[8] Engineer interprets and decides*],
      )
    ]
  ],
  caption: [WaferDX processing pipeline from wafer map input to root cause advisory output. Steps 1–7 are fully automated; step 8 is human-only.],
) <fig:pipeline>

The preprocessing step deserves attention. WM-811K wafer maps span 632 distinct spatial formats,
ranging from 25×25 to 300×300 pixels with varying aspect ratios. Simple bilinear rescaling
averages neighboring pixels and corrupts the discrete 3-value integer encoding (0 = background,
1 = passing die, 2 = failing die). WaferDX applies nearest-neighbor resampling after zero-padding
to a square aspect ratio, preserving the integer encoding throughout. Input size of 96×96 was
chosen above the dataset's average map size to retain spatial detail on larger wafers without
making the network unnecessarily deep.

// ── Section IV ───────────────────────────────────────────────
= Design Decisions and Trade-offs

== Decision 1: Direct CNN vs. Segmentation-Then-Classify Pipeline

The segmentation-then-classify (Seg → CLF) architecture was the theoretically preferred design
at the project's outset. A segmentation network producing per-pixel activation maps for each
class would make the model's spatial reasoning directly visible, eliminating the need for
post-hoc attribution methods like Grad-CAM. In practice, the Seg → CLF pipeline achieved 11.9%
overall accuracy on the 160-sample balanced test set — lower than the direct CNN at 13.1% and
substantially below the Fullstack model at 17.5%. The failure mode was qualitative: inspection
of the evaluation CSV showed the classification head predicting "Center" with confidence 1.0 for
the majority of inputs including Scratch, Random, and Edge-Ring wafers. The segmentation
activations were not providing discriminative signal to the downstream classifier, most likely
because the two network components were trained independently without end-to-end gradient flow.

_Why the direct CNN was chosen:_ Grad-CAM produces a spatial attribution map that, while
post-hoc, is mathematically grounded and visually interpretable for engineers who understand
wafer spatial structure. The direct CNN also trains as a single optimization problem, making
debugging simpler and training more stable than a disjoint two-stage pipeline.

_Rejected alternative:_ End-to-end joint training of segmentation and classification heads with
shared gradients would address the pipeline's failure mode. This was scoped out due to the
additional architecture redesign and compute time required within the project timeline.

_Conditions and limits:_ For genuinely multi-defect wafers — two or more distinct spatial
patterns coexisting on one map — the direct CNN with Grad-CAM produces a single attribution map
that conflates both patterns. A segmentation architecture trained end-to-end remains the
architecturally correct choice for the multi-label production scenario.

== Decision 2: Class-Agnostic vs. Class-Selective Data Augmentation

Rotation and flipping are standard augmentation techniques for image classification, and
applying them uniformly appeared safe. The evaluation result was sharply non-uniform. The
augmented model (Best CNN + Aug) improved Edge-Loc accuracy from 30% to 85% — a class where
the localized edge failure can appear at any angular position around the wafer perimeter, so
orientation invariance genuinely helps. But Donut accuracy collapsed from 65% to 10%. Donut
is a radially symmetric annular ring, and its class identity relies on the ring being complete.
Rotating a partial Donut sample during training teaches the model that a partial ring is a valid
Donut — which conflicts with the actual defect definition and confuses the model on Donut inputs
at inference time.

_Why augmentation was retained as an option:_ The augmented model is available in the codebase
and UI alongside the non-augmented variant, allowing engineers or future developers to select
the model appropriate for their dominant defect class distribution.

_Rejected approach:_ Uniform augmentation across all 8 classes. The correct approach, identified
after evaluation, is class-selective augmentation: apply rotation/flip only to
orientation-insensitive classes (Edge-Loc, Scratch, Random, Loc) and exclude radially symmetric
classes (Donut, Edge-Ring, Center, Near-full). This was not implemented within the project
timeline.

_Conditions and limits:_ This finding is specific to spatially structured classification problems
where class geometry determines valid augmentation operations. In natural image recognition, uniform
rotation augmentation reliably improves generalization; in wafer map classification, it actively
damages performance on specific classes.

== Decision 3: Knowledge-Based Root Cause Mapping vs. Learned Mapping

Linking defect pattern classification to specific process root causes requires labeled examples
of confirmed causal chains: _this wafer showing an Edge-Ring pattern was caused by this RTP
chamber running at the wrong temperature ramp rate_. No such public dataset exists. The SECOM
dataset from UCI (1,567 samples, 590 process features) contains semiconductor manufacturing
sensor data but does not include spatial wafer maps or defect class labels. Constructing a
learned mapping was therefore not feasible without proprietary fab data.

_Why knowledge-based mapping was chosen:_ The mapping from defect class to process hypothesis
is well-established in semiconductor process engineering literature and does not require training
data. Each defect class maps to one or two candidate process failures:

#figure(
  table(
    columns: (auto, 1fr),
    inset: 7pt,
    align: (left, left),
    stroke: 0.5pt,
    [*Defect Class*], [*Process Hypothesis*],
    [Center],     [CVD deposition rate drift at wafer center; spin-coat nozzle blockage],
    [Donut],      [Non-uniform spin coating (radial thickness variation); CMP pressure ring effect],
    [Edge-Ring],  [Non-uniform thermal processing (RTP); irregular photoresist coating at wafer edge],
    [Edge-Loc],   [Localized thermal non-uniformity (RTP furnace); local gas flow asymmetry],
    [Loc],        [Local particle contamination; clogged process nozzle],
    [Random],     [Airborne contamination; clean room excursion event],
    [Scratch],    [Mechanical handling damage (robot end-effector); CMP over-polishing],
    [Near-full],  [Catastrophic process excursion; full process step failure],
  ),
  caption: [Knowledge-based root cause mapping. Each defect class links to one or two candidate process failure mechanisms from standard CMOS front-end-of-line process engineering literature.],
) <tab:rca>

_Rejected alternative:_ Using a large language model at inference time to generate root cause
suggestions was discussed and rejected. LLM outputs for process engineering recommendations are
plausible-sounding but unverifiable without ground-truth validation, and presenting them as
system output would create a misleading impression of diagnostic authority.

_Conditions and limits:_ The knowledge-based mappings are calibrated for standard bulk CMOS
front-end processes. They may not apply to III-V compound semiconductor processes, MEMS
fabrication, or advanced packaging, where failure mode mechanisms differ substantially.

// ── Section V ────────────────────────────────────────────────
= AI Role and System Autonomy

== The Role of AI in WaferDX

The AI component performs one function: given a 96×96 grayscale wafer map encoded as a
{0.0, 0.5, 1.0} tensor, produce a probability distribution over eight spatial defect pattern
classes. The model is a convolutional neural network trained on a WM-811K subset using
TensorFlow/Keras. It operates entirely on spatial patterns in the 2D pixel grid — it knows
nothing about process parameters, lot history, tool identifiers, or time. Grad-CAM augments this
output with a spatial attribution map by computing the gradient of the top class score with
respect to the final convolutional layer's activations, globally average-pooling those gradients
to produce per-channel importance weights, and taking a weighted linear combination of the
activation maps. The result is a heatmap showing _where_ the model is looking, not _why_ the
defect occurred.

The root cause advisory layer is rule-based, not learned. Once the CNN produces a top predicted
class, a Python dictionary lookup maps that class to the corresponding process hypothesis from
@tab:rca. No machine learning is involved in this step.

== Level of Automation

Classification and heatmap generation are fully automatic: no human input is needed between
image submission and probability output. The root cause lookup is also automatic. Critically,
all three outputs arrive together as a package — the engineer sees the probability distribution,
the spatial heatmap, and the process hypothesis simultaneously, not as a sequential decision
tree.

The decision layer — whether to initiate a tool inspection, quarantine the lot, escalate to
senior engineering review, or flag the result as low-confidence and seek a second opinion — is
entirely human. WaferDX never issues a recommendation to act. It provides structured analytical
input to support the human decision.

== How Engineers Intervene and Review

Three safeguards are built into the system interface. First, the full 8-class probability
distribution is always visible as a ranked bar chart, not just the top-1 label with its
confidence score. An engineer can see immediately that a "Donut" prediction came in at 57%
confidence with Edge-Loc as the second candidate at 38% — a distribution that should prompt
caution before initiating CMP maintenance. Second, the Grad-CAM heatmap allows a visual sanity
check: if the model is attending to the wafer edge rather than a central cluster when predicting
"Center," the engineer can identify the misattribution directly. Third, the system automatically
triggers a dual-hypothesis display when the confidence gap between top-1 and top-2 falls below
0.15, presenting both process hypotheses side-by-side with their respective confidence scores.
All output text in the UI labels results as "pattern hypothesis" rather than "diagnosis" or
"root cause," making the advisory scope explicit throughout.

// ── Section VI ───────────────────────────────────────────────
= Evaluation System, Logic and Evidence

== Goals and Evaluation Setup

The evaluation has two goals: (1) compare classification accuracy across four model variants to
determine which is most suitable for deployment, and (2) characterize failure modes to identify
where the multi-hypothesis display threshold and confidence warnings should be applied. The test
set consists of 160 PNG images generated from WM-811K using `generate_images.py`, balanced at 20
samples per class across all 8 defect types. Four models were evaluated using `test.py`, which
loads each model, preprocesses each image to the model's required input size and normalization
scheme, runs inference, and records the full softmax probability vector, top-3 predicted labels,
and correctness flag for each (image, model) pair into a CSV file (`evaluation_results.csv`).

The evaluation baseline is random chance: for an 8-class balanced problem, random prediction
yields 12.5% accuracy. Any model performing near or below this level on the balanced test set
has not learned generalizable spatial features for that class.

== Per-Class and Overall Accuracy

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 7pt,
    align: (left, center, center, center, center),
    stroke: 0.5pt,
    [*Class*],       [*Best CNN*], [*Best CNN + Aug*], [*Fullstack*], [*Seg → CLF*],
    [Center],        [0%],    [0%],    [—],    [—],
    [Donut],         [65%],   [10%],   [—],    [—],
    [Edge-Loc],      [30%],   [85%],   [—],    [—],
    [Edge-Ring],     [0%],    [0%],    [—],    [—],
    [Loc],           [0%],    [0%],    [—],    [—],
    [Near-full],     [5%],    [15%],   [—],    [—],
    [Random],        [5%],    [0%],    [—],    [—],
    [Scratch],       [0%],    [0%],    [—],    [—],
    [*Overall*],     [*13.1%*\ (21/160)], [*13.8%*\ (22/160)], [*17.5%*\ (28/160)], [*11.9%*\ (19/160)],
  ),
  caption: [Per-class and overall accuracy for all four model variants on the 160-sample balanced test set (20 images per class). Fullstack and Seg → CLF per-class breakdowns are not shown due to space, but overall figures are confirmed from evaluation_results.csv. "—" indicates data not broken out for this model in the per-class analysis.],
) <tab:accuracy>

The overall figures cluster between 11.9% and 17.5% — near random-chance on a balanced 8-class
problem. This reflects a genuine model performance issue, not a test set artifact: the same
CNN architecture that reportedly achieves 70–80% accuracy during training on the full WM-811K
training set generalizes poorly to this balanced 160-sample test set, where rare classes like
Scratch and Random are equally represented with common ones like Donut and Edge-Loc.

== Key Failure Cases

The Center/Near-full confusion is the most operationally consequential failure. The Best CNN
assigns Near-full probability 0.90–0.98 to Center inputs: 18 out of 20 Center images are
predicted as Near-full with high confidence. The root cause implications are entirely opposite —
Center implicates a routine CVD deposition calibration drift, while Near-full implicates a
catastrophic full-step failure requiring immediate lot quarantine. A system presenting only
top-1 outputs would mislead an engineer into a drastic response for a routine calibration issue
on 90% of Center wafers.

The augmentation experiment's Donut collapse is the second major failure. Edge-Loc accuracy
jumps from 30% (no augmentation) to 85% (with augmentation), but Donut drops from 65% to 10%
in the same model. The augmented model was not evaluated on Donut-heavy production input
distributions because the effect was discovered only after examining per-class results in the CSV.

The Seg → CLF pipeline's collapse to "Center" predictions (confidence = 1.0 for over 90% of
inputs) is a training failure visible in every row of the evaluation CSV for that model variant.
The classification head learned the dominant class from its training distribution rather than
exploiting the segmentation activations.

== Evaluation Limitations

The 160-sample test set is balanced by design, which does not reflect the actual production
input distribution, where Center and Near-full patterns are rare events and "None" (no defect)
is by far the most common outcome. Model performance on rare classes in a production setting
would be expected to be lower still, since training data for Scratch (fewer than 300 samples in
the full labeled WM-811K dataset) is genuinely scarce. All test images are single-class; no
multi-defect synthetic maps were included in the evaluation, so the system has not been tested
on the scenario it would encounter most in a real fab. The evaluation is also entirely automated
— no engineer reviewed the Grad-CAM outputs qualitatively, so heatmap quality remains
unvalidated against expert judgment.

// ── Section VII ──────────────────────────────────────────────
= Discussion: Transferable Design Insights

== Transferable Design Principles

*Augmentation must respect class geometry.* Rotation augmentation improved Edge-Loc accuracy
by 55 percentage points and degraded Donut accuracy by 55 points in the same training run. Any
domain where class identity is geometrically defined — satellite image analysis, histopathology
slide orientation, printed circuit board defect inspection, medical imaging — requires
class-specific augmentation policies. Uniform augmentation is not a safe default when different
classes have different spatial symmetries.

*Confidence calibration matters more than accuracy for decision support.* The Best CNN assigns
Near-full confidence of 0.90–0.98 to Center inputs and is wrong on 18 of 20 such cases. That
combination — high confidence, wrong answer — is more dangerous for decision support than low
confidence with a wrong answer, because the UI's low-confidence warning would not trigger. Post-hoc
calibration methods (Platt scaling, temperature scaling, isotonic regression on a held-out
calibration set) should be treated as mandatory components in any decision support system, not
optional improvements.

*Separating classification from root cause reasoning makes systems easier to maintain.* The CNN
does not need to learn process engineering. The RCA mapping does not need to encode visual
feature detection. When a new process step introduces a new failure mode, only the lookup table
requires updating, not a model retraining cycle. This modularity pattern applies to any ML
system where domain knowledge is well-structured but training data for that knowledge layer is
unavailable.

== Context-Dependent Elements

The preprocessing pipeline — nearest-neighbor resampling, zero-padding before resize, {0.0,
0.5, 1.0} normalization — is specific to WM-811K's integer-encoded format. Applying it to
continuous-valued images (standard photographs, analog sensor readouts) would produce incorrect
model inputs. The RCA knowledge base is written for standard bulk CMOS front-end-of-line
processes. A fab running SiC power devices, GaN-on-Si, or advanced 3D packaging would need
entirely different process-to-defect mappings.

The 96×96 input resolution was chosen for WM-811K's size distribution (25×25 to 300×300, mean
near 80×80). A dataset with larger wafer maps — as would come from higher-resolution inspection
equipment — would require a larger input resolution and a deeper network.

== Design Risks and Governance Considerations

The most significant governance risk in this system is calibration failure producing
high-confidence wrong predictions without triggering any warning. The current threshold-based
safeguard (show multi-hypothesis display when confidence gap < 0.15) does not help when the
model is confidently wrong about the top-1 class, as observed in the Center/Near-full case.
Any production deployment should include: (1) per-class confidence calibration validated on
a representative held-out set, (2) mandatory human review for Near-full and Scratch predictions
given their high operational consequence, and (3) a logged feedback loop so engineer override
decisions accumulate as training data for future model versions.

A secondary risk is over-reliance on the root cause advisory output. The knowledge-based RCA
mappings are heuristics, not verified causal chains. An engineer who acts on the process
hypothesis without cross-checking with tool run logs and chamber sensor data could initiate a
costly tool inspection based on a misclassified defect type. The system's labeling of all RCA
outputs as "hypotheses" rather than "diagnoses" is a necessary but not fully sufficient safeguard.

// ── Section VIII ─────────────────────────────────────────────
= Conclusion and Future Extensions

== System Design Contributions

WaferDX demonstrates that explainability in a wafer defect decision support system requires
more than appending a Grad-CAM heatmap to a CNN. The evaluation across four model variants on a
160-sample balanced test set revealed that overall accuracy alone conceals class-level
calibration failures severe enough to make single-hypothesis outputs actively misleading — most
critically, the Best CNN predicts Near-full with 0.90–0.98 confidence for Center inputs, which
would trigger a lot quarantine response for a routine calibration drift.

The system's practical contribution is the decision support framing: always displaying the full
8-class probability distribution, pairing every prediction with a spatial Grad-CAM heatmap that
engineers can use to verify model attention, providing a structured RCA advisory layer that
converts classification outputs into actionable process hypotheses, and triggering explicit
dual-hypothesis display for ambiguous predictions. The finding that class-selective augmentation
is required for orientation-asymmetric defect patterns is a concrete, falsifiable result with
direct implications for any spatial classification task where class identity is geometrically
constrained.

== Design Adjustments with Additional Resources

With more time and compute, three extensions would most substantially improve the system.

First, per-class temperature scaling applied to the model's softmax output using a held-out
calibration set would address the systematic overconfidence in Near-full predictions. A 500-sample
per-class calibration set (4,000 samples total) drawn from WM-811K and processed through isotonic
regression would likely reduce the Center/Near-full confidence gap to a level where the existing
threshold-based warning system triggers correctly.

Second, synthetic multi-defect map generation — producing maps by taking the logical union of
two single-class WM-811K samples — would allow training and evaluation in the multi-label setting
that better reflects production reality. This requires a multi-label loss function (binary
cross-entropy per class rather than softmax cross-entropy) and multi-label evaluation metrics
(per-class recall, F1 per class), but the data generation step is straightforward from the
existing dataset.

Third, integrating process log data from confirmed-defect wafers — tool IDs, chamber sensor
readings, and run timestamps — would allow the knowledge-based RCA layer to be partially replaced
by a learned mapping, potentially validating and extending the current heuristic associations
with empirical causal data from actual production. This data exists inside every semiconductor
fab but is not publicly available.

// ── References ───────────────────────────────────────────────
= References

#set par(hanging-indent: 1.5em)

Chollet, F. (2021). _Deep learning with Python_ (2nd ed.). Manning Publications.

Molnar, C. (2022). _Interpretable machine learning: A guide for making black box models
explainable_ (2nd ed.). https://christophm.github.io/interpretable-ml-book/

Selvaraju, R. R., Cogswell, M., Das, A., Vedantam, R., Parikh, D., & Batra, D. (2017).
Grad-CAM: Visual explanations from deep networks via gradient-based localization.
_Proceedings of the IEEE International Conference on Computer Vision (ICCV)_, 618–626.

Shim, J., Hwang, C., & Lee, S. (2020). Wafer map defect pattern classification based on
convolutional neural network features and error-correcting output codes. _Journal of Intelligent
Manufacturing_, _31_(5), 1861–1875.

Wu, M. J., Jang, J. S. R., & Chen, J. L. (2015). Wafer map failure pattern recognition and
similarity ranking for large-scale data sets. _IEEE Transactions on Semiconductor Manufacturing_,
_28_(1), 1–12.

Gregor, S., & Hevner, A. R. (2013). Positioning and presenting design science research for
maximum impact. _MIS Quarterly_, _37_(2), 337–355.