class Admin::BenutzerController < ApplicationController
  def index
    @benutzer = Benutzer.order(:name)
  end

  def show
    @benutzer = Benutzer.find(params[:id])
  end
end
