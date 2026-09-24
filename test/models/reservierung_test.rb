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

  test "stornieren! setzt den Status und protokolliert mit Standard-Aktion storniert" do
    # anna_bucht_morgen_frueh hat laut Fixture bereits einen "erstellt"-Eintrag
    # (Schritt 1) — stornieren! muss zusätzlich einen "storniert"-Eintrag anlegen.
    reservierung = reservierungen(:anna_bucht_morgen_frueh)

    assert_difference("reservierung.protokolle.count", 1) do
      reservierung.stornieren!(akteur: benutzer(:anna))
    end

    assert_equal "storniert", reservierung.reload.status
    protokoll = reservierung.protokolle.find_by!(aktion: :storniert)
    assert_equal benutzer(:anna), protokoll.akteur
  end

  test "stornieren! erlaubt einen abweichenden Akteur und eine andere Aktion" do
    reservierung = reservierungen(:anna_bucht_morgen_frueh)

    reservierung.stornieren!(akteur: benutzer(:max), aktion: :geschlossen)

    protokoll = reservierung.protokolle.find_by!(aktion: :geschlossen)
    assert_equal benutzer(:max), protokoll.akteur
    assert_not_equal protokoll.akteur, reservierung.benutzer
  end

  test "stornieren! auf bereits stornierter Reservierung wirft StaleObjectError und protokolliert nichts" do
    reservierung = reservierungen(:anna_bucht_morgen_frueh)
    reservierung.stornieren!(akteur: benutzer(:anna))

    assert_no_difference("Protokoll.count") do
      assert_raises(ActiveRecord::StaleObjectError) { reservierung.stornieren!(akteur: benutzer(:anna)) }
    end
  end
end
