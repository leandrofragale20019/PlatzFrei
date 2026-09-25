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

  test "kann sich statt auf eine Reservierung direkt auf ein Zeitfenster beziehen" do
    protokoll = Protokoll.new(zeitfenster: zeitfenster(:morgen_spaet), akteur: benutzer(:max), aktion: :geschlossen, zeitpunkt: Time.current)

    assert protokoll.valid?
    assert_equal zeitfenster(:morgen_spaet), protokoll.betroffenes_zeitfenster
  end

  test "betroffenes_zeitfenster kommt bei Reservierungs-Einträgen von der Reservierung" do
    assert_equal zeitfenster(:morgen_frueh), protokolle(:anna_reservierung_erstellt).betroffenes_zeitfenster
  end

  test "erfordert eine Reservierung oder ein Zeitfenster" do
    protokoll = Protokoll.new(akteur: benutzer(:max), aktion: :geschlossen, zeitpunkt: Time.current)

    assert_not protokoll.valid?
  end

  test "darf sich nicht gleichzeitig auf Reservierung und Zeitfenster beziehen" do
    protokoll = protokolle(:anna_reservierung_erstellt)
    protokoll.zeitfenster = zeitfenster(:morgen_frueh)

    assert_not protokoll.valid?
  end
end
