#!/usr/bin/env ruby
# frozen_string_literal: true

# Lastskript für QA3 ("Die Verfügbarkeitsübersicht für einen Tag mit 15
# Plätzen liefert bei 20 gleichzeitigen Anfragen die Ergebnisse innerhalb
# von 2 Sekunden"). Feuert parallele GET-Requests gegen /zeitfenster eines
# laufenden Servers und misst die Gesamtdauer.
#
# Bootet keine eigene Rails-Umgebung — läuft komplett über HTTP gegen einen
# bereits laufenden Server, damit es eine realistische Anfrage inklusive
# Middleware-Stack misst statt nur die Controller-Logik im Prozess.
#
# Voraussetzung: bin/rails server läuft, bin/rails db:seed wurde ausgeführt
# (liefert aktuell 3 Sportplätze — für eine realistischere 15-Platz-
# Grössenordnung db/seeds.rb entsprechend erweitern) und es existiert ein
# Benutzer-Konto (z.B. über die Registrierungsseite anlegen).
#
# Aufruf: ruby script/lasttest_platzuebersicht.rb E-Mail Passwort [URL] [ANZAHL]

require "net/http"
require "uri"

email, passwort, basis_url, anzahl = ARGV
basis_url ||= "http://127.0.0.1:3000"
anzahl = (anzahl || 20).to_i

if email.nil? || passwort.nil?
  warn "Aufruf: ruby script/lasttest_platzuebersicht.rb E-Mail Passwort [URL] [ANZAHL]"
  exit 1
end

def anfrage(uri, methode: Net::HTTP::Get, cookie: nil, formular: nil, csrf_token: nil)
  http = Net::HTTP.new(uri.host, uri.port)
  request = methode.new(uri)
  request["Cookie"] = cookie if cookie
  request["X-CSRF-Token"] = csrf_token if csrf_token
  request.set_form_data(formular) if formular
  http.request(request)
end

# 1. Login-Seite laden, CSRF-Token + Session-Cookie einsammeln.
login_seite_uri = URI.join(basis_url, "/sitzung/new")
login_seite = anfrage(login_seite_uri)
csrf_token = login_seite.body[/name="csrf-token" content="([^"]+)"/, 1]
session_cookie = login_seite["set-cookie"]&.split(";")&.first

# 2. Einloggen, aktualisierten Session-Cookie übernehmen.
login_antwort = anfrage(
  URI.join(basis_url, "/sitzung"),
  methode: Net::HTTP::Post,
  cookie: session_cookie,
  csrf_token: csrf_token,
  formular: { email: email, password: passwort }
)
session_cookie = login_antwort["set-cookie"]&.split(";")&.first || session_cookie

unless login_antwort.code == "302"
  warn "Login fehlgeschlagen (HTTP #{login_antwort.code}) — E-Mail/Passwort prüfen."
  exit 1
end

# 3. N parallele Anfragen auf die Platzübersicht.
ziel_uri = URI.join(basis_url, "/zeitfenster")
ergebnisse = Queue.new

start = Time.now
threads = Array.new(anzahl) do
  Thread.new do
    einzelstart = Time.now
    antwort = anfrage(ziel_uri, cookie: session_cookie)
    ergebnisse << { status: antwort.code, dauer: Time.now - einzelstart }
  end
end
threads.each(&:join)
gesamtdauer = Time.now - start

zeiten = Array.new(ergebnisse.size) { ergebnisse.pop }

puts "#{anzahl} gleichzeitige Anfragen an #{ziel_uri}"
puts "Gesamtdauer: #{gesamtdauer.round(3)}s (Ziel laut QA3: < 2s)"
puts "Statuscodes: #{zeiten.map { |z| z[:status] }.tally}"
puts "Langsamste Einzelanfrage: #{zeiten.map { |z| z[:dauer] }.max&.round(3)}s"
