require "test_helper"

class Admin::ReservierungenControllerTest < ActionDispatch::IntegrationTest
  test "index ohne Anmeldung leitet auf Login um" do
    get admin_reservierungen_path
    assert_redirected_to new_sitzung_path
  end

  test "index als mitglied ist verboten" do
    anmelden_als(benutzer(:anna))

    get admin_reservierungen_path

    assert_redirected_to root_path
  end

  test "index als verantwortlicher zeigt alle aktiven Reservierungen" do
    anmelden_als(benutzer(:max))

    get admin_reservierungen_path

    assert_response :success
    assert_select "td", text: benutzer(:anna).name
  end

  test "destroy als verantwortlicher storniert eine fremde Reservierung" do
    anmelden_als(benutzer(:max))

    delete admin_reservierung_path(reservierungen(:anna_bucht_morgen_frueh))

    assert_redirected_to admin_reservierungen_path
    assert_equal "storniert", reservierungen(:anna_bucht_morgen_frueh).reload.status

    protokoll = reservierungen(:anna_bucht_morgen_frueh).protokolle.find_by!(aktion: :storniert)
    assert_equal benutzer(:max), protokoll.akteur
  end

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
