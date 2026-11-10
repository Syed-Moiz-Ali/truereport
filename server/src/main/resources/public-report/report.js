/* TrueReport Public Report Interactive Features */

function openLightbox(el) {
  var dialog = document.getElementById('photo-lightbox');
  var img = document.getElementById('lightbox-img');
  var caption = document.getElementById('lightbox-caption');
  var note = document.getElementById('lightbox-note');
  if (!dialog || !img) return;

  var imgSrc = el.getAttribute('data-img');
  if (imgSrc) {
    img.src = imgSrc;
  }
  if (caption) {
    caption.textContent = el.getAttribute('data-caption') || '';
  }
  if (note) {
    note.textContent = el.getAttribute('data-note') || '';
  }

  if (typeof dialog.showModal === 'function') {
    dialog.showModal();
  } else {
    dialog.setAttribute('open', 'true');
  }
  document.body.classList.add('modal-open');
}

function closeLightbox() {
  var dialog = document.getElementById('photo-lightbox');
  if (!dialog) return;
  if (typeof dialog.close === 'function') {
    dialog.close();
  } else {
    dialog.removeAttribute('open');
  }
  document.body.classList.remove('modal-open');
}

document.addEventListener('DOMContentLoaded', function () {
  // Visual Inspection Filter Tabs
  var filterButtons = document.querySelectorAll('.visual-filter-bar .filter-chip');
  var cards = document.querySelectorAll('.visual-part-card');

  filterButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      filterButtons.forEach(function (b) { b.classList.remove('active'); });
      btn.classList.add('active');
      var filter = btn.getAttribute('data-filter');

      cards.forEach(function (card) {
        var cardStatus = card.getAttribute('data-status');
        if (filter === 'all' || cardStatus === filter) {
          card.style.display = '';
        } else {
          card.style.display = 'none';
        }
      });
    });
  });

  // Showcase Filter Tabs
  var showcaseButtons = document.querySelectorAll('.showcase-filter-chip');
  var showcaseCards = document.querySelectorAll('.showcase-item-card');

  showcaseButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      showcaseButtons.forEach(function (b) { b.classList.remove('active'); });
      btn.classList.add('active');
      var cat = btn.getAttribute('data-cat');

      showcaseCards.forEach(function (card) {
        var cardCat = card.getAttribute('data-cat');
        if (cat === 'all' || cardCat === cat) {
          card.style.display = '';
        } else {
          card.style.display = 'none';
        }
      });
    });
  });

  // Lightbox click-outside-to-close & Esc key
  var dialog = document.getElementById('photo-lightbox');
  if (dialog) {
    dialog.addEventListener('click', function (e) {
      if (e.target === dialog) {
        closeLightbox();
      }
    });
    dialog.addEventListener('cancel', function () {
      document.body.classList.remove('modal-open');
    });
  }
});
