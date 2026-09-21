require "test_helper"

class ProfilControllerTest < ActionDispatch::IntegrationTest
  test "show ohne Anmeldung leitet auf Login um" do
    get profil_path
    assert_redirected_to new_sitzung_path
  end

  test "edit ohne Anmeldung leitet auf Login um" do
    get edit_profil_path
    assert_redirected_to new_sitzung_path
  end

  test "show zeigt die eigenen Daten" do
    anmelden_als(benutzer(:anna))

    get profil_path

    assert_response :success
    assert_select "p", text: /#{benutzer(:anna).name}/
  end

  test "update mit gültigen Daten ändert Name und E-Mail" do
    anmelden_als(benutzer(:anna))

    patch profil_path, params: { benutzer: { name: "Anna Neu", email: "anna-neu@example.com", password: "", password_confirmation: "" } }

    assert_redirected_to profil_path
    assert_equal "Anna Neu", benutzer(:anna).reload.name
    assert_equal "anna-neu@example.com", benutzer(:anna).reload.email
  end

  test "update mit bereits vergebener E-Mail schlägt fehl" do
    anmelden_als(benutzer(:anna))

    patch profil_path, params: { benutzer: { name: benutzer(:anna).name, email: benutzer(:max).email, password: "", password_confirmation: "" } }

    assert_response :unprocessable_entity
    assert_not_equal benutzer(:max).email, benutzer(:anna).reload.email
  end

  test "update mit neuem Passwort erlaubt Login mit dem neuen Passwort" do
    anmelden_als(benutzer(:anna))

    patch profil_path, params: { benutzer: { name: benutzer(:anna).name, email: benutzer(:anna).email, password: "neuespasswort", password_confirmation: "neuespasswort" } }

    assert_redirected_to profil_path
    assert benutzer(:anna).reload.authenticate("neuespasswort")
  end

  test "update mit leerem Passwortfeld lässt das alte Passwort gültig" do
    anmelden_als(benutzer(:anna))

    patch profil_path, params: { benutzer: { name: "Anna Neu", email: benutzer(:anna).email, password: "", password_confirmation: "" } }

    assert_redirected_to profil_path
    assert benutzer(:anna).reload.authenticate("geheim123")
  end

  private

  def anmelden_als(benutzer)
    post sitzung_path, params: { email: benutzer.email, password: "geheim123" }
  end
end
