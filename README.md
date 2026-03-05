# KVent

Fibaro QuickApp for controlling and monitoring a **Komfovent C4** ventilation unit via **Modbus TCP**. Runs on **Fibaro Home Center 3** (HC3).

---

## Hardware

```
Fibaro HC3  ←→  Ethernet switch  ←→  Komfovent PING2 (network module)  ←→  Komfovent C4 (controller)
```

- **HC3** – Fibaro Home Center 3 (runs the QuickApp).
- **Ethernet switch** – Connects HC3 and the ventilation system on the same LAN.
- **Komfovent PING2** – Network gateway that exposes the C4 over Modbus TCP.
- **Komfovent C4** – Ventilation unit controller (actual I/O and logic).

The QuickApp talks to the **PING2** at a fixed IP/port; the PING2 forwards Modbus to the C4.

---

## Functionality

### Communication

- **Modbus TCP** client: connects to the PING2’s IP, reads/writes holding registers.
- **Polling**: every 15 seconds, all defined registers are read (block reads where possible).
- **Writes**: Power, season, mode, and manual speed are written when the user acts (main UI or child switches); GUI updates immediately (optimistic), then is corrected by the next poll.

### Registers (summary)

| Area        | Registers | Purpose |
|------------|-----------|---------|
| Power      | 1000      | Unit ON/OFF |
| Season     | 1001      | Winter / Summer |
| Service    | 1007      | Service warning (bit 14) |
| Speed      | 1100, 1101| Manual setpoint (1100), current speed (1101): Standby, Level 1–3, Boost |
| Mode       | 1102      | Manual / Auto |
| Temperatures | 1200, 1201 | Supply temperature, setpoint (°C) |

### QuickApp UI

- **Labels**: Power, Season, Service, current Speed, Mode, and temperatures.
- **Buttons**: Power On/Off, Winter/Summer, Auto/Manual, Speed 1–3.
- **Device sync**: Creates child devices (switches, temperature sensors) from the register map.

### Child devices

- **Binary switches** (Power, Season, Auto mode): turn On/Off; each maps to one register.
- **Temperature sensors**: supply and setpoint temperatures; values updated from polled registers.

### Configuration (QuickApp variables)

- **device_ip** – IP of the Komfovent PING2 (required).
- **device_port** – Modbus TCP port (default 502).
- **debug** – Set to `true` or `"true"` to enable extra trace/debug logs (registers and Modbus).

---

## Project structure

- `main.lua` – QuickApp entry, device map, polling loop, button handlers, UI label helpers.
- `files/ModbusClient.lua` – Modbus TCP client (connect, read/write queue, block reads, frame build/parse).
- `files/Registers.lua` – Register definitions and read callbacks (labels and child updates).
- `files/Queue.lua` – FIFO queue for write requests.
- `files/utils.lua` – Binary helpers (e.g. read_unsigned_i16, read_signed_i16, convert_hex).
- `files/setup.lua` – Device tree setup (create child switches and sensors).
- `files/KomfoChild.lua`, `KomfoBinarySwitch.lua`, `KomfoSensor.lua` – Child device classes.

---

## Building

The `.fqa` package for this QuickApp is built with the [fqa](https://github.com/maxlarin63/fqa) tool (pack Fibaro QuickApp from a project layout).

- **CI:**
  - If you add a GitHub Actions workflow to build the `.fqa`, configure the step that checks out the fqa tool to use a tagged release (e.g. `ref: v1.0.0`) so CI uses a known tool version.
- **Local (direct fqa):**
  - Clone the fqa repo.
  - From this repo run: `python /path/to/fqa/fqa.py pack .` (output: `KVent.fqa` in the current directory).
  - To see which fqa version you are using, run `python /path/to/fqa/fqa.py --version` (or `fqa --version` if installed on PATH).
- **Local (via `fqa-pack` from this project):**
  - Make sure `.fqa-tool-path` points to your `fqa` command (for example: `python "D:\HomeAutomation\fqa\fqa.py"`).
  - From this repo run:
    - `python fqa-pack.py -y -o dist` (cross‑platform), or
    - `fqa-pack.bat -y -o dist` on Windows.
  - The built `.fqa` will be placed under `dist\`.

## License

Use and modify as needed for your installation.
