require "test_helper"

class WartelistenControllerTest < ActionDispatch::IntegrationTest
  test "create ohne Anmeldung leitet auf Login um" do
    post wartelisten_path, params: { zeitfenster_id: zeitfenster(:morgen_frueh).id }
    assert_redirected_to new_sitzung_path
  end

  test "trägt sich für ein belegtes Zeitfenster in die Warteliste ein" do
    # halle_slot ist laut Fixture bereits von max belegt; anna steht noch nicht darauf.
    anmelden_als(benutzer(:anna))

    assert_difference("Warteliste.count", 1) do
      post wartelisten_path, params: { zeitfenster_id: zeitfenster(:halle_slot).id }
    end
  end

  test "doppelte Eintragung schlägt fehl" do
    # max steht laut Fixture bereits auf der Warteliste für morgen_frueh
    anmelden_als(benutzer(:max))

    assert_no_difference("Warteliste.count") do
      post wartelisten_path, params: { zeitfenster_id: zeitfenster(:morgen_frueh).id }
    end

    assert_redirected_to zeitfenster_zeigen_path(zeitfenster(:morgen_frueh))
  end

  test "gesperrtes Zeitfenster blockiert die Eintragung" do
    anmelden_als(benutzer(:anna))

    assert_no_difference("Warteliste.count") do
      post wartelisten_path, params: { zeitfenster_id: zeitfenster(:morgen_gesperrt).id }
    end

    assert_equal "Dieser Platz ist gesperrt.", flash[:alert]
  end

  test "freies Zeitfenster blockiert die Eintragung mit Direkt-Reservieren-Hinweis" do
    anmelden_als(benutzer(:anna))

    assert_no_difference("Warteliste.count") do
      post wartelisten_path, params: { zeitfenster_id: zeitfenster(:morgen_spaet).id }
    end

    assert_match(/frei/, flash[:notice])
  end

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
