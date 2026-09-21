class Admin::SperrungenController < Admin::BaseController
  def new
    @sportplaetze = Sportplatz.order(:name)
  end

  def create
    sportplatz = Sportplatz.find(params[:sportplatz_id])
    von = parse_zeit(params[:von])
    bis = parse_zeit(params[:bis])

    if von.blank? || bis.blank? || bis <= von
      redirect_to new_admin_sperrung_path, alert: "Bitte einen gültigen Zeitraum angeben."
      return
    end

    sportplatz.sperren!(von: von, bis: bis, akteur: current_benutzer)
    redirect_to zeitfenster_path, notice: "#{sportplatz.name} wurde für den gewählten Zeitraum gesperrt."
  rescue ActiveRecord::StaleObjectError
    redirect_to new_admin_sperrung_path, alert: "Beim Sperren gab es einen Konflikt (z.B. eine zeitgleiche Reservierung) — bitte erneut versuchen."
  end

  private

  def parse_zeit(wert)
    Time.zone.parse(wert) if wert.present?
  rescue ArgumentError
    nil
  end
end
