require "test_helper"

class SitzungenControllerTest < ActionDispatch::IntegrationTest
  test "erfolgreicher Login setzt die Session" do
    post sitzung_path, params: { email: benutzer(:anna).email, password: "geheim123" }

    assert_redirected_to root_path
    assert_equal benutzer(:anna).id, session[:benutzer_id]
  end

  test "Login mit falschem Passwort schlägt mit generischer Fehlermeldung fehl" do
    post sitzung_path, params: { email: benutzer(:anna).email, password: "falsches-passwort" }

    assert_response :unprocessable_entity
    assert_nil session[:benutzer_id]
    assert_equal "E-Mail oder Passwort ungültig.", flash[:alert]
  end

  test "Login mit unbekannter E-Mail schlägt mit derselben generischen Fehlermeldung fehl" do
    post sitzung_path, params: { email: "unbekannt@example.com", password: "irgendwas123" }

    assert_response :unprocessable_entity
    assert_nil session[:benutzer_id]
    assert_equal "E-Mail oder Passwort ungültig.", flash[:alert]
  end

  test "Logout leert die Session" do
    post sitzung_path, params: { email: benutzer(:anna).email, password: "geheim123" }
    assert_equal benutzer(:anna).id, session[:benutzer_id]

    delete sitzung_path

    assert_redirected_to root_path
    assert_nil session[:benutzer_id]
  end
end
