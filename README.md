# PlatzFrei

Multiuser-Applikation zur **konfliktfreien Reservierung von Sportplätzen** in einem Verein.
Modul **M233 – Multiuser-Applikation entwickeln** · Autor: **Leandro Fragale** (Klasse 24E).

Vereinsmitglieder reservieren Zeitfenster auf Sportplätzen ohne Doppelbuchung; Platzverantwortliche behalten den Überblick über Belegung, Sperrungen und Konflikte.

Die vollständige fachliche Dokumentation (Problemstellung, Vision, Anforderungen, Qualitätsattribute, ERM, Breadboards, Wireframes, Locking-Konzept, erreichter Stand) liegt in **[docs/dokumentation.md](docs/dokumentation.md)**.

## Voraussetzungen

| | |
|---|---|
| Sprache | Ruby **4.0.6** |
| Framework | Ruby on Rails **8.1** |
| Datenbank | **SQLite3** (Datei-basiert, keine Server-Installation nötig) |
| Frontend | Hotwire (Turbo/Stimulus) + Import Maps + Tailwind CSS – **kein Node/npm nötig** |

Es wird keine zusätzliche Infrastruktur benötigt (kein Redis, keine externen Dienste).

## Installation & Konfiguration

```bash
bin/setup --skip-server   # Gems installieren, Datenbank anlegen, Demo-Daten laden
bin/dev                   # Server starten -> http://localhost:3000
```

Keine weitere Konfiguration nötig; die App läuft mit den Standardwerten aus `config/`.

## Datenbankaufbau & Demo-Daten

`bin/setup` (bzw. `bin/rails db:seed`) legt automatisch an:

- 5 Sportplätze (Fussballfeld, Badmintonhalle, Tennisplatz 1, Basketballplatz, Volleyballfeld), je mit 4 Zeitfenstern pro Tag über die nächsten 7 Tage
- Zwei Demo-Konten (siehe unten)

Demo-Daten erneut laden: `bin/rails db:seed` (idempotent). Datenbank komplett zurücksetzen: `bin/setup --reset`.

### Demo-Konten

| Rolle | E-Mail | Passwort |
|---|---|---|
| Vereinsmitglied | `mitglied@platzfrei.ch` | `geheim123` |
| Platzverantwortliche/r | `admin@platzfrei.ch` | `geheim123` |

## Start- und Testbefehle

```bash
bin/dev          # Server starten (inkl. Tailwind-Watcher) -> http://localhost:3000
bin/rails test   # Testsuite: 111 Tests, 329 Assertions, 0 Fehler
bin/rubocop      # Code-Konventionen (Rails Omakase): 70 Dateien, keine Beanstandungen
bin/ci           # kompletter CI-Lauf (Setup, Rubocop, Audits, Brakeman, Tests, Seeds)
```
