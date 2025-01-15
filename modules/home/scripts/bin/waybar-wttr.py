#!/usr/bin/env python

import json
import requests
from datetime import datetime

WEATHER_CODES = {
    '113': '☀️',
    '116': '⛅️',
    '119': '☁️',
    '122': '☁️',
    '143': '🌫',
    '176': '🌦',
    '179': '🌧',
    '182': '🌧',
    '185': '🌧',
    '200': '⛈',
    '227': '🌨',
    '230': '❄️',
    '248': '🌫',
    '260': '🌫',
    '263': '🌦',
    '266': '🌦',
    '281': '🌧',
    '284': '🌧',
    '293': '🌦',
    '296': '🌦',
    '299': '🌧',
    '302': '🌧',
    '305': '🌧',
    '308': '🌧',
    '311': '🌧',
    '314': '🌧',
    '317': '🌧',
    '320': '🌨',
    '323': '🌨',
    '326': '🌨',
    '329': '❄️',
    '332': '❄️',
    '335': '❄️',
    '338': '❄️',
    '350': '🌧',
    '353': '🌦',
    '356': '🌧',
    '359': '🌧',
    '362': '🌧',
    '365': '🌧',
    '368': '🌨',
    '371': '❄️',
    '374': '🌧',
    '377': '🌧',
    '386': '⛈',
    '389': '🌩',
    '392': '⛈',
    '395': '❄️'
}

data = {}

try:
   # weather = requests.get("https://wttr.in/?format=j1").json()
    weather = requests.get("https://wttr.in/Istanbul?format=j1").json()
    
    def format_time(time):
        return time.replace("00", "").zfill(2)

    def format_temp(temp):
        return (hour['FeelsLikeC']+"°").ljust(3)

    def format_chances(hour):
        chances = {
            "chanceoffog": "Sis",
            "chanceoffrost": "Don",
            "chanceofovercast": "Bulutlu",
            "chanceofrain": "Yağmur",
            "chanceofsnow": "Kar",
            "chanceofsunshine": "Güneşli",
            "chanceofthunder": "Gök Gürültüsü",
            "chanceofwindy": "Rüzgarlı"
        }

        conditions = []
        for event in chances.keys():
            if int(hour[event]) > 0:
                conditions.append(f"{chances[event]} {hour[event]}%")
        return ", ".join(conditions)

    current = weather['current_condition'][0]
    temp = int(current['FeelsLikeC'])
    code = current['weatherCode']
    desc = current['weatherDesc'][0]['value']

    # Sıcaklığa göre renk belirleme
    if temp < 0:
        temp_color = "#89dceb"  # Soğuk - Açık Mavi
    elif temp < 10:
        temp_color = "#74c7ec"  # Serin - Mavi
    elif temp < 20:
        temp_color = "#89b4fa"  # Ilık - Lavanta
    elif temp < 30:
        temp_color = "#f9e2af"  # Sıcak - Sarı
    else:
        temp_color = "#f38ba8"  # Çok sıcak - Kırmızı

    data['text'] = f"{WEATHER_CODES[code]} {temp}°C"
    data['class'] = current['weatherDesc'][0]['value']
    
    tooltip = f"<span size='14000'>{desc}</span>\n"
    tooltip += f"🌡️ Sıcaklık: <span foreground='{temp_color}'>{temp}°C</span>\n"
    tooltip += f"💧 Nem: {current['humidity']}%\n"
    tooltip += f"🌪️ Rüzgar: {current['windspeedKmph']}km/s\n"
    tooltip += f"\nSaatlik Tahmin:\n"
    
    for hour in weather['weather'][0]['hourly']:
        if int(format_time(hour['time'])) > int(datetime.now().strftime("%H")):
            tooltip += f"\n{format_time(hour['time'])}:00 {WEATHER_CODES[hour['weatherCode']]} {format_temp(hour['FeelsLikeC'])} "
            
            chances = format_chances(hour)
            if chances:
                tooltip += f"\n  {chances}"
                
    data['tooltip'] = tooltip

except Exception as e:
    data['text'] = "❌"
    data['tooltip'] = f"wttr.in'e bağlanılamıyor\n{e}"

print(json.dumps(data))
