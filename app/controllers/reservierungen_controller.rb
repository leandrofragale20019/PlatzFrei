class ReservierungenController < ApplicationController
  before_action :require_login

  def index
    @reservierungen = current_benutzer.reservierungen.reserviert.includes(zeitfenster: :sportplatz).order(:erstellt_am)
    @wartelisten = current_benutzer.wartelisten.includes(zeitfenster: [ :sportplatz, :reservierungen ])
    # Mitteilung an betroffene Mitglieder (FR4): kommende Reservierungen, die
    # durch eine Platzsperrung storniert wurden.
    @durch_sperrung_storniert = current_benutzer.reservierungen.storniert
      .where(id: Protokoll.geschlossen.select(:reservierung_id))
      .joins(:zeitfenster).where(zeitfenster: { start: Time.current.. })
      .includes(zeitfenster: :sportplatz).order("zeitfenster.start")
  end

  def create
    @zeitfenster = Zeitfenster.find(params[:zeitfenster_id])

    if @zeitfenster.gesperrt?
      redirect_to zeitfenster_zeigen_path(@zeitfenster), alert: "Dieser Platz ist gesperrt."
      return
    end

    @zeitfenster.reserviert_von!(current_benutzer)
    redirect_to reservierungen_path, notice: "Reservierung bestätigt."
  rescue ActiveRecord::RecordNotUnique
    # Einziger Konfliktpfad beim Erstellen: der partielle Unique-Index hat eine
    # zeitgleiche zweite Reservierung für denselben Slot abgewiesen.
    redirect_to zeitfenster_zeigen_path(@zeitfenster), alert: konflikt_hinweis(@zeitfenster)
  end

  def destroy
    reservierung = current_benutzer.reservierungen.find(params[:id])
    # lock_version kommt aus dem Formular ("Meine Reservierungen"): so greift
    # Optimistic Locking auch über Requests hinweg, wenn das Mitglied auf einer
    # veralteten Seite storniert.
    reservierung.lock_version = params[:lock_version] if params[:lock_version].present?
    reservierung.stornieren!(akteur: current_benutzer)
    redirect_to reservierungen_path, notice: "Reservierung storniert."
  rescue ActiveRecord::StaleObjectError
    # Optimistic Locking: die Reservierung wurde zwischenzeitlich bereits
    # verändert (z.B. vom/von der Platzverantwortlichen durch eine Sperrung
    # storniert). Kein Fehler für das Mitglied – der Slot ist ohnehin weg.
    hinweis = if reservierung.reload.durch_sperrung_storniert?
      "Diese Reservierung wurde inzwischen durch eine Platzsperrung storniert."
    else
      "Diese Reservierung wurde inzwischen bereits storniert."
    end
    redirect_to reservierungen_path, alert: hinweis
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
