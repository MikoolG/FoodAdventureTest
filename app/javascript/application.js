// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"


function toggleModal() {
    const modal = document.getElementById('adventureModal');
    modal.classList.toggle('hidden');
}