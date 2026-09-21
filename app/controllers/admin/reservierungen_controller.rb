class Admin::ReservierungenController < Admin::BaseController
  def index
    @reservierungen = Reservierung.reserviert.includes(:benutzer, zeitfenster: :sportplatz).order(:erstellt_am)
  end

  def destroy
    reservierung = Reservierung.find(params[:id])
    reservierung.stornieren!(akteur: current_benutzer)
    redirect_to admin_reservierungen_path, notice: "Reservierung storniert."
  end
end
