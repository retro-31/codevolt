# HELMATE

## Instructions to run server side of the application

### python environment setup and server startup (Run the following command in the working directory of the repository)

#### For running model.py 

```bash
conda create -n CNN_model python=3.7
conda activate CNN_mode
pip install -r model_requirements.txt
cd /server
python model.py
```

#### For running main.py

```bash
conda create -n helmate_server python=3.12
conda activate helmate_server
pip install flask psycopg2 opencv-python
cd /server
python main.py
```

## Instructions to run Frontend of the application on flutter

1. Insert an android phone and enable **usb debugging**
2. Install flutter sdk with android studio
3. Run the following commands to install the application on the phone

```bash
cd /frontend
flutter run
```