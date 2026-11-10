/* TrueReport Public Report Interactive Features */

var currentPartImg = '';
var currentPartCaption = '';
var currentPartNote = '';

function openPartDialog(el) {
  var dialog = document.getElementById('part-detail-dialog');
  if (!dialog) return;

  var title = el.getAttribute('data-title') || '';
  var cat = el.getAttribute('data-category') || '';
  var status = el.getAttribute('data-status') || '';
  var statusCode = el.getAttribute('data-status-code') || '';
  var score = parseInt(el.getAttribute('data-score') || '100', 10);
  var scoreText = el.getAttribute('data-score-text') || '';
  var measured = el.getAttribute('data-measured') || '';
  var standard = el.getAttribute('data-standard') || '';
  var note = el.getAttribute('data-note') || '';
  var img = el.getAttribute('data-img') || '';
  var video = el.getAttribute('data-video') || '';
  var videoCaption = el.getAttribute('data-video-caption') || '';

  currentPartImg = img;
  currentPartCaption = title + ' - ' + status;
  currentPartNote = note;

  var titleEl = document.getElementById('dialog-part-title');
  var catEl = document.getElementById('dialog-part-cat');
  var statusEl = document.getElementById('dialog-part-status');
  var scoreEl = document.getElementById('dialog-part-score');
  var measuredEl = document.getElementById('dialog-measured-spec');
  var standardEl = document.getElementById('dialog-standard-spec');
  var scoreFillEl = document.getElementById('dialog-score-fill');
  var noteEl = document.getElementById('dialog-part-note');
  var imgEl = document.getElementById('dialog-part-img');
  var videoEl = document.getElementById('dialog-part-video');
  var videoCapEl = document.getElementById('dialog-video-caption');

  if (titleEl) titleEl.textContent = title;
  if (catEl) catEl.textContent = cat;

  if (statusEl) {
    statusEl.textContent = status;
    statusEl.className = 'badge ' + (statusCode === 'DEFECT_FOUND' ? 'danger' : (statusCode === 'ATTENTION_RECOMMENDED' ? 'warning' : 'success'));
  }

  if (scoreEl) {
    scoreEl.textContent = scoreText;
    scoreEl.className = 'dialog-score-pill ' + (score >= 90 ? 'score-high' : (score >= 70 ? 'score-mid' : 'score-low'));
  }

  if (measuredEl) measuredEl.textContent = measured;
  if (standardEl) standardEl.textContent = standard;

  if (scoreFillEl) {
    scoreFillEl.style.width = Math.max(10, Math.min(100, score)) + '%';
    scoreFillEl.className = 'dialog-score-fill ' + (score >= 90 ? 'fill-green' : (score >= 70 ? 'fill-amber' : 'fill-red'));
  }

  if (noteEl) noteEl.textContent = note;

  if (imgEl) {
    imgEl.src = img;
    imgEl.alt = title;
  }

  if (videoEl) {
    videoEl.pause();
    videoEl.src = video;
    videoEl.load();
  }

  if (videoCapEl) videoCapEl.textContent = videoCaption;

  if (typeof dialog.showModal === 'function') {
    dialog.showModal();
  } else {
    dialog.setAttribute('open', 'true');
  }
  document.body.classList.add('modal-open');
}

function closePartDialog() {
  var dialog = document.getElementById('part-detail-dialog');
  if (!dialog) return;

  var video = document.getElementById('dialog-part-video');
  if (video) {
    video.pause();
    video.currentTime = 0;
  }

  if (typeof dialog.close === 'function') {
    dialog.close();
  } else {
    dialog.removeAttribute('open');
  }
  document.body.classList.remove('modal-open');
}

function openPhotoFromDialog() {
  if (!currentPartImg) return;
  openLightboxDirect(currentPartImg, currentPartCaption, currentPartNote);
}

function openLightbox(el) {
  var imgSrc = el.getAttribute('data-img') || (el.querySelector('img') ? el.querySelector('img').src : '');
  var caption = el.getAttribute('data-caption') || '';
  var note = el.getAttribute('data-note') || '';
  openLightboxDirect(imgSrc, caption, note);
}

function openLightboxDirect(imgSrc, caption, note) {
  var dialog = document.getElementById('photo-lightbox');
  var img = document.getElementById('lightbox-img');
  var captionEl = document.getElementById('lightbox-caption');
  var noteEl = document.getElementById('lightbox-note');
  if (!dialog || !img) return;

  img.src = imgSrc || '';
  if (captionEl) captionEl.textContent = caption || '';
  if (noteEl) noteEl.textContent = note || '';

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
  // One-Click Instant Checklist Filter (All, Passed, Attention, Failed)
  var checkFilterButtons = document.querySelectorAll('[data-checklist-filter]');
  var checkAccordions = document.querySelectorAll('.category-accordion');

  checkFilterButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      checkFilterButtons.forEach(function (b) { b.classList.remove('active'); });
      btn.classList.add('active');
      var filter = btn.getAttribute('data-checklist-filter');

      var firstMatchedDefect = null;

      checkAccordions.forEach(function (acc) {
        var rows = acc.querySelectorAll('.check-row-item');
        var visibleCount = 0;

        rows.forEach(function (row) {
          var res = row.getAttribute('data-result');
          var matches = (filter === 'ALL' || res === filter);
          if (matches) {
            row.style.display = '';
            visibleCount++;
            if (filter === 'DEFECT_FOUND' && !firstMatchedDefect) {
              firstMatchedDefect = row;
            }
          } else {
            row.style.display = 'none';
          }
        });

        if (visibleCount > 0) {
          acc.style.display = '';
          acc.open = true;
        } else {
          acc.style.display = 'none';
        }
      });

      // If user clicked Failed & Defects, auto-open the defect dialog directly!
      if (filter === 'DEFECT_FOUND' && firstMatchedDefect) {
        openPartDialog(firstMatchedDefect);
      }
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

  // Visual Diagnostic Sector Filter Tabs
  var diagFilterButtons = document.querySelectorAll('.visual-filter-bar .filter-chip');
  var diagCards = document.querySelectorAll('.visual-part-card');

  diagFilterButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      diagFilterButtons.forEach(function (b) { b.classList.remove('active'); });
      btn.classList.add('active');
      var filter = btn.getAttribute('data-filter');

      diagCards.forEach(function (card) {
        var cardStatus = card.getAttribute('data-status');
        if (filter === 'all' || cardStatus === filter) {
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

  // Dialog backdrop click-to-close & Esc handling
  var partDialog = document.getElementById('part-detail-dialog');
  if (partDialog) {
    partDialog.addEventListener('click', function (e) {
      if (e.target === partDialog) {
        closePartDialog();
      }
    });
    partDialog.addEventListener('cancel', function () {
      closePartDialog();
    });
  }

  var photoDialog = document.getElementById('photo-lightbox');
  if (photoDialog) {
    photoDialog.addEventListener('click', function (e) {
      if (e.target === photoDialog) {
        closeLightbox();
      }
    });
    photoDialog.addEventListener('cancel', function () {
      closeLightbox();
    });
  }
});
