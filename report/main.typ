#set page(paper: "a4", margin: 1in)
#set text(size: 12pt)
#set heading(numbering: "1.")
#show heading: it => {
  v(2em)
  it
  v(1em, weak: true)
}
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  set text(size: 18pt)
  set par(justify: false)
  it
  line(length: 100%, stroke: 0.5pt)
  v(1em)
}
#set par(justify: true)
#set page(paper: "a4", margin: 1in, numbering: "1")
#set text(lang: "en", hyphenate: true)



// title page
#align(center)[
  #v(30%)
  #text(size: 18pt, weight: "bold", hyphenate: false)[
    Explainable Artificial Intelligence-Based Wafer Map Defect Diagnosis and Decision Support System
  ]
  #v(1em)

  Abhirup Sain (T14H06318) \
  David Spickenheuer (T14H06329) \
  Martin Werner (T14H06319) \
  Matti Lehmann (T14H06309) \
  Staniya Thomas (T14H06310)
]



// table of contents
#outline(indent: 1cm)



// section
= Introduction



// section
= Dataset

== WM-811K (Source)
single defect wafermaps, different sizes, different aspect ratios, values {0,1,2}, great majority of samples actually have no label assigned 

(see "Notes_on_NN_for_report" for more)

== Preprocessing
resizing, rescaling, augmentation

== Creation of Multi-Defect Samples
combination of single-defect wafermaps \
combination of one-hot encoded labels

== Implementation
`WM_811K` dataset class:
- holds mapping of defect classes to integers (!single source of truth)
- holds image size used for resizing -> used by models (!single source of truth, consistency)
- holds static methods for image preprocessing and augmentation (!single source of truth, consistency)



// section
= Defect Classification

== Segmentation Model
> Architecture (U-Net inspired, see code)

== Classification Model
> Architecture (Classical CNN, eventually Spatial Attention layers, see code)

== Fullstack Model
> Architecture (just stack the previous two, see code)

== Training
training in 3 phases:

=== Phase 1
train image segmentation model only 
#figure(image("../plots/segmentation_loss_curve.png", width: 70%))
#figure(image("../plots/segmentation_sample_init.png"), caption: "segmentation output before training")
#figure(image("../plots/segmentation_sample_100epochs.png"), caption: "segmentation output after 100 epochs")

=== Phase 2 
train classification model only on segmentation model output
#figure(image("../plots/classification_pretrain_loss_curve.png"))

=== Phase 3
fine tune fullstack model



// section
= Root Cause Analysis



// section
= User Interface



= Conclusion
