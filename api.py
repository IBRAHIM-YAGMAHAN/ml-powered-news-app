# -*- coding: utf-8 -*-
"""
Created on Sat Apr 11 18:58:59 2026

@author: ibrah
"""

from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import re

from newspaper import Article

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


#-----------------haberleri cekmek icin-----------------

class UrlRequest(BaseModel):
    url: str 
    
@app.post("/get_full_text")
def full_text(request: UrlRequest):
    try:
        article = Article(request.url)
        article.download()
        article.parse()
        
        #haberin tam metini ve basligini geri gonderme
        return{
            "statu": "successful",
            "full_text": article.text
            }
    except Exception as e:
        return {
            "statu": "Error",
            "message":"The news article could not be retrieved; the site may be blocked."
            }
    
    
    
    
    
    
    
    
    
    
    
    
    