module ApplicationHelper
  def form_input_classes(errors)
    class_names("form-input", "form-input-error" => errors.present?)
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
