# Wafer Map Pattern Recognition (WMPR)
Wafers are composed of hundreds of individual chips (dies). When a "bin map" is generated after electrical testing, the spatial distribution of failing chips often forms a pattern.

The Idea: Specific shapes on a wafer map point to specific tool failures. A "ring" pattern might indicate a chemical vapor deposition (CVD) problem; a "scratch" indicates a robotic handling error.

ML Approach: Using ResNet or EfficientNet to classify the global pattern of the wafer map to provide "Root Cause Analysis" (RCA). This tells engineers exactly which machine in the factory is broken.


## Datasets
- [WM-811K wafer map](https://www.kaggle.com/datasets/qingyi/wm811k-wafer-map/data)
  - *wafer map --> defect type*
  - 811,457 wafer maps collected from 46,393 lots in real-world fabrication
  - defect types: Center, Donut, Edge-Loc, Edge-Ring, Loc, Random, Scratch, Near-full, none
  - [subset](https://www.kaggle.com/datasets/muhammedjunayed/wm811k-silicon-wafer-map-dataset-image) (only 1 MB instead of 2 GB)

- [Wafer bin maps](https://webmail5.hrz.tu-freiberg.de/imp/dynamic.php?page=mailbox#mbox:SU5CT1g)
  - *wafer map --> error stage* (???)

- (optional TODO) find dataset to map wafer maps / defect classes to typical machine failure


## Pitch 1
- UI application where you can draw defects on a wafer 
- a CNN classifier model outputs the probabilities for all defect types and states the most prominent one
- training directly on dataset (single defect type per wafer)


## Pitch 2
- UI application where you can draw defects on a wafer
- an image segmentation model extracts the patterns relevant to the specific classes
- a secondary model outputs a classification based on the segmentation
- training on mixed-defect maps formed by disjunction of single-defect maps
