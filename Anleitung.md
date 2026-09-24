# Anleitung – PlatzFrei testen & betreiben

Projekt: **PlatzFrei** (Sportplatz-Reservierung) · Modul **M233 – Multiuser-Applikation entwickeln** · Autor: **Leandro Fragale** · Klasse 24E

Diese Anleitung zeigt, wie man die Applikation startet und **Schritt für Schritt prüft, dass alles funktioniert** – sowohl automatisiert (Testsuite) als auch manuell im Browser. Für den Abgleich mit dem Kompetenzraster siehe [`Kompetenzen.md`](Kompetenzen.md).

---

## 1. Voraussetzungen

| | |
|---|---|
| Sprache | Ruby **4.0.6** |
| Framework | Ruby on Rails **8.1** |
| Datenbank | **SQLite3** (Datei-basiert, keine Server-Installation nötig) |
| Frontend | Hotwire (Turbo/Stimulus) + Import Maps + Tailwind CSS – **kein Node/npm nötig** |

Es wird **keine** zusätzliche Infrastruktur benötigt (kein Redis, keine externen Dienste).

---

## 2. Setup & Start

```bash
# 1. Einmalig: Gems installieren, Datenbank anlegen + Demo-Daten laden
bin/setup --skip-server

# 2. Server starten (inkl. Tailwind-Watcher)
bin/dev
```

Die App läuft danach auf **http://localhost:3000**.

Falls die Demo-Daten fehlen oder neu geladen werden sollen:

```bash
bin/rails db:seed          # Sportplätze, Zeitfenster (7 Tage) und Demo-Konten
```

### Demo-Konten (nur Entwicklung)

| Rolle | E-Mail | Passwort |
|---|---|---|
| Vereinsmitglied | `mitglied@platzfrei.ch` | `geheim123` |
| Platzverantwortliche/r | `admin@platzfrei.ch` | `geheim123` |

Die Seeds legen 5 Sportplätze an (Fussballfeld, Badmintonhalle, Tennisplatz 1, Basketballplatz, Volleyballfeld) mit je 4 Zeitfenstern pro Tag über die nächsten 7 Tage.

---

## 3. Automatisierte Tests

Der schnellste Nachweis, dass die Kernlogik korrekt ist:

```bash
bin/rails test        # komplette Testsuite (94 Tests: Models + Controller)
bin/rubocop           # Code-Konventionen (Rails Omakase) – 0 Offenses erwartet
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error   # Security-Analyse
bin/ci                # kompletter CI-Lauf (Setup, Rubocop, Audits, Brakeman, Tests, Seeds)
```

Erwartetes Ergebnis von `bin/rails test`:

```
94 runs, 262 assertions, 0 failures, 0 errors, 0 skips
```

### Locking-Nachweis gezielt ausführen (wichtig für „Transaktionen und Locking")

Die Nebenläufigkeit wird deterministisch getestet, ohne echte Threads (zwei geladene Referenzen auf dieselbe Zeile simulieren zwei gleichzeitige Benutzer):

```bash
# Doppelbuchung bei neuer Reservierung -> partieller Unique-Index (RecordNotUnique)
bin/rails test test/models/zeitfenster_test.rb

# Stornierung (Mitglied) vs. Sperrung (Admin) auf DERSELBEN Reservierung
#   -> Optimistic Locking (lock_version) -> StaleObjectError für den späteren Schreibzugriff
bin/rails test test/models/sportplatz_test.rb
```

Relevante Testfälle:
- `zeitfenster_test.rb` → *„konkurrierende Reservierung desselben Zeitfensters: nur die erste gelingt (Unique-Index)"*
- `sportplatz_test.rb` → *„QA5: Stornierung (Mitglied) vs. Sperrung (Admin) … wirft StaleObjectError"*
- `sportplatz_test.rb` → *„QA5: storniert ein Mitglied zuerst, bricht eine gleichzeitige Sperrung nicht ab"*

