from fastapi import APIRouter, Query
from fastapi.responses import JSONResponse
from pathlib import Path
import pandas as pd
from typing import List, Dict
import os

router = APIRouter()

# Dostępne opisy danych
DATA_DESCRIPTIONS = {
    "powerallphases": "Sum of real power over all phases",
    "powerl1": "Real power phase 1",
    "powerl2": "Real power phase 2",
    "powerl3": "Real power phase 3",
    "currentneutral": "Neutral current",
    "currentl1": "Current phase 1",
    "currentl2": "Current phase 2",
    "currentl3": "Current phase 3",
    "voltagel1": "Voltage phase 1",
    "voltagel2": "Voltage phase 2",
    "voltagel3": "Voltage phase 3",
    "phaseanglevoltagel2l1": "Phase shift between voltage on phase 2 and 1",
    "phaseanglevoltagel3l1": "Phase shift between voltage on phase 3 and 1",
    "phaseanglecurrentvoltagel1": "Phase shift between current/voltage on phase 1",
    "phaseanglecurrentvoltagel2": "Phase shift between current/voltage on phase 2",
    "phaseanglecurrentvoltagel3": "Phase shift between current/voltage on phase 3"
}

BASE_DIR = Path("/Users/marcinretajczyk/development/Sustainability-FLUTTER-TEAM/backend-marcin/data/sm")

def aggregate(values: List[float], interval: int) -> List[float]:
    # Agreguje listę wartości do podanego interwału (w minutach)
    if not values:
        return []

    seconds_per_interval = interval * 60
    if len(values) % seconds_per_interval != 0:
        # Zaokrąglamy w dół liczbę próbek, aby była podzielna przez interwał
        valid_samples = len(values) - (len(values) % seconds_per_interval)
        values = values[:valid_samples]

    num_intervals = len(values) // seconds_per_interval
    aggregated_values = [
        float(pd.Series(values[i*seconds_per_interval:(i+1)*seconds_per_interval]).mean())
        for i in range(num_intervals)
    ]
    return aggregated_values

def get_time_labels(interval: int) -> List[str]:
    # Generuje etykiety czasu dla podanego interwału
    minutes_in_day = 24 * 60
    num_intervals = minutes_in_day // interval
    return [f"{h:02d}:{m:02d}" for i in range(num_intervals)
            for h in [i * interval // 60]
            for m in [i * interval % 60]]

@router.get("/{data_type}")
def get_smart_meter_data(
    data_type: str,
    interval: int = Query(15, title="Interval in minutes", description="Aggregation interval in minutes")
):
    if data_type not in DATA_DESCRIPTIONS:
        return JSONResponse(status_code=400, content={"error": "Invalid data type."})

    description = DATA_DESCRIPTIONS[data_type]
    results = []

    for csv_file in sorted(BASE_DIR.glob("*.csv")):
        date_str = csv_file.stem  # np. 2012-06-01

        try:
            df = pd.read_csv(csv_file, header=None)
            # Pobierz kolumnę danych (indeks 0 to powerallphases, 1 to powerl1, itd.)
            data_column = df.iloc[:, list(DATA_DESCRIPTIONS.keys()).index(data_type)].tolist()
            # Zamień "-1" na wartość NaN
            data_column = [float(x) if str(x) != "-1" else float('nan') for x in data_column]
            # Wypełnij brakujące wartości (NaN) średnią z pozostałych
            data_column = pd.Series(data_column).fillna(pd.Series(data_column).mean()).tolist()

        except Exception as e:
            print(f"Error reading or processing {csv_file}: {e}")
            continue  # Pomiń ten plik, jeśli wystąpił błąd

        agg_values = aggregate(data_column, interval)
        time_labels = get_time_labels(interval)

        # Upewnij się, że liczba etykiet czasu odpowiada liczbie zagregowanych wartości
        min_len = min(len(time_labels), len(agg_values))
        data = [{"time": t, "value": v} for t, v in zip(time_labels[:min_len], agg_values[:min_len])]

        results.append({
            "date": date_str,
            "description": description,
            "interval": f"{interval}min",
            "data": data
        })

    return JSONResponse(content=results)