from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import numpy as np
import tensorflow as tf
import io

app = FastAPI(title="EcoScan V2 API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Loading EcoScan model...")
model = tf.keras.models.load_model('EcoScan_MultiClass_V1.h5')
print("Model loaded successfully.")

CLASS_NAMES = [
    'battery', 'biological', 'brown-glass', 'cardboard', 'clothes', 
    'glass', 'green-glass', 'metal', 'paper', 'plastic', 'shoes', 'trash', 'white-glass'
]

KELOMPOK_ANORGANIK = [
    'battery', 'brown-glass', 'cardboard', 'clothes', 'glass', 
    'green-glass', 'metal', 'paper', 'plastic', 'shoes', 'trash', 'white-glass'
]

def prepare_image(image_bytes):
    """
    Convert raw image bytes to a preprocessed tensor suitable for ResNet50.
    """
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((224, 224))
    x = tf.keras.preprocessing.image.img_to_array(img)
    x = np.expand_dims(x, axis=0)
    x = tf.keras.applications.resnet50.preprocess_input(x)
    return x

@app.post("/predict")
async def predict_trash(file: UploadFile = File(...)):
    """
    Predict the waste category of an uploaded image.
    """
    try:
        image_bytes = await file.read()
        
        processed_image = prepare_image(image_bytes)
        
        predictions = model.predict(processed_image)
        predicted_index = np.argmax(predictions[0])
        predicted_class = CLASS_NAMES[predicted_index]
        confidence = float(predictions[0][predicted_index]) * 100
        
        category = "Anorganik" if predicted_class in KELOMPOK_ANORGANIK else "Organik"
        
        return {
            "status": "success",
            "class": predicted_class,
            "category": category,
            "confidence": round(confidence, 2)
        }
        
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/")
def read_root():
    return {"status": "ok", "message": "EcoScan V2 API is running"}
