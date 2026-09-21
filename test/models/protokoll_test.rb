require "test_helper"

class ProtokollTest < ActiveSupport::TestCase
  test "gültig mit Fixture-Daten" do
    assert protokolle(:anna_reservierung_erstellt).valid?
  end

  test "erfordert einen zeitpunkt" do
    protokoll = protokolle(:anna_reservierung_erstellt)
    protokoll.zeitpunkt = nil
    assert_not protokoll.valid?
  end

  test "akteur kann von der reservierenden Person abweichen (z.B. Manager storniert fremde Reservierung)" do
    protokoll = Protokoll.new(
      reservierung: reservierungen(:anna_bucht_morgen_frueh),
      akteur: benutzer(:max),
      aktion: :storniert,
      zeitpunkt: Time.current
    )

    assert protokoll.valid?
    assert_equal benutzer(:max), protokoll.akteur
    assert_not_equal protokoll.akteur, protokoll.reservierung.benutzer
  end
end
