// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazy 로딩: 각 컨트롤러 모듈(과 chart.js/embla/lightgallery 등 무거운 의존성)은
// 페이지에 해당 data-controller 요소가 나타날 때만 fetch된다.
lazyLoadControllersFrom("controllers", application)
