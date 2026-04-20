import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["channelName"]
  static params = ["name"]

  select({ params: { name } }) {
    this.channelNameTarget.value = name
  }
}
