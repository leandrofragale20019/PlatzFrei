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

  test "reserviert_von! legt eine Reservierung an und erhöht lock_version" do
    zf = zeitfenster(:morgen_spaet)
    alter_lock_version = zf.lock_version

    reservierung = zf.reserviert_von!(benutzer(:anna))

    assert reservierung.persisted?
    assert_equal benutzer(:anna), reservierung.benutzer
    assert_equal alter_lock_version + 1, zf.reload.lock_version
  end

  test "reserviert_von! protokolliert die Reservierung atomar" do
    zf = zeitfenster(:morgen_spaet)

    reservierung = zf.reserviert_von!(benutzer(:anna))

    protokoll = reservierung.protokolle.sole
    assert_equal "erstellt", protokoll.aktion
    assert_equal benutzer(:anna), protokoll.akteur
  end

  test "bei einem Konflikt wird kein Protokoll-Eintrag geschrieben" do
    zf_fuer_anna = Zeitfenster.find(zeitfenster(:morgen_spaet).id)
    zf_fuer_max = Zeitfenster.find(zeitfenster(:morgen_spaet).id)

    zf_fuer_anna.reserviert_von!(benutzer(:anna))

    assert_raises(ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique) do
      zf_fuer_max.reserviert_von!(benutzer(:max))
    end

    assert_equal 1, Protokoll.where(reservierung: zeitfenster(:morgen_spaet).reload.aktive_reservierung).count
    assert_not Protokoll.exists?(akteur: benutzer(:max))
  end

  test "konkurrierende Reservierung desselben Zeitfensters: nur die erste gelingt" do
    # Simuliert zwei Mitglieder, die dieselbe Detailseite gleichzeitig offen
    # haben: beide laden das Zeitfenster mit demselben lock_version-Stand,
    # bevor irgendjemand reserviert. Je nach Timing schlägt entweder der
    # partielle Unique-Index (Schritt 1) oder lock_version zu — beide sind
    # gültige Ausprägungen derselben Sicherheitsgarantie.
    zf_fuer_anna = Zeitfenster.find(zeitfenster(:morgen_spaet).id)
    zf_fuer_max = Zeitfenster.find(zeitfenster(:morgen_spaet).id)

    zf_fuer_anna.reserviert_von!(benutzer(:anna))

    assert_raises(ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique) do
      zf_fuer_max.reserviert_von!(benutzer(:max))
    end

    # Nur Annas Reservierung existiert, Zeitfenster hat weiterhin nur einen
    # aktiven Reservierungs-Eintrag.
    assert_equal 1, zeitfenster(:morgen_spaet).reload.reservierungen.reserviert.count
    assert_equal benutzer(:anna), zeitfenster(:morgen_spaet).aktive_reservierung.benutzer
  end

  test "lock_version erkennt eine veraltete Zeitfenster-Referenz auch wenn der Unique-Index (noch) nicht greift" do
    # Zeigt, dass die Sicherheit nicht nur vom Unique-Index kommt: Anna
    # reserviert und storniert sofort wieder (Slot ist laut Index wieder
    # frei), aber Max hält noch eine veraltete lock_version-Referenz von vor
    # Annas Reservierung — sein Versuch muss trotzdem als Konflikt erkannt
    # werden, weil er auf Basis veralteter Daten handelt.
    zf_fuer_anna = Zeitfenster.find(zeitfenster(:morgen_spaet).id)
    zf_fuer_max = Zeitfenster.find(zeitfenster(:morgen_spaet).id)

    reservierung = zf_fuer_anna.reserviert_von!(benutzer(:anna))
    reservierung.update!(status: :storniert)

    assert_raises(ActiveRecord::StaleObjectError) do
      zf_fuer_max.reserviert_von!(benutzer(:max))
    end
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
