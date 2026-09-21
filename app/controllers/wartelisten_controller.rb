class WartelistenController < ApplicationController
  before_action :require_login

  def create
    @zeitfenster = Zeitfenster.find(params[:zeitfenster_id])

    if @zeitfenster.gesperrt?
      redirect_to zeitfenster_zeigen_path(@zeitfenster), alert: "Dieser Platz ist gesperrt."
      return
    end

    if @zeitfenster.aktive_reservierung.blank?
      redirect_to zeitfenster_zeigen_path(@zeitfenster), notice: "Dieses Zeitfenster ist frei — du kannst direkt reservieren."
      return
    end

    eintrag = @zeitfenster.wartelisten.new(benutzer: current_benutzer)
    if eintrag.save
      redirect_to zeitfenster_zeigen_path(@zeitfenster), notice: "Auf die Warteliste eingetragen."
    else
      redirect_to zeitfenster_zeigen_path(@zeitfenster), alert: eintrag.errors.full_messages.to_sentence
    end
  end
end
