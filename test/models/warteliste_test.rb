require "test_helper"

class WartelisteTest < ActiveSupport::TestCase
  test "gültig mit Fixture-Daten" do
    assert wartelisten(:max_wartet_auf_morgen_frueh).valid?
  end

  test "dieselbe Person kann sich nicht doppelt für dasselbe Zeitfenster eintragen" do
    duplikat = Warteliste.new(
      zeitfenster: wartelisten(:max_wartet_auf_morgen_frueh).zeitfenster,
      benutzer: wartelisten(:max_wartet_auf_morgen_frueh).benutzer
    )

    assert_not duplikat.valid?
  end

  test "dieselbe Person kann sich für unterschiedliche Zeitfenster eintragen" do
    anderes_zeitfenster = Zeitfenster.create!(
      sportplatz: sportplaetze(:feld_eins),
      start: zeitfenster(:morgen_frueh).ende,
      ende: zeitfenster(:morgen_frueh).ende + 1.hour
    )

    eintrag = Warteliste.new(zeitfenster: anderes_zeitfenster, benutzer: wartelisten(:max_wartet_auf_morgen_frueh).benutzer)
    assert eintrag.valid?
  end
end
