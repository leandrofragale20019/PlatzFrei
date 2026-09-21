# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Nebenläufigkeit: Optimistic vs. Pessimistic Locking

Sowohl die Einzelreservierung (`Zeitfenster#reserviert_von!`) als auch die
Platzsperrung (`Sportplatz#sperren!`) lösen ihre Nebenläufigkeitsprobleme
einheitlich über Rails' Optimistic Locking (`lock_version` auf
`Zeitfenster`): beide Operationen "berühren" dasselbe Zeitfenster-Row per
`touch`/`update!`, wodurch ein zeitgleicher Konflikt automatisch als
`ActiveRecord::StaleObjectError` erkannt wird — unabhängig davon, welche der
beiden Operationen zuerst committet. Bei einem Konflikt scheitert die
gesamte Transaktion und muss erneut versucht werden (bei der Reservierung:
sofortige Fehlermeldung mit Vorschlag des nächsten freien Zeitfensters; bei
der Sperrung: Fehlermeldung an den Manager, erneut versuchen).

Die diskutierte Alternative wäre pessimistisches Locking gewesen (SQLite
`BEGIN IMMEDIATE`), das den Konflikt von vornherein durch Blockieren
verhindert, statt ihn per Rollback+Retry aufzulösen. Dagegen spricht: Eine
Platzsperrung betrifft potenziell viele Zeitfenster auf einmal und würde bei
`BEGIN IMMEDIATE` die Schreibsperre für die gesamte Dauer der Sperrung
halten — das bremst den deutlich häufigeren Reservierungs-Hotpath aus, nur
um den seltenen, manuell vom Manager ausgelösten Sperrungsfall etwas
komfortabler zu machen. Für diese App ist Optimistic Locking daher die
bessere Priorisierung.

## Qualitätsattribute → Tests

| Qualitätsattribut | Tests |
|---|---|
| 1. Datenkonsistenz (Concurrency) | `test/models/zeitfenster_test.rb` |
| 2. Aktualität (Freshness) | `test/controllers/zeitfenster_controller_test.rb` |
| 3. Performance | `test/controllers/zeitfenster_controller_test.rb` (Einzel-Request, deterministisch) + `script/lasttest_platzuebersicht.rb` (20 gleichzeitige Anfragen gegen einen laufenden Server, manuell wiederholbar) |
| 4. Nachvollziehbarkeit (Audit-Log) | `test/models/{zeitfenster,reservierung}_test.rb`, `test/controllers/admin/protokolle_controller_test.rb` |
| 5. Konsistenz bei Sperrungen | `test/models/sportplatz_test.rb` |
| Rollen-Zugriff auf `Admin::` | `test/controllers/admin/*_test.rb` (je Controller: ohne Login, als Mitglied, als Verantwortliche/r) |
| FR7 Warteliste-Benachrichtigung | `test/controllers/reservierungen_controller_test.rb` |

Das Lastskript für QA3 läuft gegen einen laufenden Dev-Server (nicht Teil von `bin/rails test`, um zeitbasierte Flakiness aus der CI-Suite herauszuhalten):

```
RAILS_MAX_THREADS=20 bin/rails server
ruby script/lasttest_platzuebersicht.rb <E-Mail> <Passwort>
```

**Befund:** Mit dem Standard-Dev-Setup (`config/puma.rb`, 3 Threads) serialisiert Puma 20 gleichzeitige Anfragen stark (gemessen ca. 4s) — das ist eine Infrastruktur-/Konfigurationsfrage, kein Code-Problem (der automatisierte Query-Count-Test oben bestätigt bereits keine N+1-Regression). Mit `RAILS_MAX_THREADS=20` (passend zur erwarteten Last) liegt die Gesamtdauer nach einem kurzen Warm-up konstant bei ca. 1.5–1.7s, innerhalb des 2s-Ziels. Für den Betrieb muss `RAILS_MAX_THREADS`/`WEB_CONCURRENCY` entsprechend der erwarteten Last konfiguriert werden.
