# Kompetenzen – Abgleich mit dem Bewertungsraster

Projekt: **PlatzFrei** · Modul **M233** · Autor: **Leandro Fragale** (Klasse 24E)

Diese Datei gleicht die Applikation mit dem offiziellen Bewertungsraster ab: **was** ist umgesetzt, **wo** im Code, **wie** man es prüft und die **Selbsteinschätzung**.

**Bewertungsregel (laut Raster):** `0 = nicht erfüllt`, `1 = teilweise erfüllt`, `2 = erfüllt`. Maximal 42 Punkte.
**Legende Selbsteinschätzung:** ✅ = im Code nachweisbar umgesetzt · 🟡 = teilweise/mit Einschränkung · ⚪ = nicht Teil der Applikation (Präsentation/Prüfung/Sozialkompetenz).

Setup- und Testschritte im Detail: siehe [`Anleitung.md`](Anleitung.md).

---

## 1. Projektqualität (max. 8 Punkte)

| Kompetenz | Umsetzung im Projekt | Wie testen/prüfen | Selbst­einschätzung |
|---|---|---|---|
| Dokumentation & sinnvoller Einsatz von Dokumentationstools | `docs/projektantrag_sportplatz.md` (Antrag inkl. ERM), `CLAUDE.md` (Architektur, Locking, Domäne), `README.md`, `Anleitung.md`, `Kompetenzen.md`, saubere Git-History mit sprechenden Commits | Dateien lesen; `git log --oneline` | ✅ |
| Konventionen beachtet (Code, Dateinamen, Frameworks) | Rails-Konventionen durchgängig, RuboCop **Rails Omakase** ohne Offenses, konsistente deutsche Domänen-Benennung, Import Maps statt Node | `bin/rubocop` (0 Offenses) | ✅ |
| Applikation ist lauffähig & entspricht der Doku | Start via `bin/setup` / `bin/dev`, Verhalten deckt sich mit dieser Anleitung | `bin/dev` → http://localhost:3000 durchklicken | ✅ |
| Abschlusspräsentation | – | mündlich am Prüfungstag | ⚪ |

---

## 2. Domänenmodell und Architektur (max. 4 Punkte)

| Kompetenz | Umsetzung im Projekt | Wie testen/prüfen | Selbst­einschätzung |
|---|---|---|---|
| Domänenspezifische Fachbegriffe verwendet | Modelle/Begriffe konsequent aus der Domäne: `Benutzer`, `Sportplatz`, `Zeitfenster`, `Reservierung`, `Protokoll`, `Warteliste`; Rollen `Vereinsmitglied` / `Platzverantwortliche/r` | `app/models/`, `docs/projektantrag_sportplatz.md`, `CLAUDE.md` | ✅ |
| Datenbankmodell | 6 Tabellen mit Fremdschlüsseln, Enums (`status`, `rolle`, `aktion`), **partieller Unique-Index** auf `reservierungen`, `lock_version`-Spalten, Constraint gegen überlappende Zeitfenster (Model-Validierung) | `db/schema.rb`; `bin/rails dbconsole` | ✅ |

---

## 3. Multi-User-Applikation (max. 18 Punkte)

