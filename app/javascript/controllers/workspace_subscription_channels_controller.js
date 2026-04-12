import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="workspace-subscription-channels"
export default class extends Controller {
  static targets = ["channelSelect", "channelName", "feedback"]
  static values = {
    url: String,
    selectedId: String,
    selectedName: String,
    loaded: { type: Boolean, default: false },
    loading: { type: Boolean, default: false }
  }

  connect() {
    if (this.hasChannelNameTarget && this.selectedNameValue && !this.channelNameTarget.value) {
      this.channelNameTarget.value = this.selectedNameValue
    }
  }

  async load() {
    if (this.loadedValue || this.loadingValue || !this.hasChannelSelectTarget) return

    this.loadingValue = true
    this.channelSelectTarget.disabled = true
    this.setFeedback("채널 목록을 불러오는 중입니다.")

    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" }
      })
      const payload = await response.json()

      if (!response.ok) {
        throw new Error(payload.error || "채널 목록을 불러오지 못했습니다.")
      }

      this.populateOptions(payload.channels || [])
      this.loadedValue = true
      this.channelSelectTarget.disabled = false

      if (this.channelSelectTarget.options.length <= 1) {
        this.setFeedback("선택할 수 있는 채널이 없습니다.")
      } else {
        this.setFeedback("채널을 선택한 뒤 저장해 주세요.")
      }
    } catch (error) {
      this.channelSelectTarget.disabled = false
      this.setFeedback(error.message, true)
    } finally {
      this.loadingValue = false
    }
  }

  syncSelection() {
    if (!this.hasChannelSelectTarget || !this.hasChannelNameTarget) return

    const option = this.channelSelectTarget.selectedOptions[0]
    if (!option || !option.value) {
      this.channelNameTarget.value = ""
      return
    }

    this.channelNameTarget.value = option.dataset.channelName || this.selectedNameValue || ""
  }

  populateOptions(channels) {
    const selectedId = this.currentSelectedId
    const fragment = document.createDocumentFragment()

    fragment.appendChild(this.buildOption("채널을 선택해 주세요", "", { selected: selectedId === "" }))

    channels.forEach((channel) => {
      fragment.appendChild(
        this.buildOption(
          `#${channel.name}`,
          channel.id,
          {
            channelName: channel.name,
            selected: channel.id === selectedId
          }
        )
      )
    })

    this.channelSelectTarget.replaceChildren(fragment)
  }

  buildOption(label, value, { channelName = "", selected = false } = {}) {
    const option = document.createElement("option")
    option.textContent = label
    option.value = value
    option.selected = selected
    option.dataset.channelName = channelName
    return option
  }

  setFeedback(message, isError = false) {
    if (!this.hasFeedbackTarget) return

    this.feedbackTarget.textContent = message
    this.feedbackTarget.classList.toggle("text-danger-text", isError)
    this.feedbackTarget.classList.toggle("text-content-muted", !isError)
  }

  get currentSelectedId() {
    return this.channelSelectTarget.value || this.selectedIdValue || ""
  }
}
