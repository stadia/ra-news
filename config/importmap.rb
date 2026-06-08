# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/utils", under: "utils"
pin "@floating-ui/dom", to: "@floating-ui--dom.js" # @1.7.6
pin "@floating-ui/core", to: "@floating-ui--core.js" # @1.7.5
pin "@floating-ui/utils", to: "@floating-ui--utils.js" # @0.2.11
pin "@floating-ui/utils/dom", to: "@floating-ui--utils--dom.js" # @0.2.11
pin "embla-carousel" # @8.6.0
pin "lexxy", to: "lexxy.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "chart.js" # @4.5.1
pin "@kurkle/color", to: "@kurkle--color.js" # @0.3.4
pin "@stimulus-components/lightbox", to: "@stimulus-components--lightbox.js" # @4.0.0
pin "lightgallery" # @2.9.0
pin "@stimulus-components/character-counter", to: "@stimulus-components--character-counter.js" # @5.1.0