Details zur Locking-Strategie stehen als Code-Kommentare in `app/models/zeitfenster.rb`, `app/models/reservierung.rb`, `app/models/sportplatz.rb` sowie in `CLAUDE.md` (Abschnitt „Locking & transactions").

---

## 4. Manuelles Testprotokoll (Browser)

Reihenfolge zum Durchklicken. Abhaken, was funktioniert.

### 4.1 Authentifizierung
1. `http://localhost:3000` öffnen → Startseite mit „Anmelden / Konto erstellen".
2. **Registrieren**: „Konto erstellen" → Formular mit ungültigen Daten (z. B. Passwort < 8 Zeichen) absenden → **Fehlermeldung direkt unter dem Feld**.
3. Mit gültigen Daten registrieren → automatisch angemeldet, Weiterleitung auf Startseite.
4. **Abmelden** (Header) → zurück zur Gast-Ansicht.
5. **Anmelden** mit falschem Passwort → rote Fehlermeldung „E-Mail oder Passwort ungültig."
6. Mit `mitglied@platzfrei.ch` / `geheim123` anmelden.

### 4.2 Benutzerprofil
1. Header → **Profil** → eigene Daten werden angezeigt (Name, E-Mail, Rolle).
2. **Bearbeiten** → Name ändern → Speichern → Änderung sichtbar.
3. (Nur eigenes Profil ist bearbeitbar – es gibt keinen Weg, ein fremdes Profil zu bearbeiten.)

### 4.3 Kernfunktion: Platzübersicht & Reservieren
1. Header → **Plätze**.
2. **Kalender**: Monat mit Pfeilen wechseln, einen Tag anklicken → Liste aktualisiert sich für dieses Datum. Vergangene Tage sind ausgegraut/nicht wählbar.
3. **Sportart-Filter**: oben rechts eine Sportart anklicken → Liste zeigt nur diese Sportart.
4. **Gruppierung**: die Zeitfenster sind pro Sportplatz gruppiert (alle Zeiten eines Platzes untereinander), jede Sportart hat einen eigenen Farbton.
5. Bei einem **freien** Slot auf **Details** → **Jetzt reservieren** → Bestätigungsdialog → bestätigen → Weiterleitung zu „Meine Reservierungen", Slot ist jetzt **Reserviert** (rotes Badge).

### 4.4 Konfliktfreiheit (Doppelbuchung) – 2 Browser
1. In **Browser A** (Mitglied) und **Browser B** (z. B. Inkognito, mit dem Admin-Konto) dieselbe Slot-Detailseite öffnen.
2. In A reservieren → erfolgreich.
3. In B ohne Neuladen ebenfalls „Jetzt reservieren" → **Fehlermeldung** „… wurde inzwischen von jemand anderem reserviert. Nächstes freies Zeitfenster: …".
   → Genau **eine** Reservierung wird bestätigt (durchgesetzt durch den DB-Unique-Index).

### 4.5 Meine Reservierungen & Stornierung
1. Header → **Meine Reservierungen** → gebuchte Slots + Warteliste.
2. Bei einer Buchung **Stornieren** → Bestätigungsdialog → storniert; der Slot ist wieder frei.
3. Ist die Liste leer, erscheint ein freundlicher Leerzustand statt einer leeren Tabelle.

### 4.6 Warteliste (FR7)
1. Als Mitglied einen **belegten** Slot öffnen → **Auf Warteliste setzen**.
2. Den Slot (durch den Bucher oder Admin) **stornieren** lassen.
3. Als wartendes Mitglied „Meine Reservierungen" neu laden → Warteliste-Eintrag zeigt **„Jetzt frei!"** + Direktlink zum Reservieren.

### 4.7 Rollen & Berechtigungen
1. Als **Mitglied** angemeldet `http://localhost:3000/admin/benutzer` aufrufen → Weiterleitung auf Startseite mit „Kein Zugriff." (Der Verwaltungsbereich ist nur für Platzverantwortliche.)
2. Der Header zeigt für Mitglieder **keine** „Verwaltung".

### 4.8 Admin-Bereich (als `admin@platzfrei.ch`)
1. **Verwaltung** im Header → dunkle Konsolen-Leiste erscheint.
2. **Benutzer**: Liste aller Benutzer, Detailansicht.
3. **Reservierungen**: alle aktiven Reservierungen; eine fremde Reservierung **stornieren** (z. B. bei Missbrauch).
4. **Protokoll**: Aktivitätsprotokoll mit Zeitpunkt, Aktion (erstellt/storniert/geschlossen), Akteur, Mitglied, Sportplatz.
5. **Platz sperren**: Sportplatz + Zeitraum wählen → sperren. Bestehende Reservierungen in diesem Zeitraum werden **automatisch storniert** und im Protokoll als „geschlossen" festgehalten.

### 4.9 Konsistenz Stornierung ↔ Sperrung (QA5, manuell)
1. Ein Mitglied hat einen Slot reserviert; „Meine Reservierungen" offen lassen.
2. Als Admin denselben Platz/Zeitraum **sperren** → Reservierung wird storniert.
3. Das Mitglied klickt jetzt (auf der veralteten Seite) **Stornieren** → freundliche Meldung „Diese Reservierung wurde inzwischen bereits storniert (z. B. durch eine Platzsperrung)." – **kein** Absturz, keine doppelte Stornierung.
   → Der automatisierte Nachweis dafür ist der `StaleObjectError`-Test in `sportplatz_test.rb`.

---

## 5. Häufige Handgriffe

```bash
bin/rails test test/models/sportplatz_test.rb   # einzelne Testdatei
bin/rails console                               # Rails-Konsole (Daten inspizieren)
bin/rails db:seed                               # Demo-Daten (idempotent) neu laden
bin/setup --reset                               # Datenbank komplett zurücksetzen + neu seeden
```

---

## 6. Fehlerbehebung

- **Port 3000 belegt:** einen anderen Server beenden oder `bin/rails server -p 3001`.
- **Schriftarten/Styles fehlen:** die App nutzt einen System-Font (Helvetica-Stack) und lädt keine externen Fonts – ein einmaliges `bin/rails tailwindcss:build` baut das CSS neu.
- **Keine Zeitfenster sichtbar:** ein Datum in den nächsten 7 Tagen wählen; ggf. `bin/rails db:seed` ausführen.
