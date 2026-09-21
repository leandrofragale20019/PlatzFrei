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

**Data model** (see full ERM with attributes in `docs/Projektantrag.md` if present — keep migrations in sync with it)

- `Benutzer` (User) `1—n` `Reservierung`
- `Sportplatz` (Facility) `1—n` `Zeitfenster` (Slot)
- `Zeitfenster` `1—0/1` `Reservierung`; has `lock_version` (optimistic locking) and `gesperrt` (closed, bool)
- `Reservierung` `1—n` `Protokoll` (Activity log)
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

1. **Data consistency:** if two members reserve the same slot concurrently, exactly one reservation is confirmed; the other gets an immediate error with a suggested next free slot. Implement via `lock_version` (optimistic locking) on `Zeitfenster`, not a pre-check-then-write.
2. **Freshness:** a successfully reserved slot disappears from every other logged-in user's availability view within 5 seconds.
3. **Performance:** the availability overview for one day with 15 facilities returns within 2 seconds under 20 concurrent requests.
4. **Auditability:** every cancellation and facility closure is logged with timestamp and acting user, viewable by managers at any time.
5. **Closure consistency:** if a manager closes a facility while a member concurrently creates/cancels a reservation for it, the data stays consistent — no double-release, no "ghost" reservation.

**Locking & transactions (explicit, don't simplify these away)**

- Optimistic locking (`lock_version`) on `Zeitfenster`/`Reservierung` for the reservation-creation path.
- Creating a `Reservierung` and its `Protokoll` entry must be one atomic transaction — if the conflict check fails, no log entry is written.
- Closing a facility + auto-cancelling affected reservations + their log entries + notifications must be one atomic transaction.
- Pessimistic locking (SQLite `BEGIN IMMEDIATE`) is the discussed alternative for the closure path (bulk-affects a group of reservations) — worth a short comparison note in the code/README, not necessarily the final implementation.

**Tech stack constraints:** Ruby on Rails + SQLite3 (as already set up in this repo). No additional infra (no Redis) unless explicitly requested.

## Implementation plan

Work through these steps **one at a time, in this order**. After finishing a step: run the relevant tests, run `bin/rubocop`, commit with a message naming the step, and stop — wait for confirmation before starting the next step. Don't implement functionality from a later step early, even if it seems convenient.

1. **Datenbank und Models** — migrations + models for the full ERM (`Benutzer`, `Sportplatz`, `Zeitfenster` incl. `lock_version`/`gesperrt`, `Reservierung`, `Protokoll`, `Warteliste`), associations, basic validations (no overlapping slots). No controllers/views yet.
2. **Benutzerauthentifizierung** — `has_secure_password`-based auth (registration, login, logout).
3. **Benutzerprofil** — view/edit own profile; only the logged-in user may edit their own.
4. **Benutzerverwaltung** — `Admin::` namespace, list/view users. No access restriction yet (that's step 5).
5. **Benutzerrollen und Berechtigungen** — role-based access per the roles table above; lock down the `Admin::` namespace to `Platzverantwortliche/r` only.
6. **Kernfunktion** — reservation creation/cancellation/waitlist flows. This is where quality attribute 1 (optimistic locking, concurrent reservation conflict) must be implemented and tested with a concurrency test, not just a happy-path test.
7. **Aktivitätsprotokoll** — `Protokoll` model + the two atomic transactions described above (reservation+log, closure+cancellations+notifications+log).
8. **Testing** — test suite specifically targeting the quality attributes above (concurrent reservation conflict, transaction integrity on closure, role-gated admin access, logging), not just CRUD happy paths.