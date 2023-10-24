// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"


document.addEventListener('DOMContentLoaded', () => {
    const openModalButton = document.getElementById('beginAdventureBtn');
    const closeModalButton = document.getElementById('closeAdventureBtn');
    const modal = document.getElementById('modal');
    const body = document.body;
  
    if (openModalButton && closeModalButton && modal) {
      openModalButton.addEventListener('click', () => {
        modal.classList.toggle('hidden');
        body.classList.add('no-scroll');
      });
  
      closeModalButton.addEventListener('click', () => {
        modal.classList.add('hidden');
        body.classList.remove('no-scroll');
      });
    }
  });

  document.getElementById("adventure_phone_number").addEventListener('input', function (e) {
    e.target.value = e.target.value.replace(/[^\d\s\-\(\)]+/g, '');
    });