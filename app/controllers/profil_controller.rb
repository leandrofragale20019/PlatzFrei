class ProfilController < ApplicationController
  before_action :require_login
  before_action :set_benutzer

  def show
  end

  def edit
  end

  def update
    if @benutzer.update(profil_params)
      redirect_to profil_path, notice: "Profil aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_benutzer
    @benutzer = current_benutzer
  end

  def profil_params
    params_hash = params.expect(benutzer: [ :name, :email, :password, :password_confirmation ])
    params_hash = params_hash.except(:password, :password_confirmation) if params_hash[:password].blank?
    params_hash
  end
end
