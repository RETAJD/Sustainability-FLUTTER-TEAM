from fastapi import APIRouter, Query
from typing import List
import os
from typing import Dict
import pandas as pd


router = APIRouter()

DATA_DIR = "/Users/marcinretajczyk/development/Sustainability-FLUTTER-TEAM/backend-marcin/data/occupancy/"

@router.get("/{folder}/summer")
def get_summer_occupancy(interval: int = Query(15, description="Agregacja w minutach")):
    data = aggregate_csv("01_summer.csv", interval)
    return data

@router.get("/{folder}/winter")
def get_summer_occupancy(interval: int = Query(15, description="Agregacja w minutach")):
    data = aggregate_csv("01_winter.csv", interval)
    return data

def aggregate_csv(filename: str, interval: int) -> List[Dict]:
    # Wczytaj plik CSV
    df = pd.read_csv(os.path.join(DATA_DIR, filename), index_col=0)
    results = []

    seconds_per_interval = interval * 60
    num_intervals = 24 * 60 // interval

    for day, row in df.iterrows():
        values = row.values.astype(float)
        intervals = [
            values[i * seconds_per_interval : (i + 1) * seconds_per_interval].mean()
            for i in range(num_intervals)
        ]
        # Generowanie znaczników czasu
        times = [
            f"{str(h).zfill(2)}:{str(m).zfill(2)}"
            for h in range(24)
            for m in range(0, 60, interval)
        ]
        results.append({
            "date": day,
            "interval": f"{interval}min",
            "data": [
                {"time": t, "value": round(v, 2)}
                for t, v in zip(times, intervals)
            ]
        })
    return results