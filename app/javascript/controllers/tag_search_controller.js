import { Controller } from "@hotwired/stimulus"

// 사이드바 태그 검색 기능
export default class extends Controller {
  static targets = ["input", "container"]
  
  connect() {
    console.log("Tag search controller connected")
    this.originalTags = Array.from(this.containerTarget.children)
  }

  search(event) {
    const query = event.target.value.toLowerCase().trim()
    
    this.originalTags.forEach(tagElement => {
      const tagName = tagElement.dataset.tag
      
      if (!tagName) return
      
      const shouldShow = tagName.includes(query)
      
      if (shouldShow) {
        tagElement.classList.remove('hidden')
        tagElement.style.display = ''
      } else {
        tagElement.classList.add('hidden')
        tagElement.style.display = 'none'
      }
    })

    // 검색 결과가 없는 경우 메시지 표시 (향후 구현)
    const visibleTags = this.originalTags.filter(tag => 
      !tag.classList.contains('hidden')
    )
    
    if (visibleTags.length === 0 && query.length > 0) {
      this.showNoResults(query)
    } else {
      this.hideNoResults()
    }
  }

  showNoResults(query) {
    // 검색 결과 없음 메시지 (향후 확장)
    console.log(`No tags found for: ${query}`)
  }

  hideNoResults() {
    // 검색 결과 없음 메시지 숨기기 (향후 확장)
  }

  clear() {
    this.inputTarget.value = ''
    this.originalTags.forEach(tag => {
      tag.classList.remove('hidden')
      tag.style.display = ''
    })
    this.hideNoResults()
  }
}