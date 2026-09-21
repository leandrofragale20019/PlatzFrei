require "test_helper"

class Admin::SperrungenControllerTest < ActionDispatch::IntegrationTest
  test "new ohne Anmeldung leitet auf Login um" do
    get new_admin_sperrung_path
    assert_redirected_to new_sitzung_path
  end

  test "new als mitglied ist verboten" do
    anmelden_als(benutzer(:anna))

    get new_admin_sperrung_path

    assert_redirected_to root_path
  end

  test "create als verantwortlicher sperrt den Platz und storniert betroffene Reservierungen" do
    anmelden_als(benutzer(:max))
    reservierung = reservierungen(:anna_bucht_morgen_frueh)

    post admin_sperrung_path, params: {
      sportplatz_id: sportplaetze(:feld_eins).id,
      von: (zeitfenster(:morgen_frueh).start - 1.hour).iso8601,
      bis: (zeitfenster(:morgen_frueh).ende + 1.hour).iso8601
    }

    assert_redirected_to zeitfenster_path
    assert zeitfenster(:morgen_frueh).reload.gesperrt?
    assert_equal "storniert", reservierung.reload.status
  end

  test "create mit ungültigem Zeitraum zeigt eine Fehlermeldung" do
    anmelden_als(benutzer(:max))

    post admin_sperrung_path, params: {
      sportplatz_id: sportplaetze(:feld_eins).id,
      von: zeitfenster(:morgen_frueh).ende.iso8601,
      bis: zeitfenster(:morgen_frueh).start.iso8601
    }

    assert_redirected_to new_admin_sperrung_path
    assert_not zeitfenster(:morgen_frueh).reload.gesperrt?
  end

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
