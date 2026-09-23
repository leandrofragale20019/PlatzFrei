module ApplicationHelper
  MONATSNAMEN = %w[Januar Februar März April Mai Juni Juli August September Oktober November Dezember].freeze

  # One soft, distinct hue per Sportart: :chip tints the monogram, :kopf tints
  # the group header. Each entry stays a single hue (no rainbow inside one),
  # kept light so it never competes with the green/gray/red status badges.
  SPORT_FARBEN = {
    "fussball"   => { chip: "border-emerald-600/20 bg-emerald-50 text-emerald-700", kopf: "bg-emerald-50/70" },
    "fußball"    => { chip: "border-emerald-600/20 bg-emerald-50 text-emerald-700", kopf: "bg-emerald-50/70" },
    "badminton"  => { chip: "border-sky-600/20 bg-sky-50 text-sky-700", kopf: "bg-sky-50/70" },
    "federball"  => { chip: "border-sky-600/20 bg-sky-50 text-sky-700", kopf: "bg-sky-50/70" },
    "tennis"     => { chip: "border-amber-600/20 bg-amber-50 text-amber-700", kopf: "bg-amber-50/70" },
    "basketball" => { chip: "border-orange-600/20 bg-orange-50 text-orange-700", kopf: "bg-orange-50/70" },
    "volleyball" => { chip: "border-violet-600/20 bg-violet-50 text-violet-700", kopf: "bg-violet-50/70" }
  }.freeze

  SPORT_FALLBACK = [
    { chip: "border-violet-600/20 bg-violet-50 text-violet-700", kopf: "bg-violet-50/70" },
    { chip: "border-rose-600/20 bg-rose-50 text-rose-700", kopf: "bg-rose-50/70" },
    { chip: "border-cyan-600/20 bg-cyan-50 text-cyan-700", kopf: "bg-cyan-50/70" },
    { chip: "border-teal-600/20 bg-teal-50 text-teal-700", kopf: "bg-teal-50/70" }
  ].freeze

  def form_input_classes(errors)
    class_names("form-input", "form-input-error" => errors.present?)
  end

  # Colour classes for a Sportart (stable for the known sports, deterministic
  # fallback for any others).
  def sportart_palette(sportart)
    key = sportart.to_s.downcase
    SPORT_FARBEN[key] || SPORT_FALLBACK[key.sum % SPORT_FALLBACK.size]
  end

  # "September 2026" — German month label, independent of the app's I18n locale.
  def monatsname(date)
    "#{MONATSNAMEN[date.month - 1]} #{date.year}"
  end

  # The month the calendar should render. Driven purely by the view-only
  # `monat` param (so month navigation never changes the selected day); falls
  # back to the month of the selected date.
  def angezeigter_monat(fallback)
    wert = params[:monat].presence
    (wert ? Date.parse(wert) : fallback).beginning_of_month
  rescue Date::Error, ArgumentError
    fallback.beginning_of_month
  end

  # Primary navigation for a logged-in member (facility managers see these too).
  def mitglied_navigation
    return [] unless angemeldet?

    [
      { label: "Plätze", path: zeitfenster_path },
      { label: "Meine Reservierungen", path: reservierungen_path },
      { label: "Profil", path: profil_path }
    ]
  end

  # Management console links — only for facility managers. Kept separate from the
  # member navigation so the admin area reads as its own context, not another
  # row of equal links.
  def admin_navigation
    return [] unless angemeldet? && current_benutzer.verantwortlicher?

    [
      { label: "Benutzer", path: admin_benutzer_path },
      { label: "Reservierungen", path: admin_reservierungen_path },
      { label: "Protokoll", path: admin_protokolle_path },
      { label: "Platz sperren", path: new_admin_sperrung_path }
    ]
  end

  # True while the current request is anywhere under the admin console.
  def im_admin_bereich?
    request.path.start_with?("/admin")
  end

  # Highlights the nav entry whose section the current page belongs to, so a
  # detail page (e.g. /zeitfenster/5) still marks its parent ("Plätze") active.
  def nav_aktiv?(pfad)
    return request.path == "/" if pfad == "/"

    request.path == pfad || request.path.start_with?("#{pfad}/")
  end
end
