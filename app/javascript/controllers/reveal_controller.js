import { Controller } from "@hotwired/stimulus"

// Gentle fade-up-on-enter for a section. Progressive enhancement: the hidden
// state is applied here in JS, so users without JS (or with reduced motion)
// always see fully rendered content. Optionally staggers direct children when
// data-reveal-stagger-value is set.
export default class extends Controller {
  static values = { stagger: Boolean }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.targets = this.staggerValue ? Array.from(this.element.children) : [ this.element ]

    this.targets.forEach((el, i) => {
      el.classList.add("reveal-init", "reveal-ready")
      el.style.transitionDelay = `${Math.min(i * 80, 400)}ms`
    })

    this.observer = new IntersectionObserver(this.onIntersect, { threshold: 0.12, rootMargin: "0px 0px -8% 0px" })
    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  onIntersect = (entries) => {
    if (!entries.some((entry) => entry.isIntersecting)) return

    this.targets.forEach((el) => {
      el.classList.add("reveal-in")
      el.classList.remove("reveal-init")
    })
    this.observer.disconnect()
  }
}
