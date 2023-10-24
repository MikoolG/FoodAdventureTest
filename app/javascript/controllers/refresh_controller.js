import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
      this.refreshIfNeeded();
    }
  
    refreshIfNeeded() {
      // If the 'homeVisited' is 'true', refresh the page and then set it to 'refreshed'.
      if (sessionStorage.getItem('homeVisited') === 'true') {
        sessionStorage.setItem('homeVisited', 'refreshed');
        window.location.reload(true);
      } else if (!sessionStorage.getItem('homeVisited')) {
        // If it's the first visit or the session storage item doesn't exist, set it to 'true'.
        sessionStorage.setItem('homeVisited', 'true');
      }
      // If the 'homeVisited' is 'refreshed', we do nothing, preventing further refreshes.
    }
  }