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
end
