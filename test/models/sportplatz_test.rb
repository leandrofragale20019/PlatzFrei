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

  test "sperren! auf einem bereits freien Zeitfenster erzeugt keinen Protokoll-Eintrag" do
    sportplaetze(:feld_eins).sperren!(
      von: zeitfenster(:morgen_spaet).start,
      bis: zeitfenster(:morgen_spaet).ende,
      akteur: benutzer(:max)
    )

    assert zeitfenster(:morgen_spaet).reload.gesperrt?
    assert_equal 0, Protokoll.joins(:reservierung).where(reservierungen: { zeitfenster_id: zeitfenster(:morgen_spaet).id }).count
  end

  test "eine zeitgleiche Reservierung während einer Sperrung wird sicher abgelehnt (keine Geister-Reservierung)" do
    # Anna hat die Detailseite bereits offen (veraltete lock_version-Referenz),
    # bevor der Verantwortliche den Platz für genau dieses Zeitfenster sperrt.
    zf_fuer_anna = Zeitfenster.find(zeitfenster(:morgen_spaet).id)

    sportplaetze(:feld_eins).sperren!(
      von: zeitfenster(:morgen_spaet).start,
      bis: zeitfenster(:morgen_spaet).ende,
      akteur: benutzer(:max)
    )

    assert_raises(ActiveRecord::StaleObjectError) do
      zf_fuer_anna.reserviert_von!(benutzer(:anna))
    end

    assert zeitfenster(:morgen_spaet).reload.gesperrt?
    assert_nil zeitfenster(:morgen_spaet).aktive_reservierung
  end
end
