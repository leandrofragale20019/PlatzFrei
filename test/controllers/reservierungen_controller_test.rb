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

  test "destroy storniert die eigene Reservierung" do
    anmelden_als(benutzer(:anna))

    delete reservierung_path(reservierungen(:anna_bucht_morgen_frueh))

    assert_redirected_to reservierungen_path
    assert_equal "storniert", reservierungen(:anna_bucht_morgen_frueh).reload.status
  end

  test "destroy einer fremden Reservierung liefert 404" do
    anmelden_als(benutzer(:max))

    delete reservierung_path(reservierungen(:anna_bucht_morgen_frueh))

    assert_response :not_found
  end

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
