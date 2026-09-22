# Rails wraps invalid form fields in a <div class="field_with_errors">,
# which breaks the flex/block layout our form_field partial builds around
# each input. Error styling and messages are shown explicitly by that
# partial instead, so leave the field markup untouched here.
ActionView::Base.field_error_proc = proc { |html_tag, _instance| html_tag }
