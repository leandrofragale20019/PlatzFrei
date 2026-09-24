require "test_helper"

class ZeitfensterTest < ActiveSupport::TestCase
  test "gültig mit Fixture-Daten" do
    assert zeitfenster(:morgen_frueh).valid?
  end

  test "ende muss nach start liegen" do
    zf = zeitfenster(:morgen_frueh)
    zf.ende = zf.start
    assert_not zf.valid?
    assert_includes zf.errors[:ende], "muss nach dem Start liegen"
  end

  test "überlappende Zeitfenster für denselben Sportplatz sind ungültig" do
    bestehend = zeitfenster(:morgen_frueh)
    ueberlappend = Zeitfenster.new(
      sportplatz: bestehend.sportplatz,
      start: bestehend.start + 10.minutes,
      ende: bestehend.ende + 10.minutes
    )

    assert_not ueberlappend.valid?
    assert_includes ueberlappend.errors[:base], "überlappt mit einem bestehenden Zeitfenster für diesen Sportplatz"
  end

  test "nicht überlappende Zeitfenster für denselben Sportplatz sind gültig" do
    bestehend = zeitfenster(:morgen_frueh)
    getrennt = Zeitfenster.new(
      sportplatz: bestehend.sportplatz,
      start: bestehend.ende,
      ende: bestehend.ende + 1.hour
    )

    assert getrennt.valid?
  end

  test "gleiche Zeiten auf unterschiedlichen Sportplätzen überlappen nicht" do
    bestehend = zeitfenster(:morgen_frueh)
    anderer_platz = Sportplatz.create!(name: "Feld 2", sportart: "Tennis")
    gleiche_zeit_anderer_platz = Zeitfenster.new(sportplatz: anderer_platz, start: bestehend.start, ende: bestehend.ende)

    assert gleiche_zeit_anderer_platz.valid?
  end

  test "reserviert_von! legt eine Reservierung für das Zeitfenster an" do
    zf = zeitfenster(:morgen_spaet)

    reservierung = zf.reserviert_von!(benutzer(:anna))

    assert reservierung.persisted?
    assert_equal benutzer(:anna), reservierung.benutzer
    assert_equal zf, reservierung.zeitfenster
  end

  test "reserviert_von! protokolliert die Reservierung atomar" do
    zf = zeitfenster(:morgen_spaet)

    reservierung = zf.reserviert_von!(benutzer(:anna))

    protokoll = reservierung.protokolle.sole
    assert_equal "erstellt", protokoll.aktion
    assert_equal benutzer(:anna), protokoll.akteur
  end

  test "bei einem Reservierungs-Konflikt wird kein Protokoll-Eintrag geschrieben" do
    zf_fuer_anna = Zeitfenster.find(zeitfenster(:morgen_spaet).id)
    zf_fuer_max = Zeitfenster.find(zeitfenster(:morgen_spaet).id)

    zf_fuer_anna.reserviert_von!(benutzer(:anna))

    assert_raises(ActiveRecord::RecordNotUnique) do
      zf_fuer_max.reserviert_von!(benutzer(:max))
    end

    assert_equal 1, Protokoll.where(reservierung: zeitfenster(:morgen_spaet).reload.aktive_reservierung).count
    assert_not Protokoll.exists?(akteur: benutzer(:max))
  end

  test "konkurrierende Reservierung desselben Zeitfensters: nur die erste gelingt (Unique-Index)" do
    # Zwei Mitglieder haben dieselbe Detailseite offen und reservieren fast
    # gleichzeitig. Gegen die Doppelbuchung schützt allein der partielle
    # Unique-Index auf reservierungen: der erste INSERT gelingt, der zweite
    # scheitert mit RecordNotUnique. lock_version spielt hier keine Rolle (es
    # schützt nur UPDATEs, nicht das INSERT einer neuen Reservierung).
    zf_fuer_anna = Zeitfenster.find(zeitfenster(:morgen_spaet).id)
    zf_fuer_max = Zeitfenster.find(zeitfenster(:morgen_spaet).id)

    zf_fuer_anna.reserviert_von!(benutzer(:anna))

    assert_raises(ActiveRecord::RecordNotUnique) do
      zf_fuer_max.reserviert_von!(benutzer(:max))
    end

    # Nur Annas Reservierung existiert, Zeitfenster hat weiterhin nur einen
    # aktiven Reservierungs-Eintrag.
    assert_equal 1, zeitfenster(:morgen_spaet).reload.reservierungen.reserviert.count
    assert_equal benutzer(:anna), zeitfenster(:morgen_spaet).aktive_reservierung.benutzer
  end

  test "frei-Scope schliesst gesperrte und bereits reservierte Zeitfenster aus" do
    frei = Zeitfenster.frei

    assert_includes frei, zeitfenster(:morgen_spaet)
    assert_not_includes frei, zeitfenster(:morgen_gesperrt)
    assert_not_includes frei, zeitfenster(:morgen_frueh)
  end

  test "aktive_reservierung liefert die reservierte Buchung oder nil" do
    assert_equal reservierungen(:anna_bucht_morgen_frueh), zeitfenster(:morgen_frueh).aktive_reservierung
    assert_nil zeitfenster(:morgen_spaet).aktive_reservierung
  end
end
