
= Notes on
This is a collection of progress notes on the archetecture, training and chellenges of the Network used for this project, which can be used as reference when writing the final report:
== Data Preparation
There is an encoutered difficulty in the data set due to varying wafer map sizes:
- 632 different format sizes for the wafer maps, differing in aspect ratio and varyig from 25x25 for the smallest to 300x300 for the biggest.
- To Tackle this an additional step of data cleaning/preperation was taken
- To preserve information and features, simple rescaling is not enough
- since the input map is initially an integermap(0 for background, 1 for no marking, 2 for defect marking) there is a need for rescaling without averaging over neighbouring pixels, so a nearest neighbor rescaling is taken. (*maybe*)
- To avoid making features less recognizable by warping, before rescaling padding is added(pixels of 0 for background)
- To not make the Network too large but to also not loose too much information and finer details on larger wafers a scale of 96x96, above the overall average size, is chosen.
== Data Augmentation
- For simple data Augmentation in the dataset pipeline the images are, flipped and rotated in 90degree angles 
== Network approaches
- Baseline CNN caps out at $approx 70-80%$ accuracy 
