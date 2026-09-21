class ReservierungenController < ApplicationController
  before_action :require_login

  def index
    @reservierungen = current_benutzer.reservierungen.reserviert.includes(zeitfenster: :sportplatz).order(:erstellt_am)
    @wartelisten = current_benutzer.wartelisten.includes(zeitfenster: :sportplatz)
  end

  def create
    @zeitfenster = Zeitfenster.find(params[:zeitfenster_id])

    if @zeitfenster.gesperrt?
      redirect_to zeitfenster_zeigen_path(@zeitfenster), alert: "Dieser Platz ist gesperrt."
      return
    end

    @zeitfenster.reserviert_von!(current_benutzer)
    redirect_to reservierungen_path, notice: "Reservierung bestätigt."
  rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique
    redirect_to zeitfenster_zeigen_path(@zeitfenster), alert: konflikt_hinweis(@zeitfenster)
  end

  def destroy
    reservierung = current_benutzer.reservierungen.find(params[:id])
    reservierung.stornieren!(akteur: current_benutzer)
    redirect_to reservierungen_path, notice: "Reservierung storniert."
  end

  private

  def konflikt_hinweis(zeitfenster)
    naechstes = Zeitfenster.frei
      .where(sportplatz_id: zeitfenster.sportplatz_id)
      .where("start > ?", zeitfenster.start)
      .order(:start)
      .first

    if naechstes
      "Dieses Zeitfenster wurde inzwischen von jemand anderem reserviert. " \
        "Nächstes freies Zeitfenster: #{naechstes.start.strftime('%d.%m.%Y %H:%M')}."
    else
      "Dieses Zeitfenster wurde inzwischen von jemand anderem reserviert."
    end
  end
end
