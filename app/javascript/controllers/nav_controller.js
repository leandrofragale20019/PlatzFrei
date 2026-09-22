import { Controller } from "@hotwired/stimulus"

// Toggles the mobile navigation panel in the app header.
export default class extends Controller {
  static targets = [ "panel", "menuIcon", "closeIcon", "button" ]

  toggle() {
    const expanded = this.panelTarget.classList.toggle("hidden") === false

    this.menuIconTarget.classList.toggle("hidden", expanded)
    this.closeIconTarget.classList.toggle("hidden", !expanded)
    this.buttonTarget.setAttribute("aria-expanded", expanded)
  }
}
