class Admin::ProtokolleController < Admin::BaseController
  def index
    @protokolle = Protokoll.includes(:akteur, { zeitfenster: :sportplatz }, reservierung: [ :benutzer, { zeitfenster: :sportplatz } ]).order(zeitpunkt: :desc)
  end
end
