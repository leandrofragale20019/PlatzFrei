require "test_helper"

class BenutzerTest < ActiveSupport::TestCase
  test "gültig mit Fixture-Daten" do
    assert benutzer(:anna).valid?
  end

  test "erfordert einen Namen" do
    benutzer(:anna).name = nil
    assert_not benutzer(:anna).valid?
  end

  test "erfordert eine eindeutige E-Mail, unabhängig von Gross-/Kleinschreibung" do
    duplikat = Benutzer.new(name: "Anna Zwei", email: benutzer(:anna).email.upcase, rolle: "mitglied")
    assert_not duplikat.valid?
    assert_includes duplikat.errors[:email], "has already been taken"
  end

  test "rolle ist standardmässig mitglied" do
    assert_equal "mitglied", Benutzer.new.rolle
  end

  test "verantwortlicher ist eine gültige Rolle" do
    assert benutzer(:max).verantwortlicher?
  end

  test "authenticate gibt den Benutzer bei korrektem Passwort zurück" do
    assert_equal benutzer(:anna), benutzer(:anna).authenticate("geheim123")
  end

  test "authenticate schlägt bei falschem Passwort fehl" do
    assert_not benutzer(:anna).authenticate("falsches-passwort")
  end

  test "erfordert ein Passwort mit mindestens 8 Zeichen" do
    neuer_benutzer = Benutzer.new(name: "Neu", email: "neu@example.com", password: "kurz", password_confirmation: "kurz")
    assert_not neuer_benutzer.valid?
    assert_includes neuer_benutzer.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "Passwort-Mindestlänge blockiert nicht das Speichern ohne Passwortänderung" do
    benutzer(:anna).name = "Anna Neu"
    assert benutzer(:anna).valid?
  end
end
