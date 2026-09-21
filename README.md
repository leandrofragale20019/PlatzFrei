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
