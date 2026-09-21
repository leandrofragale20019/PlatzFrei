# Deutsche Pluralformen für die PlatzFrei-Domänenbegriffe, damit Tabellennamen
# und Assoziationen korrektes Deutsch verwenden (z.B. sportplatz.zeitfenster,
# sportplatz.wartelisten) statt Rails' englischer Standardpluralisierung.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "sportplatz", "sportplaetze"
  inflect.irregular "reservierung", "reservierungen"
  inflect.irregular "protokoll", "protokolle"
  inflect.irregular "warteliste", "wartelisten"
  inflect.uncountable %w[zeitfenster benutzer]
end
