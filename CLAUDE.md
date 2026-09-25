# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is a Rails 8.1 application generated from the default `rails new` skeleton — Ruby 4.0.6, SQLite (via `sqlite3` gem), Hotwire (Turbo + Stimulus), Propshaft, Solid Queue/Cache/Cable, and Kamal for deployment. No custom models, controllers, routes, or tests have been added yet (`config/routes.rb` has no root route; `app/models`, `app/controllers`, and `test/` only contain the generated stubs).

## Commands

- `bin/setup` — install gems, prepare the database, clear logs/tmp, then start the dev server. Add `--skip-server` to stop after setup, `--reset` to reset the database.
- `bin/dev` — start the app (`bin/rails server`).
- `bin/rails test` — run the test suite. Run a single file with `bin/rails test test/models/foo_test.rb`, or a single test with `bin/rails test test/models/foo_test.rb:LINE`.
- `bin/rails test:system` — run system tests (Capybara + Selenium).
- `bin/rubocop` — lint/style check (Omakase Rails style via `rubocop-rails-omakase`; house rules go in `.rubocop.yml`).
- `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` — static security analysis.
- `bin/bundler-audit` — audit gems for known CVEs.
- `bin/importmap audit` — audit JS dependencies pinned in `config/importmap.rb`.
- `bin/ci` — runs the full CI pipeline locally (setup, rubocop, bundler-audit, importmap audit, brakeman, `bin/rails test`, then reseeds the test DB) — see `config/ci.rb` for the exact steps.
- `bin/rails db:prepare` / `db:migrate` / `db:seed` — standard Active Record DB tasks.

## Architecture notes

- Three auxiliary SQLite databases besides the primary one (`config/database.yml`), each with its own schema/migration path: `solid_cache` (`db/cache_schema.rb`), `solid_queue` (`db/queue_schema.rb`), `solid_cable` (`db/cable_schema.rb`). Background jobs, Rails.cache, and Action Cable all persist to these rather than external services (Redis/Memcached), consistent with the "Solid trifecta" Rails 8 defaults.
- Frontend uses import maps (no Node/bundler build step) with Stimulus controllers registered in `app/javascript/controllers/index.js`.
- Deployment is via Kamal (`config/deploy.yml`, `.kamal/`) into a Docker image built from the root `Dockerfile`, fronted by Thruster.

## Agent skills

### Issue tracker

Issues and specs live as local markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Standard five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout (`CONTEXT.md` + `docs/adr/` at repo root). See `docs/agents/domain.md`.

## Project domain: PlatzFrei

School project (Modul M233 – Multiuser-Applikation entwickeln). PlatzFrei lets club members reserve sports facilities (Sportplätze) without double-booking, while facility managers keep an overview of bookings, closures, and conflicts. This is the 1st MVP iteration only — scope is deliberately limited to what's listed below.

**Roles**

| Role | Permissions |
|---|---|
| `Vereinsmitglied` (member) | view facilities/availability, reserve a slot, cancel own reservations, join a waitlist |
| `Platzverantwortliche/r` (facility manager) | everything a member can do, plus: create/close facilities, view & cancel any reservation, view the activity log |

**Data model** (see ERM in `docs/dokumentation.md` §7 and deviations in §11 — keep migrations in sync with it)

- `Benutzer` (User) `1—n` `Reservierung`
- `Sportplatz` (Facility) `1—n` `Zeitfenster` (Slot)
- `Zeitfenster` `1—0/1` `Reservierung`; `Zeitfenster` has `gesperrt` (closed, bool). `Reservierung` has `lock_version` — optimistic locking for the reservation-**update** path (cancel vs. closure), see Locking below. (`Zeitfenster` also carries a `lock_version` column, only relevant when the slot row itself is updated, e.g. closing it.)
- `Reservierung` `1—n` `Protokoll` (Activity log); `Zeitfenster` `1—n` `Protokoll` for entries without a reservation (closure of a free slot, lifting a closure — aktion `geschlossen` / `entsperrt`). Each `Protokoll` references exactly one of `reservierung_id` / `zeitfenster_id` (both nullable, validated XOR).
- `Warteliste` (Waitlist) `n—1` `Zeitfenster`

**Functional requirements, priority order**

1. View available facilities/slots for a chosen date, filterable by sport/facility
2. Reserve a free slot
3. View and cancel own reservation
4. Manager closes a facility for a period (maintenance/tournament) — reservations in that period are auto-cancelled and affected members notified
5. Manager views and cancels any reservation for a facility (e.g. abuse)
6. Member registration and login
7. Waitlist: if a slot is full, a member can join a waitlist and is auto-notified on cancellation

**Quality attributes — treat these as acceptance criteria, not suggestions**

