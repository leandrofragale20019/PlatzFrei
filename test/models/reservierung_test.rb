require "test_helper"

class ReservierungTest < ActiveSupport::TestCase
  test "gültig mit Fixture-Daten" do
    assert reservierungen(:anna_bucht_morgen_frueh).valid?
  end

  test "status ist standardmässig reserviert" do
    assert_equal "reserviert", reservierungen(:anna_bucht_morgen_frueh).status
  end

  test "erfordert erstellt_am" do
    reservierung = reservierungen(:anna_bucht_morgen_frueh)
    reservierung.erstellt_am = nil
    assert_not reservierung.valid?
  end

  test "höchstens eine aktive Reservierung pro Zeitfenster (DB-Constraint)" do
    zweite = Reservierung.new(
      benutzer: benutzer(:max),
      zeitfenster: reservierungen(:anna_bucht_morgen_frueh).zeitfenster,
      erstellt_am: Time.current
    )

    assert_raises(ActiveRecord::RecordNotUnique) { zweite.save!(validate: false) }
  end

  test "eine stornierte Reservierung blockiert keine neue aktive Reservierung" do
    aktive = reservierungen(:anna_bucht_morgen_frueh)
    aktive.update!(status: :storniert)

    zweite = Reservierung.new(benutzer: benutzer(:max), zeitfenster: aktive.zeitfenster, erstellt_am: Time.current)
    assert zweite.save
  end
end
