import os
import cv2
import numpy as np
import tensorflow as tf
from keras.models import load_model
from pygame import mixer
from flask import Flask, request, jsonify

# Initialize Flask app
app = Flask(__name__)

# Initialize alarm sound (this works on the machine running the server)
mixer.init()
sound = mixer.Sound('alarm.wav')

# Load Haar cascades for face and eye detection
face_cascade = cv2.CascadeClassifier('haar cascade files/haarcascade_frontalface_alt.xml')
leye_cascade = cv2.CascadeClassifier('haar cascade files/haarcascade_lefteye_2splits.xml')
reye_cascade = cv2.CascadeClassifier('haar cascade files/haarcascade_righteye_2splits.xml')

# Label definitions and load the model
lbl = ['Close', 'Open']
model = load_model('models/model.h5')

# Global variables to track scoring and latest prediction
score = 0
latest_prediction = "No data"
latest_score = 0
thicc = 2
val1 = 1
val2 = 1

@app.route('/predict', methods=['POST'])
def predict():
    global score, thicc, val1, val2, latest_prediction, latest_score

    # Check for image file in request
    if 'image' not in request.files:
        return jsonify({'status': 'failure', 'message': 'No image file provided'}), 400

    # Read and decode the image from the request
    file = request.files['image']
    file_bytes = np.frombuffer(file.read(), np.uint8)
    frame = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
    if frame is None:
        return jsonify({'status': 'failure', 'message': 'Invalid image file'}), 400

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    current_status = 'Unknown'

    # Detect faces and eyes
    faces = face_cascade.detectMultiScale(gray, minNeighbors=5, scaleFactor=1.1, minSize=(25,25))
    left_eyes = leye_cascade.detectMultiScale(gray)
    right_eyes = reye_cascade.detectMultiScale(gray)

    # Process right eye (if detected)
    for (x, y, w, h) in right_eyes:
        r_eye = frame[y:y+h, x:x+w]
        r_eye_gray = cv2.cvtColor(r_eye, cv2.COLOR_BGR2GRAY)
        r_eye_resized = cv2.resize(r_eye_gray, (52, 52))
        r_eye_norm = r_eye_resized / 255.0
        r_eye_reshaped = r_eye_norm.reshape(52, 52, 1)
        rpred = model.predict(np.expand_dims(r_eye_reshaped, axis=0))
        if rpred[0][0] > rpred[0][1]:
            val1 = 0
            current_status = 'Closed'
        else:
            val1 = 1
            current_status = 'Open'
        break  # Process only the first detected right eye

    # Process left eye (if detected)
    for (x, y, w, h) in left_eyes:
        l_eye = frame[y:y+h, x:x+w]
        l_eye_gray = cv2.cvtColor(l_eye, cv2.COLOR_BGR2GRAY)
        l_eye_resized = cv2.resize(l_eye_gray, (52, 52))
        l_eye_norm = l_eye_resized / 255.0
        l_eye_reshaped = l_eye_norm.reshape(52, 52, 1)
        lpred = model.predict(np.expand_dims(l_eye_reshaped, axis=0))
        if lpred[0][0] > lpred[0][1]:
            val2 = 0
            current_status = 'Closed'
        else:
            val2 = 1
            current_status = 'Open'
        break  # Process only the first detected left eye

    # Update score: increase when both eyes are closed, decrease otherwise
    if val1 == 0 and val2 == 0:
        score += 1
    else:
        score -= 1
    if score < 0:
        score = 0

    # Optional: if score exceeds threshold, save an alert image and try to play the alarm sound.
    if score > 15:
        alert_image_path = os.path.join(os.getcwd(), 'alert_image.jpg')
        cv2.imwrite(alert_image_path, frame)
        try:
            if score > 20:
                sound.play()
        except Exception as e:
            print("Error playing sound:", e)

    # Update global latest data for polling
    latest_prediction = current_status
    latest_score = score

    # Build response JSON
    response = {
        'prediction': current_status,
        'score': score
    }
    return jsonify(response), 200

# New endpoint for polling fatigue data
@app.route('/latest_score', methods=['GET'])
def latest_score_endpoint():
    global latest_prediction, latest_score
    data = {
        'prediction': latest_prediction,
        'score': latest_score
    }
    return jsonify(data), 200

if __name__ == '__main__':
    # Bind to all interfaces so that the server is accessible on your local network
    app.run(host='0.0.0.0', port=5001, debug=True)

