---
created: 2026-09-01
---

# Durations read as raw seconds — the kiosk shows `3900s` where people expect `1h 5m`

`formatDuration` in `duration.js` only appends `s`; anything over a minute is unreadable at a glance.
