class Admin::ReservierungenController < Admin::BaseController
  def index
    @reservierungen = Reservierung.reserviert.includes(:benutzer, zeitfenster: :sportplatz).order(:erstellt_am)
  end

  def destroy
    reservierung = Reservierung.find(params[:id])
    reservierung.stornieren!(akteur: current_benutzer)
    redirect_to admin_reservierungen_path, notice: "Reservierung storniert."
  rescue ActiveRecord::StaleObjectError
    redirect_to admin_reservierungen_path, alert: "Diese Reservierung wurde inzwischen bereits storniert."
  end
end
