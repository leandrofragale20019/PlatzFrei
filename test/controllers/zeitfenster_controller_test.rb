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

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
