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

  // Showcase Category Filter (Tabs: All, Exterior, Interior, Mechanical)
  var galleryFilterButtons = document.querySelectorAll('[data-gallery-filter]');
  var galleryCards = document.querySelectorAll('.gallery-photo-card');

  galleryFilterButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      galleryFilterButtons.forEach(function (b) { b.classList.remove('active'); });
      btn.classList.add('active');
      var filter = btn.getAttribute('data-gallery-filter');

      galleryCards.forEach(function (card) {
        var cardCat = card.getAttribute('data-category');
        if (filter === 'all' || cardCat === filter) {
          card.style.display = '';
        } else {
          card.style.display = 'none';
        }
      });
    });
  });

  // Sticky Nav Active Link ScrollSpy
  var navLinks = document.querySelectorAll('.quick-nav-bar .nav-chip');
  var mainSections = document.querySelectorAll('main > section[id]');

  if (window.IntersectionObserver && navLinks.length > 0 && mainSections.length > 0) {
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          var id = entry.target.getAttribute('id');
          navLinks.forEach(function (link) {
            var href = link.getAttribute('href');
            if (href === '#' + id) {
              link.classList.add('active');
              // Auto scroll nav bar to keep active chip visible
              link.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
            } else {
              link.classList.remove('active');
            }
          });
        }
      });
    }, { rootMargin: '-15% 0px -70% 0px' });

    mainSections.forEach(function (sec) {
      observer.observe(sec);
    });
  }

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
