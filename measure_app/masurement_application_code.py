import psutil
import time
import csv
import threading
import subprocess

# Funkcja do znalezienia wszystkich procesów związanych z Dartem
def find_all_dart_processes():
    dart_processes = []
    for proc in psutil.process_iter(['pid', 'name', 'exe', 'cmdline']):
        try:
            # Sprawdzanie, czy proces jest związany z Dartem
            if 'dart' in proc.info['name'].lower():
                print(f"Znaleziono proces: {proc.info}")
                dart_processes.append(proc)
            elif 'cmdline' in proc.info and proc.info['cmdline']:
                # Sprawdzamy, czy cmdline istnieje i jest listą
                if 'dart' in ' '.join(proc.info['cmdline']).lower():
                    print(f"Znaleziono proces: {proc.info}")
                    dart_processes.append(proc)
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    return dart_processes

# Funkcja do zapisania danych do oddzielnego pliku CSV dla każdego procesu
def save_to_csv(process, data):
    pid = process.info['pid']
    filename = f'dart_process_{pid}_metrics.csv'
    with open(filename, mode='a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(data)

# Funkcja do zapisania danych o zużyciu energii do osobnego pliku
def save_power_usage_to_csv(power_data):
    filename = 'power_usage_metrics.csv'  # Plik przechowujący dane o zużyciu energii
    with open(filename, mode='a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow([time.strftime("%Y-%m-%d %H:%M:%S"), power_data])

# Funkcja do monitorowania zużycia energii
def get_power_usage():
    try:
        # Uruchamiamy powermetrics, aby uzyskać dane o zużyciu energii
        result = subprocess.run(['sudo', 'powermetrics', '--samplers', 'cpu_power'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode == 0:
            output = result.stdout.decode('utf-8')
            # Zapisujemy dane o zużyciu energii do osobnego pliku
            save_power_usage_to_csv(output)
            return output
        else:
            return "Błąd podczas uzyskiwania danych o zużyciu energii."
    except Exception as e:
        return str(e)

# Funkcja do monitorowania zasobów procesu
def monitor_process_and_save(process):
    print(f"Monitoring procesu: {process.info['name']} (PID: {process.info['pid']})")
    try:
        while process.is_running():
            # Pobieranie informacji o procesie
            cpu_percent = process.cpu_percent(interval=1)
            memory_info = process.memory_info()
            memory_percent = process.memory_percent()

            # Czas CPU
            user_time = process.cpu_times().user  # Czas użytkownika
            system_time = process.cpu_times().system  # Czas systemowy

            # Zużycie dysku (zabezpieczenie przed błędami)
            try:
                io_counters = process.io_counters()
                read_bytes = io_counters.read_bytes  # Liczba bajtów przeczytanych
                write_bytes = io_counters.write_bytes  # Liczba bajtów zapisanych
            except (psutil.AccessDenied, psutil.NoSuchProcess, AttributeError):
                read_bytes = write_bytes = 0  # W przypadku braku dostępu ustawiamy 0

            # Liczba otwartych plików
            try:
                open_files = len(process.open_files())
            except (psutil.AccessDenied, psutil.NoSuchProcess):
                open_files = 0  # W przypadku braku dostępu ustawiamy 0

            # Liczba wątków
            num_threads = process.num_threads()

            # Zbieranie danych do zapisania
            data = [
                time.strftime("%Y-%m-%d %H:%M:%S"),  # Czas zbierania danych
                cpu_percent,                         # Zużycie CPU w %
                memory_info.rss / 1024 ** 2,         # Zużycie pamięci (RSS) w MB
                memory_info.vms / 1024 ** 2,         # Pamięć wirtualna (VMS) w MB
                memory_percent,                      # Procentowe zużycie pamięci
                user_time,                           # Czas CPU użytkownika
                system_time,                         # Czas CPU systemu
                read_bytes,                          # Liczba przeczytanych bajtów
                write_bytes,                         # Liczba zapisanych bajtów
                open_files,                          # Liczba otwartych plików
                num_threads                          # Liczba wątków
            ]

            # Zapisz dane procesu do pliku
            save_to_csv(process, data)  # Zapisz dane do pliku dla konkretnego procesu
            print(f"Zapisano dane: {data}")  # Wyświetlanie danych na ekranie
            time.sleep(1)  # Zbieraj dane co sekundę
    except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
        print("Proces zakończony lub dostęp zabroniony!")

# Funkcja do monitorowania wielu procesów równolegle
def monitor_multiple_processes(dart_processes):
    threads = []
    for process in dart_processes:
        # Tworzenie nowego wątku dla każdego procesu
        thread = threading.Thread(target=monitor_process_and_save, args=(process,))
        threads.append(thread)
        thread.start()

    # Czekanie na zakończenie wszystkich wątków
    for thread in threads:
        thread.join()

# Funkcja do ciągłego monitorowania systemu
def continuously_monitor():
    known_processes = set()  # Set, aby śledzić już monitorowane procesy

    while True:
        # Znajdowanie nowych procesów Dart
        dart_processes = find_all_dart_processes()

        # Tworzenie listy nowych procesów, które nie były wcześniej monitorowane
        new_processes = [proc for proc in dart_processes if proc.info['pid'] not in known_processes]

        if new_processes:
            for process in new_processes:
                # Dodanie nowego procesu do śledzenia
                known_processes.add(process.info['pid'])
                # Rozpoczęcie monitorowania nowego procesu
                thread = threading.Thread(target=monitor_process_and_save, args=(process,))
                thread.start()

        # Czekanie na chwilę przed kolejnym sprawdzeniem
        time.sleep(1)  # Sprawdzaj co 1 sekundę, aby stale monitorować procesy

        # Dodatkowe monitorowanie energii co 5 sekund
        power_thread = threading.Thread(target=get_power_usage)
        power_thread.start()

# Główna część programu
if __name__ == "__main__":
    continuously_monitor()
