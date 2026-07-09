# NTU Data Analysis Project
This project implements wafer defect classification using CNN models and a Streamlit-based UI as the final project for the Data Analysis and Machine Learning course at National Taiwan University.

## Prerequisites
- Python 3.11
- pip

Verify your Python version:

    python3 --version

Expected output:

    Python 3.11.x

## Automatic Setup (Recommended)

Run the setup script:

    chmod +x setup.sh
    ./setup.sh

The script will:
1. Create a virtual environment named "env"
2. Activate the virtual environment
3. Install all required dependencies from requirements.txt


## Manual Setup

Create and activate a virtual environment:

    python3 -m venv env
    source env/bin/activate

Install dependencies:

    pip install -r requirements.txt


## Project Dependencies

- numpy
- pandas
- matplotlib
- tensorflow-cpu
- streamlit
- streamlit-drawable-canvas
- tqdm
- jupyter
- ipywidgets
- iprogress
- ...many more which we forgot to list


## Running the Project

Run the Streamlit application:

    streamlit run src/App/app.py
