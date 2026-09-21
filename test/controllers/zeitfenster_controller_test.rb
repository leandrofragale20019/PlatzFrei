require "test_helper"

class ZeitfensterControllerTest < ActionDispatch::IntegrationTest
  test "index ohne Anmeldung leitet auf Login um" do
    get zeitfenster_path
    assert_redirected_to new_sitzung_path
  end

  test "show ohne Anmeldung leitet auf Login um" do
    get zeitfenster_zeigen_path(zeitfenster(:morgen_frueh))
    assert_redirected_to new_sitzung_path
  end

  test "index zeigt Zeitfenster für das gewählte Datum" do
    anmelden_als(benutzer(:anna))

    get zeitfenster_path(datum: zeitfenster(:morgen_frueh).start.to_date)

    assert_response :success
    assert_select "td", text: zeitfenster(:morgen_frueh).sportplatz.name
  end

  test "index filtert nach Sportart" do
    anmelden_als(benutzer(:anna))

    get zeitfenster_path(datum: zeitfenster(:halle_slot).start.to_date, sportart: "Badminton")

    assert_response :success
    assert_select "td", text: "Halle 1"
    assert_select "td", { text: "Feld 1", count: 0 }
  end

  test "show zeigt Details eines Zeitfensters" do
    anmelden_als(benutzer(:anna))

    get zeitfenster_zeigen_path(zeitfenster(:morgen_spaet))

    assert_response :success
  end

  test "ein reserviertes Zeitfenster verschwindet sofort aus der Verfügbarkeitsansicht anderer Benutzer (Aktualität)" do
    zf = zeitfenster(:morgen_spaet)

    anna_session = open_session
    anna_session.post sitzung_path, params: { email: benutzer(:anna).email, password: "geheim123" }
    anna_session.post reservierungen_path, params: { zeitfenster_id: zf.id }

    max_session = open_session
    max_session.post sitzung_path, params: { email: benutzer(:max).email, password: "geheim123" }
    max_session.get zeitfenster_path(datum: zf.start.to_date)

    assert_includes max_session.response.body, "Reserviert"
  end

  test "Platzübersicht für 15 Plätze an einem Tag erzeugt keine N+1-Anfragen" do
    # Absolute Zeitmessungen sind unter bin/rails test unzuverlässig, weil die
    # Suite parallel über viele Worker-Prozesse läuft (CPU-Kontention ≠
    # App-Performance). Stattdessen wird direkt die Anfragenanzahl geprüft:
    # das ist die eigentliche Ursache von QA3-Regressionen und unabhängig
    # von der Maschinenlast deterministisch.
    anmelden_als(benutzer(:anna))
    datum = 3.days.from_now.to_date

    15.times do |i|
      sportplatz = Sportplatz.create!(name: "Performance-Platz #{i}", sportart: "Fussball")
      4.times do |slot|
        beginn = datum.to_time.change(hour: 8 + (slot * 2))
        Zeitfenster.create!(sportplatz: sportplatz, start: beginn, ende: beginn + 1.hour)
      end
    end

    anzahl_queries = 0
    zaehler = ->(*, payload) { anzahl_queries += 1 unless payload[:sql].match?(/\A(BEGIN|COMMIT|SAVEPOINT|RELEASE)/i) }

    ActiveSupport::Notifications.subscribed(zaehler, "sql.active_record") do
      get zeitfenster_path(datum: datum)
    end

    assert_response :success
    # 60 Zeitfenster über 15 Sportplätze — bei einer N+1-Regression (z.B. ein
    # sportplatz-Zugriff pro Zeile ohne includes) läge das im Bereich von 60+
    # Anfragen statt einer Handvoll.
    assert_operator anzahl_queries, :<, 10, "Zu viele SQL-Anfragen (#{anzahl_queries}) — vermutlich eine N+1-Regression"
  end

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
