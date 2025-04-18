from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import occupancy, plugs, smartmeter

app = FastAPI()

# Dodaj middleware CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:56491", "http://127.0.0.1:56491"],  # Dodaj domeny, z których chcesz pozwolić na dostęp
    allow_credentials=True,
    allow_methods=["*"],  # Może być bardziej restrykcyjnie (np. tylko GET, POST)
    allow_headers=["*"],  # Może być bardziej restrykcyjnie (np. tylko niektóre nagłówki)
)

app.include_router(occupancy.router, prefix="/occupancy")
app.include_router(plugs.router, prefix="/plugs")
app.include_router(smartmeter.router, prefix="/smartmeter")