| Kompetenz | Umsetzung im Projekt | Wie testen/prüfen | Selbst­einschätzung |
|---|---|---|---|
| Authentifizierung | `has_secure_password` (bcrypt), Registrierung/Login/Logout, Session-basiert, Rate-Limit auf Login (Brute-Force-Schutz) | `test/controllers/sitzungen_*` & `registrierungen_*`; manuell 4.1 | ✅ |
| Benutzerrollen und Berechtigungen | Rollen-Enum `mitglied`/`verantwortlicher`; `require_login` + `require_verantwortlicher`; `Admin::`-Namespace für Verantwortliche gesperrt | `test/controllers/admin/*`; manuell 4.7 (`/admin/...` als Mitglied → „Kein Zugriff") | ✅ |
| Benutzerprofil | `ProfilController` (show/edit/update), nur eigenes Profil editierbar | `test/controllers/profil_controller_test.rb`; manuell 4.2 | ✅ |
| Benutzerverwaltung | `Admin::BenutzerController` (Liste + Detailansicht aller Benutzer) | `test/controllers/admin/benutzer_controller_test.rb`; manuell 4.8 | ✅ |
| **Transaktionen und Locking** | **Doppelbuchung (INSERT):** partieller Unique-Index → `RecordNotUnique`. **Stornierung vs. Sperrung (UPDATE derselben Reservierung):** Optimistic Locking über `lock_version` → `StaleObjectError`. Atomare Transaktionen für Reservierung+Protokoll und Sperrung+Stornierungen+Protokoll; Savepoint-Skip in `Sportplatz#sperren!` | `bin/rails test test/models/zeitfenster_test.rb test/models/sportplatz_test.rb`; manuell 4.4 & 4.9 | ✅ |
| Aktivitätsprotokoll | `Protokoll`-Model; jede Erstellung/Stornierung/Sperrung wird mit Zeitpunkt + Akteur protokolliert; Admin-Ansicht | `test/controllers/admin/protokolle_controller_test.rb`; manuell 4.8 (Punkt 4) | ✅ |
| Fehlerbehandlung und User Feedback | Flash-Meldungen (Erfolg/Fehler/Info), Formularfehler direkt am Feld, Konflikthinweis mit **nächstem freiem Slot**, freundliche `StaleObjectError`-Meldung, „Platz gesperrt"-Hinweis, 404 bei fremder Reservierung, Rate-Limit-Meldung, Leerzustände | manuell 4.1/4.4/4.5/4.9; Controller-Tests | ✅ |
| Testing | 94 automatisierte Tests (Models + Controller), inkl. **Nebenläufigkeits-Tests** für die Qualitätsattribute (Unique-Index, `StaleObjectError`) und ein N+1-/Performance-Test | `bin/rails test` (94 runs, 0 failures) | ✅ |
| Kernfunktion (Domänen-Funktionalität + UI) | Platzübersicht mit **Kalender** (Monatsnavigation), **Sportart-Filter**, **Gruppierung pro Sportplatz** mit eigenem Farbton; Reservierung mit Bestätigungsdialog; „Meine Reservierungen" mit Stornierung; **Warteliste**; Platzsperrung mit Auto-Stornierung; responsive „Liquid-Glass"-UI | manuell 4.3–4.6, 4.8 | ✅ |

---

## 4. Sozialkompetenz (max. 2 Punkte)

| Kompetenz | Umsetzung im Projekt | Wie testen/prüfen | Selbst­einschätzung |
|---|---|---|---|
| Arbeits- und Terminverhalten (Verspätungen: 0) | Nicht Teil des Codes; kontinuierliche Arbeit ist in der Git-History nachvollziehbar | `git log` | ⚪ |

---

## 5. Schriftliche Einzelprüfung / Online-Test (max. 10 Punkte)

| Kompetenz | Umsetzung im Projekt | Wie testen/prüfen | Selbst­einschätzung |
|---|---|---|---|
| Verständnisfragen | Nicht Teil der Applikation; separater Online-Test | am Prüfungstag | ⚪ |

---

## Überblick der Qualitätsattribute (aus dem Projektantrag)

| # | Qualitätsattribut | Umsetzung | Nachweis |
|---|---|---|---|
| QA1 | Datenkonsistenz (keine Doppelbuchung) | Partieller Unique-Index auf `reservierungen (zeitfenster_id) WHERE status='reserviert'` | `zeitfenster_test.rb`, `reservierung_test.rb`; manuell 4.4 |
| QA2 | Aktualität (reservierter Slot verschwindet) | Server rendert immer den aktuellen DB-Stand; belegte/gesperrte Slots fallen aus dem `frei`-Scope | manuell 4.3/4.4 (Slot ist nach Reload „Reserviert") |
| QA3 | Performance (Übersicht ohne N+1) | `includes(:sportplatz, :reservierungen)`, gruppiert ohne Zusatz-Queries | N+1-Test in `zeitfenster_controller_test.rb` |
| QA4 | Nachvollziehbarkeit (Audit) | `Protokoll` für erstellt/storniert/geschlossen mit Zeitpunkt + Akteur | `sportplatz_test.rb`, Admin-Protokoll-Ansicht |
| QA5 | Konsistenz Stornierung ↔ Sperrung | Optimistic Locking (`lock_version` auf `reservierungen`) → `StaleObjectError`, sauber behandelt | `sportplatz_test.rb`; manuell 4.9 |

---

## Schnell-Nachweis in einem Durchlauf

```bash
bin/rubocop            # Konventionen
bin/rails test         # 94 Tests, 0 Fehler (inkl. Locking/Concurrency)
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error   # Security
bin/dev                # App live durchklicken (siehe Anleitung.md, Abschnitt 4)
```
