// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
import PageLoaderController from "controllers/page_loader_controller"

// page-loader는 <body>에 항상 붙어 turbo:before-visit로 첫 네비게이션 스피너를
// 구동한다. lazy면 DOM ready~connect 사이 첫 네비에서 스피너가 누락될 수 있어
// eager로 등록한다(@hotwired/stimulus만 의존, 가벼움). 이미 등록되어 있으면
// lazyLoadControllersFrom가 중복 로드하지 않는다.
application.register("page-loader", PageLoaderController)

// lazy 로딩: 나머지 컨트롤러 모듈(과 chart.js/embla/lightgallery 등 무거운 의존성)은
// 페이지에 해당 data-controller 요소가 나타날 때만 fetch된다.
lazyLoadControllersFrom("controllers", application)
