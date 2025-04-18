from fastapi import APIRouter, Query
from fastapi.responses import JSONResponse
from pathlib import Path
import pandas as pd
from typing import List


router = APIRouter()

# Mapowanie device_id -> description
DEVICE_DESCRIPTIONS = {
    "01": "Fridge",
    "02": "Dryer",
    "03": "Coffee machine",
    "04": "Kettle",
    "05": "Washing machine",
    "06": "PC",
    "07": "Freezer",
}

#01: Fridge (no. days: 231, coverage: 98.53%)
#02: Dryer (no. days: 231, coverage: 98.56%)
#03: Coffee machine (no. days: 113, coverage: 85.36%)
#04: Kettle (no. days: 203, coverage: 77.65%)
#05: Washing machine (no. days: 231, coverage: 98.56%)
#06: PC (no,. days: 66, coverage: 84.77%) (*)
#07: Freezer (no. days: 231, coverage: 98.56%)

BASE_DIR = Path("/Users/marcinretajczyk/development/Sustainability-FLUTTER-TEAM/backend-marcin/data/plugs/")  # lub inna ścieżka bazowa

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

@router.get("/{folder}/{device_id}")
def get_device_data(
    folder: str,
    device_id: str,
    interval: int = Query(15, title="Interval in minutes", description="Aggregation interval in minutes")
):
    device_path = BASE_DIR / device_id
    if not device_path.exists():
        return JSONResponse(status_code=404, content={"error": "Device folder not found."})

    description = DEVICE_DESCRIPTIONS.get(device_id, "Unknown")
    results = []

    for csv_file in sorted(device_path.glob("*.csv")):
        date_str = csv_file.stem  # np. 2012-06-01
        # Wczytaj dane z pliku CSV (jeden float na linię)
        with open(csv_file, "r") as f:
            values = [float(line.strip()) for line in f if line.strip()]

        if not values:
            continue  # Pomiń puste pliki

        agg_values = aggregate(values, interval)
        time_labels = get_time_labels(interval)

         # Upewnij się, że liczba etykiet czasu odpowiada liczbie zagregowanych wartości
        min_len = min(len(time_labels), len(agg_values))
        data = [{"time": t, "value": v} for t, v in zip(time_labels[:min_len], agg_values[:min_len])]

        results.append({
            "device": device_id,
            "description": description,
            "date": date_str,
            "interval": f"{interval}min",
            "data": data
        })

    return JSONResponse(content=results)