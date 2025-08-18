import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tag-filter"
export default class extends Controller {
  static targets = ["container", "search", "searchInput", "expandableContent", "toggleIcon", "toggleText", "toggleButton"]
  
  connect() {
    console.log("Tag filter controller connected")
    this.originalTags = Array.from(this.containerTarget.children)
    this.isExpanded = false
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

  toggleExpanded(event) {
    event.preventDefault()
    this.isExpanded = !this.isExpanded
    
    const content = this.expandableContentTarget
    const icon = this.toggleIconTarget
    
    if (this.isExpanded) {
      // 드롭다운 열기
      content.classList.remove('opacity-0', 'invisible')
      content.style.transform = 'translateY(0)'
      icon.style.transform = "rotate(180deg)"
    } else {
      // 드롭다운 닫기
      content.classList.add('opacity-0', 'invisible')
      content.style.transform = 'translateY(-10px)'
      icon.style.transform = "rotate(0deg)"
    }
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