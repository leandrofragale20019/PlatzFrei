class SitzungenController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_sitzung_path, alert: "Zu viele Versuche. Bitte später erneut versuchen." }

  def new
  end

  def create
    benutzer = Benutzer.authenticate_by(email: params[:email], password: params[:password])

    if benutzer
      anmelden(benutzer)
      redirect_to root_path, notice: "Erfolgreich angemeldet."
    else
      flash.now[:alert] = "E-Mail oder Passwort ungültig."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    abmelden
    redirect_to root_path, notice: "Erfolgreich abgemeldet."
  end
end
