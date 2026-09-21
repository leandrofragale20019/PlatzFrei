require "test_helper"

class Admin::ProtokolleControllerTest < ActionDispatch::IntegrationTest
  test "index ohne Anmeldung leitet auf Login um" do
    get admin_protokolle_path
    assert_redirected_to new_sitzung_path
  end

  test "index als mitglied ist verboten" do
    anmelden_als(benutzer(:anna))

    get admin_protokolle_path

    assert_redirected_to root_path
  end

  test "index als verantwortlicher zeigt das Protokoll" do
    anmelden_als(benutzer(:max))

    get admin_protokolle_path

    assert_response :success
    assert_select "td", text: "erstellt"
  end

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
