# Wafer Map Pattern Recognition (WMPR)
Wafers are composed of hundreds of individual chips (dies). When a "bin map" is generated after electrical testing, the spatial distribution of failing chips often forms a pattern.

The Idea: Specific shapes on a wafer map point to specific tool failures. A "ring" pattern might indicate a chemical vapor deposition (CVD) problem; a "scratch" indicates a robotic handling error.

ML Approach: Using ResNet or EfficientNet to classify the global pattern of the wafer map to provide "Root Cause Analysis" (RCA). This tells engineers exactly which machine in the factory is broken.