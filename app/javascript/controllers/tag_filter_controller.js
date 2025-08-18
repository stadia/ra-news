import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tag-filter"
export default class extends Controller {
  static targets = ["container", "search", "searchInput"]
  
  connect() {
    console.log("Tag filter controller connected")
    this.originalTags = Array.from(this.containerTarget.children)
  }

  selectTag(event) {
    // 태그 선택 시 URL 업데이트
    const tagName = event.currentTarget.dataset.tag
    const url = new URL(window.location)
    
    if (tagName) {
      url.searchParams.set('tag', tagName)
    } else {
      url.searchParams.delete('tag')
    }
    
    // Turbo를 사용하여 페이지 이동
    Turbo.visit(url.toString())
  }

  clearFilter(event) {
    event.preventDefault()
    
    const url = new URL(window.location)
    url.searchParams.delete('tag')
    
    Turbo.visit(url.toString())
  }

  searchTags(event) {
    const query = event.target.value.toLowerCase()
    const tags = this.containerTarget.children
    
    Array.from(tags).forEach(tag => {
      const tagName = tag.dataset.tag.toLowerCase()
      if (tagName.includes(query)) {
        tag.classList.remove('hidden')
      } else {
        tag.classList.add('hidden')
      }
    })
  }

  // 태그 필터 토글 (향후 확장)
  toggleSearch() {
    this.searchTarget.classList.toggle('hidden')
    if (!this.searchTarget.classList.contains('hidden')) {
      this.searchInputTarget.focus()
    }
  }
}