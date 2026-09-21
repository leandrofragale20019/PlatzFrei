require "test_helper"

class RegistrierungenControllerTest < ActionDispatch::IntegrationTest
  test "erfolgreiche Registrierung legt einen Benutzer an und loggt ihn ein" do
    assert_difference("Benutzer.count", 1) do
      post registrierung_path, params: {
        benutzer: { name: "Neu Mitglied", email: "neu@example.com", password: "geheim123", password_confirmation: "geheim123" }
      }
    end

    assert_redirected_to root_path
    assert_equal Benutzer.find_by(email: "neu@example.com").id, session[:benutzer_id]
  end

  test "Registrierung mit doppelter E-Mail schlägt fehl" do
    assert_no_difference("Benutzer.count") do
      post registrierung_path, params: {
        benutzer: { name: "Zweite Anna", email: benutzer(:anna).email, password: "geheim123", password_confirmation: "geheim123" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "Registrierung mit zu kurzem Passwort schlägt fehl" do
    assert_no_difference("Benutzer.count") do
      post registrierung_path, params: {
        benutzer: { name: "Kurz", email: "kurz@example.com", password: "kurz", password_confirmation: "kurz" }
      }
    end

    assert_response :unprocessable_entity
  end
end
