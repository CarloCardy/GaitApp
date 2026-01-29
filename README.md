# GaitApp

Web app React Native per acquisizione IMU e analisi del gait.

## Avvio

```bash
npm install
npm run web
```

## Struttura

- `src/data`: DAO e sorgenti dati (TXT simulato + Bluetooth).
- `src/algorithms`: porting dei metodi MATLAB (conversione matrici, segmentazione, picchi).
- `src/processing`: pipeline per orchestrare le fasi di analisi.
