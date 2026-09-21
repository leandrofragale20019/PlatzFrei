class Admin::ProtokolleController < Admin::BaseController
  def index
    @protokolle = Protokoll.includes(:akteur, reservierung: [ :benutzer, { zeitfenster: :sportplatz } ]).order(zeitpunkt: :desc)
  end
end
