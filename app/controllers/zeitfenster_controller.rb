class ZeitfensterController < ApplicationController
  before_action :require_login

  def index
    @datum = parse_datum(params[:datum])
    @sportart = params[:sportart].presence
    @sportarten = Sportplatz.distinct.order(:sportart).pluck(:sportart)

    scope = Zeitfenster.includes(:sportplatz, :reservierungen).where(start: @datum.all_day)
    scope = scope.joins(:sportplatz).where(sportplatz: { sportart: @sportart }) if @sportart
    @zeitfenster = scope.order(:start)
  end

  def show
    @zeitfenster = Zeitfenster.includes(:sportplatz, :reservierungen).find(params[:id])
    @bereits_auf_warteliste = @zeitfenster.wartelisten.exists?(benutzer: current_benutzer)
  end

  private

  def parse_datum(wert)
    wert.present? ? Date.parse(wert) : Date.current
  rescue Date::Error, ArgumentError
    Date.current
  end
end
