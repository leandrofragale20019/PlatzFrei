require "test_helper"

class ReservierungenControllerTest < ActionDispatch::IntegrationTest
  test "create ohne Anmeldung leitet auf Login um" do
    post reservierungen_path, params: { zeitfenster_id: zeitfenster(:morgen_spaet).id }
    assert_redirected_to new_sitzung_path
  end

  test "erfolgreiche Reservierung eines freien Zeitfensters" do
    anmelden_als(benutzer(:anna))

    assert_difference("Reservierung.count", 1) do
      post reservierungen_path, params: { zeitfenster_id: zeitfenster(:morgen_spaet).id }
    end

    assert_redirected_to reservierungen_path
    assert_equal benutzer(:anna), zeitfenster(:morgen_spaet).reload.aktive_reservierung.benutzer
  end

  test "Reservierung eines bereits belegten Zeitfensters schlägt mit Hinweis fehl" do
    anmelden_als(benutzer(:max))

    assert_no_difference("Reservierung.count") do
      post reservierungen_path, params: { zeitfenster_id: zeitfenster(:morgen_frueh).id }
    end

    assert_redirected_to zeitfenster_zeigen_path(zeitfenster(:morgen_frueh))
    assert_match(/bereits.*reserviert|inzwischen/, flash[:alert])
  end

  test "Reservierung eines gesperrten Zeitfensters wird abgelehnt" do
    anmelden_als(benutzer(:anna))

    assert_no_difference("Reservierung.count") do
      post reservierungen_path, params: { zeitfenster_id: zeitfenster(:morgen_gesperrt).id }
    end

    assert_redirected_to zeitfenster_zeigen_path(zeitfenster(:morgen_gesperrt))
    assert_equal "Dieser Platz ist gesperrt.", flash[:alert]
  end

  test "index zeigt nur eigene Reservierungen" do
    anmelden_als(benutzer(:anna))

    get reservierungen_path

    assert_response :success
    assert_select "td", text: zeitfenster(:morgen_frueh).sportplatz.name
  end

  test "destroy storniert die eigene Reservierung und protokolliert sie" do
    anmelden_als(benutzer(:anna))
    reservierung = reservierungen(:anna_bucht_morgen_frueh)

    delete reservierung_path(reservierung)

    assert_redirected_to reservierungen_path
    assert_equal "storniert", reservierung.reload.status

    protokoll = reservierung.protokolle.find_by!(aktion: :storniert)
    assert_equal benutzer(:anna), protokoll.akteur
  end

  test "destroy einer fremden Reservierung liefert 404" do
    anmelden_als(benutzer(:max))

    delete reservierung_path(reservierungen(:anna_bucht_morgen_frueh))

    assert_response :not_found
  end

  test "Warteliste: nach Stornierung sieht der wartende Benutzer sofort den 'Jetzt frei'-Hinweis (FR7)" do
    # Fixtures: anna hat morgen_frueh reserviert, max steht bereits auf dessen Warteliste.
    anmelden_als(benutzer(:anna))
    delete reservierung_path(reservierungen(:anna_bucht_morgen_frueh))

    max_session = open_session
    max_session.post sitzung_path, params: { email: benutzer(:max).email, password: "geheim123" }
    max_session.get reservierungen_path

    assert_includes max_session.response.body, "Jetzt frei!"
  end

  test "Stornieren auf veralteter Seite nach einer Platzsperrung: Hinweis statt zweiter Stornierung (QA5, Anleitung 4.9)" do
    reservierung = reservierungen(:anna_bucht_morgen_frueh)
    veraltete_lock_version = reservierung.lock_version
    zf = reservierung.zeitfenster
    zf.sportplatz.sperren!(von: zf.start, bis: zf.ende, akteur: benutzer(:max))

    anmelden_als(benutzer(:anna))
    assert_no_difference("Protokoll.count") do
      delete reservierung_path(reservierung), params: { lock_version: veraltete_lock_version }
    end

    assert_redirected_to reservierungen_path
    assert_equal "Diese Reservierung wurde inzwischen durch eine Platzsperrung storniert.", flash[:alert]
  end

  test "index zeigt eine Mitteilung für durch Sperrung stornierte Reservierungen" do
    zf = zeitfenster(:morgen_frueh)
    zf.sportplatz.sperren!(von: zf.start, bis: zf.ende, akteur: benutzer(:max))

    anmelden_als(benutzer(:anna))
    get reservierungen_path

    assert_select "p", text: "Wegen einer Platzsperrung storniert"
  end

  test "Warteliste zeigt 'Gesperrt' für gesperrte Zeitfenster" do
    zf = zeitfenster(:morgen_frueh)
    zf.sportplatz.sperren!(von: zf.start, bis: zf.ende, akteur: benutzer(:max))

    anmelden_als(benutzer(:max))
    get reservierungen_path

    assert_select ".badge", text: "Gesperrt"
    assert_not_includes response.body, "Wartend"
  end

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
