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
end
