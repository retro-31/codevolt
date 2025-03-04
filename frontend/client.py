import cv2
import requests
import time

# Replace <server-ip> with your server laptop's IP address
url = 'http://172.16.45.12:5001/predict'

# Open the default camera
cap = cv2.VideoCapture(0)

# Set desired frame rate (for example, 5 frames per second)
fps = 5
frame_interval = 1.0 / fps

print("Starting image capture and transmission...")

try:
    while True:
        start_time = time.time()
        
        # Capture frame
        ret, frame = cap.read()
        if not ret:
            print("Failed to capture image")
            break
        
        # Encode the frame as JPEG
        ret, jpeg = cv2.imencode('.jpg', frame)
        if not ret:
            print("Failed to encode image")
            continue
        
        # Convert to bytes
        image_bytes = jpeg.tobytes()
        
        # Create a dictionary with the file data; the key must be "image"
        files = {
            'image': ('frame.jpg', image_bytes, 'image/jpeg')
        }
        
        # Send the image as a POST request
        try:
            response = requests.post(url, files=files, timeout=1)
            if response.status_code == 200 | response.status_code == 201:
                # The server returns a JSON with prediction and score
                data = response.json()
                print("Prediction:", data.get('prediction'), "Score:", data.get('score'))
            else:
                print("Server responded with status code:", response.status_code)
        except Exception as e:
            print("Error sending image:", e)
        
        # Wait to maintain the desired FPS
        elapsed_time = time.time() - start_time
        sleep_time = frame_interval - elapsed_time
        if sleep_time > 0:
            time.sleep(sleep_time)
finally:
    cap.release()
    print("Released camera resource")
