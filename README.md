# PlatzFrei

Multiuser-Applikation zur **konfliktfreien Reservierung von Sportplätzen** in einem Verein.
Modul **M233 – Multiuser-Applikation entwickeln** · Autor: **Leandro Fragale** (Klasse 24E).

Vereinsmitglieder reservieren Zeitfenster auf Sportplätzen ohne Doppelbuchung; Platzverantwortliche behalten den Überblick über Belegung, Sperrungen und Konflikte.

## Dokumentation

- **[Anleitung.md](Anleitung.md)** – Setup, Start und vollständiges Testprotokoll (automatisiert + manuell).
- **[Kompetenzen.md](Kompetenzen.md)** – Abgleich mit dem Bewertungsraster (was ist umgesetzt, wie testen, Status).
- **[CLAUDE.md](CLAUDE.md)** – Architektur, Domäne, Locking- & Transaktionsstrategie.
- **[docs/projektantrag_sportplatz.md](docs/projektantrag_sportplatz.md)** – Projektantrag inkl. Domänenmodell (ERM).

## Schnellstart

```bash
bin/setup --skip-server   # Gems, Datenbank und Demo-Daten
bin/dev                   # Server starten -> http://localhost:3000
```

Demo-Konten (Passwort `geheim123`): `mitglied@platzfrei.ch` (Mitglied) · `admin@platzfrei.ch` (Platzverantwortliche/r).

## Tech-Stack

Ruby 4.0.6 · Rails 8.1 · SQLite3 · Hotwire (Turbo/Stimulus) · Import Maps · Tailwind CSS · **kein Node/Redis**.

## Tests

```bash
bin/rails test   # 94 Tests (Models + Controller), inkl. Nebenläufigkeit/Locking
bin/rubocop      # Code-Konventionen (Rails Omakase)
bin/ci           # kompletter CI-Lauf (Setup, Rubocop, Audits, Brakeman, Tests, Seeds)
```