1. **Data consistency:** if two members reserve the same slot concurrently, exactly one reservation is confirmed; the other gets an immediate error with a suggested next free slot. This is an **INSERT** conflict, so it is enforced by a **partial unique index** on `reservierungen (zeitfenster_id) WHERE status = 'reserviert'` (the second INSERT raises `ActiveRecord::RecordNotUnique`) — not by `lock_version` and not by a pre-check-then-write. (`lock_version` only guards UPDATEs to an already-existing row and therefore cannot prevent a duplicate INSERT; the genuine optimistic-locking case lives on the reservation-update path, see QA5.)
2. **Freshness:** a successfully reserved slot disappears from every other logged-in user's availability view within 5 seconds.
3. **Performance:** the availability overview for one day with 15 facilities returns within 2 seconds under 20 concurrent requests.
4. **Auditability:** every cancellation and facility closure is logged with timestamp and acting user, viewable by managers at any time.
5. **Closure consistency (the genuine optimistic-locking case):** if a manager closes a facility while a member concurrently **cancels** the same reservation, both operations `UPDATE` the same `reservierungen` row. `lock_version` (optimistic locking on `reservierungen`) makes the later writer lose with `ActiveRecord::StaleObjectError` instead of clobbering the row a second time. It is handled cleanly on both sides: the member sees a friendly notice, and the closure skips the already-cancelled reservation (per-reservation savepoint) instead of aborting. For the concurrent-**create** direction the closure path relies on the controller's `gesperrt?` check plus the QA1 unique index (no hard DB guarantee beyond that). No double-release, no "ghost" reservation.

**Locking & transactions (explicit, don't simplify these away)**

- **Double-booking on new reservations (INSERT)** is prevented by the **partial unique index** on `reservierungen (zeitfenster_id) WHERE status = 'reserviert'` — the second concurrent INSERT raises `ActiveRecord::RecordNotUnique`. This is the only conflict path when creating a reservation (`Zeitfenster#reserviert_von!`, caught in `ReservierungenController#create`). `lock_version` is **not** used here (it cannot protect an INSERT).
- **Optimistic locking (`lock_version` on `reservierungen`)** guards the reservation-**update** path: cancelling a reservation (`Reservierung#stornieren!`) vs. closing the facility (`Sportplatz#sperren!`) both UPDATE the same row. The later write is rejected with `ActiveRecord::StaleObjectError` ("who writes first, wins"). Caught in `ReservierungenController#destroy` (member) and skipped per-reservation via a `requires_new` savepoint inside `Sportplatz#sperren!` (manager).
- Creating a `Reservierung` and its `Protokoll` entry must be one atomic transaction — if the unique index rejects the INSERT, no log entry is written.
- Closing a facility + auto-cancelling affected reservations + their log entries + notifications must be one atomic transaction; a per-reservation `StaleObjectError` (member cancelled concurrently) is caught and skipped, not allowed to abort the whole closure.
- Pessimistic locking (SQLite `BEGIN IMMEDIATE`) is the discussed alternative for the closure path (bulk-affects a group of reservations) — worth a short comparison note in the code/README, not necessarily the final implementation.

**Tech stack constraints:** Ruby on Rails + SQLite3 (as already set up in this repo). No additional infra (no Redis) unless explicitly requested.

## Implementation plan

Work through these steps **one at a time, in this order**. After finishing a step: run the relevant tests, run `bin/rubocop`, commit with a message naming the step, and stop — wait for confirmation before starting the next step. Don't implement functionality from a later step early, even if it seems convenient.

1. **Datenbank und Models** — migrations + models for the full ERM (`Benutzer`, `Sportplatz`, `Zeitfenster` incl. `lock_version`/`gesperrt`, `Reservierung`, `Protokoll`, `Warteliste`), associations, basic validations (no overlapping slots). No controllers/views yet.
2. **Benutzerauthentifizierung** — `has_secure_password`-based auth (registration, login, logout).
3. **Benutzerprofil** — view/edit own profile; only the logged-in user may edit their own.
4. **Benutzerverwaltung** — `Admin::` namespace, list/view users. No access restriction yet (that's step 5).
5. **Benutzerrollen und Berechtigungen** — role-based access per the roles table above; lock down the `Admin::` namespace to `Platzverantwortliche/r` only.
6. **Kernfunktion** — reservation creation/cancellation/waitlist flows. This is where quality attribute 1 (double-booking on concurrent creation) must be implemented via the partial unique index and tested with a concurrency test (two INSERTs → one `RecordNotUnique`), not just a happy-path test. UI dazu: Platzübersicht mit Kalenderansicht (Filter nach
   Sportart/Datum), Reservierungsdetail mit Bestätigungsdialog, "Meine
   Reservierungen" mit Stornier-Optio
7. **Aktivitätsprotokoll** — `Protokoll` model + the two atomic transactions described above (reservation+log, closure+cancellations+notifications+log). This is also where quality attribute 5 (optimistic locking on `reservierungen`: cancel vs. closure) lives, tested with a concurrency test (`StaleObjectError` on the later write).
8. **Testing** — test suite specifically targeting the quality attributes above (concurrent reservation conflict, transaction integrity on closure, role-gated admin access, logging), not just CRUD happy paths.