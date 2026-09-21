module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_benutzer
    helper_method :current_benutzer, :angemeldet?
  end

  private

  def set_current_benutzer
    Current.benutzer = Benutzer.find_by(id: session[:benutzer_id])
  end

  def current_benutzer
    Current.benutzer
  end

  def angemeldet?
    current_benutzer.present?
  end

  def require_login
    redirect_to new_sitzung_path, alert: "Bitte melde dich zuerst an." unless angemeldet?
  end

  def require_verantwortlicher
    redirect_to root_path, alert: "Kein Zugriff." unless current_benutzer&.verantwortlicher?
  end

  def anmelden(benutzer)
    reset_session
    session[:benutzer_id] = benutzer.id
    Current.benutzer = benutzer
  end

  def abmelden
    reset_session
    Current.benutzer = nil
  end
end
