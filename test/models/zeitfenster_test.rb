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
end
