require "test_helper"

class Admin::BenutzerControllerTest < ActionDispatch::IntegrationTest
  test "index ist auch ohne Anmeldung erreichbar und listet alle Benutzer" do
    get admin_benutzer_path

    assert_response :success
    assert_select "td", text: benutzer(:anna).name
    assert_select "td", text: benutzer(:max).name
  end

  test "show ist auch ohne Anmeldung erreichbar und zeigt die Daten eines Benutzers" do
    get admin_benutzer_zeigen_path(benutzer(:anna))

    assert_response :success
    assert_select "p", text: /#{benutzer(:anna).email}/
  end

  test "show mit unbekannter ID liefert 404" do
    get admin_benutzer_zeigen_path(id: -1)

    assert_response :not_found
  end
end
