# -*- coding: utf-8 -*-
"""
Created on Sat Apr 11 18:58:59 2026

@author: ibrah
"""

from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import re
import trafilatura

# Sunucu baslatma
app = FastAPI(title='News Category Prediction API')

model = joblib.load('haber_modeli.joblib')
vectorizer = joblib.load('haber_vectorizer.joblib')

category_name = {
    1: "World",
    2: "Sports", 
    3: "Business",
    4: "Sci/Tech"
}

# Gelen haberleri temizlememiz gerek
def clear_text(text):
    text = text.lower()
    text = re.sub(r'[^a-z\s]', '', text) 
    return text

# Gelen haberlerin formatini duzenliyoruz
class NewsRequest(BaseModel):
    header: str 
    
@app.post("/predict")
def predict_category(request: NewsRequest):
    # Gelen basligi temizledik
    clear_header = clear_text(request.header) 
    vector = vectorizer.transform([clear_header])
    
    pred_no = model.predict(vector)[0]
    
    return {
        "orijinal_baslik": request.header,
        "kategori_kodu": int(pred_no),
        "kategori_adi": category_name[pred_no] 
    }
        
@app.get("/")
def ana_sayfa():
    return {"mesaj": "Haber Tahmin API'si Çalışıyor!"}

#haberleri cekmek icin
class UrlRequest(BaseModel):
    url: str 
    
@app.post("/get_full_text")
def full_text(request: UrlRequest):
    try:
        downloaded = trafilatura.fetch_url(request.url)
        text = trafilatura.extract(downloaded)
        
        if text and len(text.strip()) > 50:
            return {"statu": "successful", "full_text": text}
        else:
            return {
                "statu": "Error", 
                "message": "Site blocked the request."
            }
    except Exception as e:
        return {"statu": "Error", "message": str(e)}
        
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=7860)
