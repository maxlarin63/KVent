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

## License

Use and modify as needed for your installation.
