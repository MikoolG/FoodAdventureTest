import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["map"];

    connect() {
      // Wait for Google Maps API to load
      if (typeof google !== 'undefined' && google.maps) {
        this.initMap();
        this.loadMarkers();
      } else {
        // If not loaded yet, wait for the global callback
        const checkGoogleMaps = setInterval(() => {
          if (typeof google !== 'undefined' && google.maps) {
            clearInterval(checkGoogleMaps);
            this.initMap();
            this.loadMarkers();
          }
        }, 100);
      }
    }

    initMap() {
      const mapOptions = {
        center: { lat: 37.76008693198700, lng: -122.41880648110100 },
        zoom: 12,
        styles: [
            {
              "featureType": "water",
              "elementType": "geometry",
              "stylers": [{"color": "#00CAE3"}, {"lightness": 0}]
            },
        ],
      };
      this.map = new google.maps.Map(this.mapTarget, mapOptions);
    }

    async loadMarkers() {
      try {
        const response = await fetch('/food_trucks.json');
        if (!response.ok) {
          throw new Error('Network response was not ok ' + response.statusText);
        }
        const data = await response.json();
        const icon = {
            url: 'data:image/svg+xml;utf-8,' + encodeURIComponent(`
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="30">
                    <path d="M10 0C4.5 0 0 4.5 0 10c0 6 10 20 10 20s10-14 10-20c0-5.5-4.5-10-10-10z" fill="#FF7F96"/>
                    <circle cx="10" cy="7" r="3" fill="#914653" />
                </svg>
            `),
            scaledSize: new google.maps.Size(20, 30),
        };
        data.forEach(food_truck => {
          const marker = new google.maps.Marker({
            position: { lat: parseFloat(food_truck.latitude), lng: parseFloat(food_truck.longitude)},
            map: this.map,
            icon: icon,
            title: food_truck.name
          });
        });
      } catch (error) {
        console.error('There has been a problem with your fetch operation:', error);
      }
    }
}
