class RegistrierungenController < ApplicationController
  def new
    @benutzer = Benutzer.new
  end

  def create
    @benutzer = Benutzer.new(registrierung_params)

    if @benutzer.save
      anmelden(@benutzer)
      redirect_to root_path, notice: "Konto erfolgreich erstellt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registrierung_params
    params.expect(benutzer: [ :name, :email, :password, :password_confirmation ])
  end
end
