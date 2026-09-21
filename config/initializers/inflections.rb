# Deutsche Pluralformen für die PlatzFrei-Domänenbegriffe, damit Tabellennamen,
# Controller und Assoziationen korrektes Deutsch verwenden (z.B.
# sportplatz.zeitfenster, RegistrierungenController) statt Rails' englischer
# Standardpluralisierung.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "sportplatz", "sportplaetze"
  inflect.irregular "reservierung", "reservierungen"
  inflect.irregular "protokoll", "protokolle"
  inflect.irregular "warteliste", "wartelisten"
  inflect.irregular "registrierung", "registrierungen"
  inflect.irregular "sitzung", "sitzungen"
  inflect.uncountable %w[zeitfenster benutzer]
end
