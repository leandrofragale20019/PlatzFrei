require "test_helper"

class Admin::BenutzerControllerTest < ActionDispatch::IntegrationTest
  test "index ohne Anmeldung leitet auf Login um" do
    get admin_benutzer_path
    assert_redirected_to new_sitzung_path
  end

  test "show ohne Anmeldung leitet auf Login um" do
    get admin_benutzer_zeigen_path(benutzer(:anna))
    assert_redirected_to new_sitzung_path
  end

  test "index als mitglied leitet mit Kein-Zugriff-Meldung auf die Startseite um" do
    anmelden_als(benutzer(:anna))

    get admin_benutzer_path

    assert_redirected_to root_path
    assert_equal "Kein Zugriff.", flash[:alert]
  end

  test "show als mitglied leitet mit Kein-Zugriff-Meldung auf die Startseite um" do
    anmelden_als(benutzer(:anna))

    get admin_benutzer_zeigen_path(benutzer(:max))

    assert_redirected_to root_path
    assert_equal "Kein Zugriff.", flash[:alert]
  end

  test "index als verantwortlicher listet alle Benutzer" do
    anmelden_als(benutzer(:max))

    get admin_benutzer_path

    assert_response :success
    assert_select "td", text: benutzer(:anna).name
    assert_select "td", text: benutzer(:max).name
  end

  test "show als verantwortlicher zeigt die Daten eines Benutzers" do
    anmelden_als(benutzer(:max))

    get admin_benutzer_zeigen_path(benutzer(:anna))

    assert_response :success
    assert_select "p", text: /#{benutzer(:anna).email}/
  end

  test "show mit unbekannter ID liefert als verantwortlicher 404" do
    anmelden_als(benutzer(:max))

    get admin_benutzer_zeigen_path(id: -1)

    assert_response :not_found
  end

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
