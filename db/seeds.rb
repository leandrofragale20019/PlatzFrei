# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Es gibt (noch) keine Verwaltungs-UI für Sportplätze/Zeitfenster (das ist
# nicht Teil der 8 Implementierungsschritte) — Demo-Daten für die
# Platzübersicht kommen daher aus diesen Seeds.

sportplaetze = [
  { name: "Feld 1", sportart: "Fussball" },
  { name: "Halle 1", sportart: "Badminton" },
  { name: "Tennisplatz 1", sportart: "Tennis" }
].map { |attrs| Sportplatz.find_or_create_by!(name: attrs[:name]) { |s| s.sportart = attrs[:sportart] } }

(0..6).each do |tag_offset|
  datum = Date.current + tag_offset.days

  sportplaetze.each do |sportplatz|
    [ 9, 11, 15, 17 ].each do |stunde|
      beginn = datum.to_time.change(hour: stunde)

      Zeitfenster.find_or_create_by!(sportplatz: sportplatz, start: beginn) do |zeitfenster|
        zeitfenster.ende = beginn + 1.hour
      end
    end
  end
end

unless Rails.env.production?
  # Demo-Konten für Dev/Test — nie in Production seeden (bekanntes Passwort).
  Benutzer.find_or_create_by!(email: "mitglied@platzfrei.ch") do |b|
    b.name = "Mia Mitglied"
    b.password = "geheim123"
    b.password_confirmation = "geheim123"
    b.rolle = "mitglied"
  end

  Benutzer.find_or_create_by!(email: "admin@platzfrei.ch") do |b|
    b.name = "Vera Verantwortlich"
    b.password = "geheim123"
    b.password_confirmation = "geheim123"
    b.rolle = "verantwortlicher"
  end

  puts "Demo-Konten: mitglied@platzfrei.ch / admin@platzfrei.ch (Passwort: geheim123)"
end

puts "#{Sportplatz.count} Sportplätze, #{Zeitfenster.count} Zeitfenster."
