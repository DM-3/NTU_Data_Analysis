# NTU Data Analysis - Explainable AI Decision Support System

## 1. Group discussion
Submission details:
- deadline: before class on 3/31
- file name: "<groupID>_gd"
- content: any type of our disccussion result during the first week
- context: can be anything, such as topic, thoughts, or any final presentation related content



## 2. File structure
--------------------------------------------------
OVERVIEW
--------------------------------------------------
This project implements wafer defect classification using CNN models and a Streamlit-based UI.
There are two separate models and corresponding apps:

1. best_wafer_cnn (96x96 input)
2. direct_classifier_cnn (64x64 input)


--------------------------------------------------
APPLICATION FILES
--------------------------------------------------

app_best_wafer_cnn.py
- Streamlit app for the best CNN model
- Uses 96x96 input size
- Loads model from: src/best_wafer_cnn.keras
- Allows image upload or drawing
- Displays predicted wafer defect classes with confidence

app_direct_classifier_cnn.py
- Streamlit app for simpler CNN model
- Uses 64x64 input size
- Loads model from: models/direct_classifier_cnn.keras
- Same UI functionality as above


--------------------------------------------------
MODEL FILES
--------------------------------------------------

src/best_wafer_cnn.keras
- Trained CNN model using 96x96 wafer images
- Higher accuracy model

models/direct_classifier_cnn.keras
- CNN model trained on 64x64 wafer images
- Simpler and faster model


--------------------------------------------------
DATASET FILES
--------------------------------------------------

dataset.py
- Contains dataset loading classes

  WM_811K:
  - Loads raw wafer dataset (LSWMD_slimmed.pkl)
  - Resizes images dynamically

  WM_811K_preprocessed:
  - Loads preprocessed dataset from .npz file
  - Combines train and test sets


--------------------------------------------------
TRAINING NOTEBOOKS
--------------------------------------------------

temp.ipynb
- Trains CNN on 64x64 dataset
- Uses TensorFlow dataset pipeline
- Includes model training, validation, and evaluation

temp2.ipynb
- Preprocesses wafer dataset to 96x96
- Saves dataset as wafer_dataset_96x96.npz
- Trains best-performing CNN model


--------------------------------------------------
DATA GENERATION & TESTING
--------------------------------------------------

generate_images.py
- Generates balanced wafer images from dataset
- Saves images into generated_images/ folder

generated_images/
- Contains generated wafer samples for testing

test.py (evaluation script)
- Loads trained model
- Preprocesses input images
- Runs predictions
- Calculates accuracy


--------------------------------------------------
ASSETS
--------------------------------------------------

icons/
- Contains icons for each wafer defect class
- Used in Streamlit UI for visualization


--------------------------------------------------
PREPROCESSING
--------------------------------------------------

Important: Preprocessing must match training.

Steps:
- Convert image to grayscale
- Resize using resize_with_pad
- Normalize using:
  arr = round(arr / 127.5)

This keeps values consistent with training data (0,1,2).


--------------------------------------------------
DEFECT CLASSES
--------------------------------------------------

Center
Donut
Edge-Loc
Edge-Ring
Loc
Random
Scratch
Near-full
None


--------------------------------------------------
HOW TO RUN
--------------------------------------------------

Run best model app:
streamlit run app_best_wafer_cnn.py

Run direct classifier app:
streamlit run app_direct_classifier_cnn.py


--------------------------------------------------
NOTES
--------------------------------------------------

- Use correct input size for each model:
  96x96 -> best_wafer_cnn
  64x64 -> direct_classifier_cnn

- Mismatch in preprocessing or size will reduce accuracy

- Model performance depends heavily on preprocessing consistency
