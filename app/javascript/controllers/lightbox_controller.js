import Lightbox from "@stimulus-components/lightbox";

export default class extends Lightbox {
  get defaultOptions() {
    return {
      selector: "a",
      download: false,
      counter: true,
      loop: true,
      animateThumb: false,
      allowMediaOverlap: true,
      toggleThumb: true,
    };
  }
}
