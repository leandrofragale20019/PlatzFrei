require "test_helper"

class SportplatzTest < ActiveSupport::TestCase
  test "gültig mit Fixture-Daten" do
    assert sportplaetze(:feld_eins).valid?
  end

  test "erfordert einen Namen" do
    sportplaetze(:feld_eins).name = nil
    assert_not sportplaetze(:feld_eins).valid?
  end

  test "erfordert eine Sportart" do
    sportplaetze(:feld_eins).sportart = nil
    assert_not sportplaetze(:feld_eins).valid?
  end

  test "kennt seine Zeitfenster" do
    assert_includes sportplaetze(:feld_eins).zeitfenster, zeitfenster(:morgen_frueh)
  end

  test "sperren! sperrt betroffene Zeitfenster und storniert+protokolliert aktive Reservierungen" do
    reservierung = reservierungen(:anna_bucht_morgen_frueh)

    sportplaetze(:feld_eins).sperren!(
      von: zeitfenster(:morgen_frueh).start - 1.hour,
      bis: zeitfenster(:morgen_spaet).ende + 1.hour,
      akteur: benutzer(:max)
    )

    assert zeitfenster(:morgen_frueh).reload.gesperrt?
    assert zeitfenster(:morgen_spaet).reload.gesperrt?
    assert_equal "storniert", reservierung.reload.status

    protokoll = reservierung.protokolle.find_by!(aktion: :geschlossen)
    assert_equal benutzer(:max), protokoll.akteur
  end

  test "sperren! lässt Zeitfenster ausserhalb des Zeitraums und auf anderen Sportplätzen unangetastet" do
    sportplaetze(:feld_eins).sperren!(
      von: zeitfenster(:morgen_frueh).start,
      bis: zeitfenster(:morgen_frueh).ende,
      akteur: benutzer(:max)
    )

    assert_not zeitfenster(:morgen_spaet).reload.gesperrt?
    assert_not zeitfenster(:halle_slot).reload.gesperrt?
  end

  test "QA4: sperren! auf einem freien Zeitfenster protokolliert die Sperrung am Zeitfenster" do
    zf = zeitfenster(:morgen_spaet)

    assert_difference -> { Protokoll.count }, 1 do
      sportplaetze(:feld_eins).sperren!(von: zf.start, bis: zf.ende, akteur: benutzer(:max))
    end

    assert zf.reload.gesperrt?
    protokoll = zf.protokolle.sole
    assert_equal "geschlossen", protokoll.aktion
    assert_equal benutzer(:max), protokoll.akteur
    assert_nil protokoll.reservierung
  end

  test "QA4: sperren! protokolliert pro Zeitfenster genau einen Eintrag (mit oder ohne Reservierung)" do
    reservierung = reservierungen(:anna_bucht_morgen_frueh)

    assert_difference -> { Protokoll.geschlossen.count }, 2 do
      sportplaetze(:feld_eins).sperren!(
        von: zeitfenster(:morgen_frueh).start,
        bis: zeitfenster(:morgen_spaet).ende,
        akteur: benutzer(:max)
      )
    end

    assert_equal 1, reservierung.protokolle.geschlossen.count
    assert_not zeitfenster(:morgen_frueh).protokolle.exists?
    assert_equal 1, zeitfenster(:morgen_spaet).protokolle.geschlossen.count
  end

  test "sperren! überspringt bereits gesperrte Zeitfenster (keine Doppeleinträge)" do
    zf = zeitfenster(:morgen_gesperrt)

    assert_no_difference -> { Protokoll.count } do
      sportplaetze(:feld_eins).sperren!(von: zf.start, bis: zf.ende, akteur: benutzer(:max))
    end

    assert zf.reload.gesperrt?
  end

  test "QA4: entsperren! hebt die Sperrung auf und protokolliert das pro Zeitfenster" do
    zf = zeitfenster(:morgen_gesperrt)

    sportplaetze(:feld_eins).entsperren!(von: zf.start, bis: zf.ende, akteur: benutzer(:max))

    assert_not zf.reload.gesperrt?
    protokoll = zf.protokolle.sole
    assert_equal "entsperrt", protokoll.aktion
    assert_equal benutzer(:max), protokoll.akteur
  end

  test "entsperren! lässt nicht gesperrte Zeitfenster unangetastet und protokolliert sie nicht" do
    assert_difference -> { Protokoll.entsperrt.count }, 1 do
      sportplaetze(:feld_eins).entsperren!(
        von: zeitfenster(:morgen_frueh).start,
        bis: zeitfenster(:morgen_gesperrt).ende,
        akteur: benutzer(:max)
      )
    end

    assert_not zeitfenster(:morgen_frueh).protokolle.exists?
    assert_not zeitfenster(:morgen_spaet).protokolle.exists?
  end

  test "QA5: Stornierung (Mitglied) vs. Sperrung (Admin) derselben Reservierung – der spätere Schreibzugriff wirft StaleObjectError" do
    # Anna hat ihre Reservierung auf "Meine Reservierungen" offen (veralteter
    # lock_version-Stand). Zeitgleich sperrt der Verantwortliche den Platz und
    # storniert dabei genau diese Reservierung – er schreibt zuerst.
    anna_referenz = Reservierung.find(reservierungen(:anna_bucht_morgen_frueh).id)

    sportplaetze(:feld_eins).sperren!(
      von: zeitfenster(:morgen_frueh).start,
      bis: zeitfenster(:morgen_frueh).ende,
      akteur: benutzer(:max)
    )

    # Annas verspäteter Stornierungs-Schreibzugriff arbeitet auf veralteten
    # Daten und wird per Optimistic Locking (lock_version) erkannt.
    assert_raises(ActiveRecord::StaleObjectError) do
      anna_referenz.stornieren!(akteur: benutzer(:anna))
    end

    # Die Reservierung wurde durch die Sperrung genau einmal storniert.
    reservierung = reservierungen(:anna_bucht_morgen_frueh).reload
    assert_equal "storniert", reservierung.status
    assert_equal 1, reservierung.protokolle.where(aktion: :geschlossen).count
  end

  test "QA5: storniert ein Mitglied zuerst, bricht eine gleichzeitige Sperrung nicht ab" do
    # Anna storniert ihre Reservierung selbst; danach sperrt der Verantwortliche
    # den Platz. sperren! findet keine aktive Reservierung mehr und läuft
    # trotzdem sauber durch (Slot wird gesperrt, keine Doppel-Stornierung).
    reservierungen(:anna_bucht_morgen_frueh).stornieren!(akteur: benutzer(:anna))

    assert_nothing_raised do
      sportplaetze(:feld_eins).sperren!(
        von: zeitfenster(:morgen_frueh).start,
        bis: zeitfenster(:morgen_frueh).ende,
        akteur: benutzer(:max)
      )
    end

    assert zeitfenster(:morgen_frueh).reload.gesperrt?

    reservierung = reservierungen(:anna_bucht_morgen_frueh).reload
    assert_equal "storniert", reservierung.status
    assert reservierung.protokolle.exists?(aktion: :storniert)
    assert_not reservierung.protokolle.exists?(aktion: :geschlossen)
    # Die Sperrung selbst ist trotzdem protokolliert – am Zeitfenster (QA4).
    assert zeitfenster(:morgen_frueh).protokolle.geschlossen.exists?
  end

  test "QA5: storniert ein Mitglied zwischen Laden und Schliessen, wird übersprungen und die Sperrung am Zeitfenster protokolliert" do
    sportplatz = sportplaetze(:feld_eins)
    anna = benutzer(:anna)
    # Simuliert das Race-Fenster: sperren! hat die aktive Reservierung schon
    # geladen, da storniert Anna sie über ein eigenes Objekt (eigener Request).
    # Das Schliessen läuft danach auf veraltetem lock_version-Stand.
    sportplatz.define_singleton_method(:reservierung_schliessen) do |reservierung, akteur|
      Reservierung.find(reservierung.id).stornieren!(akteur: anna)
      super(reservierung, akteur)
    end

    assert_nothing_raised do
      sportplatz.sperren!(
        von: zeitfenster(:morgen_frueh).start,
        bis: zeitfenster(:morgen_frueh).ende,
        akteur: benutzer(:max)
      )
    end

    assert zeitfenster(:morgen_frueh).reload.gesperrt?
    reservierung = reservierungen(:anna_bucht_morgen_frueh).reload
    assert_equal "storniert", reservierung.status
    assert_equal 1, reservierung.protokolle.storniert.count
    assert_not reservierung.protokolle.geschlossen.exists?
    assert_equal 1, zeitfenster(:morgen_frueh).protokolle.geschlossen.count
  end
end
