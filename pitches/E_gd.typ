#set page(paper: "a4", margin: 1in)
#set text(size: 12pt)
#set heading(numbering: "1.")
#set par(justify: true)
#set page(paper: "a4", margin: 1in, numbering: "1")
#set text(lang: "en", hyphenate: true)




#align(center)[
  #text(size: 16pt, weight: "bold", hyphenate: false)[
    Explainable Artificial Intelligence-Based Wafer Map Defect Diagnosis and Decision Support System
  ]


  #v(0.5em)


  Abhirup Sain (T14H06318) \
  David Spickenheuer (T14H06329) \
  Martin Werner (T14H06319) \
  Matti Lehmann (T14H06309) \
  Staniya Thomas (T14H06310)
]


= Project Motivation

Process Yield is the deciding factor in economic success of a semiconductor fab. While precise process control is able to prevent most defects, wafers still need to be continuously checked for faults. In semiconductor manufacturing, wafer maps visually represent the spatial distribution of defective dies. Engineers rely on these patterns to identify process issues and diagnose failures. Ideally, malfunctions in the tools can be determined and prevented in future manufacturing via parameter tuning and sensor recalibration. This process is time-consuming and depends heavily on expert knowledge.

In practice, a single wafer may exhibit multiple defect patterns simultaneously, making diagnosis more complex and increasing the difficulty of identifying root causes. This project aims to develop an Explainable Artificial Intelligence (AI) Decision Support System that assists engineers in identifying defect patterns and understanding their possible root causes. Instead of providing only a classification result, the system will generate interpretable insights and actionable recommendations.


= Problem Statement

To be able to improve the production yield and identify errors in the production process, given a wafer map image, the system should:


- Detect and classify one or more defect patterns (multi-label classification)
- Provide an explanation of why each pattern is identified
- Suggest likely process-related causes for each detected defect
-  In the best case even recommend possible actions for engineers


The system does not provide guaranteed conclusions but supports decision-making under uncertainty.


= Proposed System Overview


The system consists of three main components:

+ *Defect Classification Model*

  A deep learning model  will be adapted for multi-label classification to identify multiple defect types present in a single wafer map.

+ *Root Cause Analysis (RCA) Engine*


  A knowledge-based mapping will connect defect patterns to likely process issues and machine types.


+ *Decision Support Layer*


  The system will generate:


  - Diagnosis (multiple defect types with confidence scores)
  - Explanation (key contributing regions for each defect)
  - Root cause suggestions
  - Actionable recommendations


= Dataset


We will use the WM-811K wafer map dataset, which contains:


- 811,457 wafer maps
- 46,393 manufacturing lots
- Multiple defect categories:
  - Center
  - Donut
  - Edge-Loc
  - Edge-Ring
  - Loc
  - Random
  - Scratch
  - Near-full
  - None


Although each wafer is labeled with a primary defect type in the dataset, real-world wafers may contain multiple defect patterns. This project extends the problem to a multi-label detection setting.


Due to computational constraints, a subset of the dataset might be used.


= Methodology
The system will be implemented in python using either PyTorch or TensorFlow (still an open question in discussion) for the machine learning, NumPy and Pandas for data analysis and pre-processing, Matplotlib or Open Source Computer Vision Library (OpenCV) for visualization of the results and PyQt for the user interface




== Step 1: Data Preprocessing


- Normalize wafer maps
- Prepare training and Test Data
- Resize images
- maybe include additional handcrafted Features like Fourier-transform of the wafer-images
- Convert to suitable input format for the Convolutional Neural Network (CNN)


== Step 2: Model Training

As part of the discussion we came up with two possible general aproaches to realize the classification

+ single network approach:
  - a typical convolutional neural network (CNN) maps the multi-defect wafer maps to the likelihood values for all classes

+ a dual network approach:
  - an image segmentation model maps the multi-defect wafer to activation maps for the individual defect classes
  - a classification model maps the single-defect activation maps to the likelihoods values for all classes
  - this would pose the advantage of being able to handle multi deffect wafers, and would provide a higher explainability

   




== Step 4: Root Cause Knowledge Mapping


Since no public dataset directly links SECOM (a semiconductor manufacturing sensor dataset) readings to WM-811K defect labels, we construct the following knowledge-based mapping:


- Center    → Thin film deposition failure (Chemical Vapor Deposition (CVD) rate drift at wafer center)
- Donut → Non-uniform spin coating (radial thickness variation) or Chemical Mechanical Planarization pressure ring effect
- Edge-Ring → Non-uniform thermal processing (RTP) or irregular PR coating thickness during spin coating
- Edge-Loc  → Localized thermal non-uniformity (Rapid Thermal Processing (RTP) or furnace)
- Loc       → Local particle contamination or clogged process nozzle
- Random    → Airborne contamination or clean room excursion
- Scratch   → Mechanical handling damage or Chemical Mechanical Planarization (CMP) over-polishing
- Near-Full → Catastrophic process excursion (full step failure)


Multiple detected defect types on a single wafer indicate concurrent failure modes and are handled by assigning multi-label root cause sets.


== Step 5: Decision Support Output


Generate structured output including:


- Multiple predictions with confidence scores
- Explanation of influencing regions for each defect
- Likely causes
- Optionally a last layer consisting of an LLM-wrapper could be added to give advice on what to fix based on the classified error and the root cause analysis
-UI for wafer image input and classification/advice

#figure(
  image("wafer_system_design.jpg", width: 80%),
  caption: [Initial system design sketch showing User Interface (UI) layout, model pipeline, and module breakdown],
) <fig:system-design>



= Expected Output Example


- *Detected Defects:*
  - Edge-Ring (Confidence: 85%)
  - Scratch (Confidence: 62%)
- *Explanation:*
  - Edge concentration near wafer boundary
  - Linear defect pattern indicating mechanical damage
- *Likely Causes:*
  - Gas flow non-uniformity (CVD process)
  - Robotic handling issue
- *Recommendation:*
  - Inspect CVD chamber gas distribution
  - Check wafer handling robot alignment



= Division of Work (Tentative)


- Data preprocessing and dataset handling
- Model development and training
- Explainability and interpretation
- UI development and system integration
- Report writing and presentation 


= Expected Contributions


- An explainable AI system for wafer defect diagnosis
- Multi-label defect detection for realistic scenarios
- Integration of deep learning with domain knowledge
- A decision support framework for semiconductor manufacturing
- Improved interpretability compared to black-box models


= Future Extensions


- Incorporate real fabrication facility data with process logs
- Use temporal wafer data for predictive maintenance
- Extend system to multi-stage failure diagnosis
