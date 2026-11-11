/* TrueReport Public Report Interactive Features */

var currentPartImg = '';
var currentPartCaption = '';
var currentPartNote = '';

function openPartDialog(el) {
  var dialog = document.getElementById('part-detail-dialog');
  if (!dialog) return;

  var title = el.getAttribute('data-title') || '';
  var cat = el.getAttribute('data-category') || '';
  var status = el.getAttribute('data-status') || el.getAttribute('data-status-label') || '';
  var statusCode = el.getAttribute('data-status-code') || '';
  var passFail = el.getAttribute('data-pass-fail') || '';
  var score = parseInt(el.getAttribute('data-score') || '100', 10);
  var scoreText = el.getAttribute('data-score-text') || (score + '/100');
  var measured = el.getAttribute('data-measured') || '';
  var standard = el.getAttribute('data-standard') || '';
  var note = el.getAttribute('data-note') || '';
  var img = el.getAttribute('data-img') || '';
  var video = el.getAttribute('data-video') || '';
  var videoCaption = el.getAttribute('data-video-caption') || '';

  if (!passFail) {
    if (statusCode === 'DEFECT_FOUND' || statusCode === 'DEFECT' || statusCode === 'FAIL') {
      passFail = 'FAIL';
    } else if (statusCode === 'ATTENTION_RECOMMENDED' || statusCode === 'ATTENTION') {
      passFail = 'ATTENTION';
    } else {
      passFail = 'PASS';
    }
  }

  currentPartImg = img;
  currentPartCaption = title + (status ? ' - ' + status : '');
  currentPartNote = note;

  var titleEl = document.getElementById('dialog-part-title');
  var catEl = document.getElementById('dialog-part-cat');
  var statusEl = document.getElementById('dialog-part-status');
  var passFailBadgeEl = document.getElementById('dialog-pass-fail-badge');
  var statusRibbonEl = document.getElementById('dialog-status-ribbon');
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

  var isFail = (statusCode === 'DEFECT_FOUND' || statusCode === 'DEFECT' || passFail.indexOf('FAIL') !== -1 || passFail.indexOf('فاشل') !== -1);
  var isAttn = (statusCode === 'ATTENTION_RECOMMENDED' || statusCode === 'ATTENTION' || passFail.indexOf('ATTENTION') !== -1 || passFail.indexOf('تنبيه') !== -1);

  if (passFailBadgeEl) {
    if (isFail) {
      passFailBadgeEl.textContent = '✕ ' + passFail;
      passFailBadgeEl.className = 'badge-status-pill badge-fail';
    } else if (isAttn) {
      passFailBadgeEl.textContent = '⚠ ' + passFail;
      passFailBadgeEl.className = 'badge-status-pill badge-attention';
    } else {
      passFailBadgeEl.textContent = '✓ ' + passFail;
      passFailBadgeEl.className = 'badge-status-pill badge-pass';
    }
  }

  if (statusRibbonEl) {
    statusRibbonEl.className = 'dialog-status-ribbon ' + (isFail ? 'ribbon-fail' : (isAttn ? 'ribbon-attention' : 'ribbon-pass'));
  }

  if (statusEl) {
    statusEl.textContent = status;
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
    imgEl.src = img || '';
    imgEl.alt = title;
  }

  if (videoEl) {
    try {
      videoEl.pause();
      if (video) {
        videoEl.src = video;
        videoEl.style.display = 'block';
        videoEl.load();
      } else {
        videoEl.style.display = 'none';
      }
    } catch (e) {
      console.warn('Video load error', e);
    }
  }

  if (videoCapEl) videoCapEl.textContent = videoCaption;

  try {
    if (typeof dialog.showModal === 'function') {
      dialog.showModal();
    } else {
      dialog.setAttribute('open', 'true');
    }
  } catch (err) {
    dialog.setAttribute('open', 'true');
  }
  document.body.classList.add('modal-open');
}

function closePartDialog() {
  var dialog = document.getElementById('part-detail-dialog');
  if (!dialog) return;

  var video = document.getElementById('dialog-part-video');
  if (video) {
    try {
      video.pause();
      video.currentTime = 0;
    } catch (e) {}
  }

  try {
    if (typeof dialog.close === 'function') {
      dialog.close();
    } else {
      dialog.removeAttribute('open');
    }
  } catch (err) {
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

  try {
    if (typeof dialog.showModal === 'function') {
      dialog.showModal();
    } else {
      dialog.setAttribute('open', 'true');
    }
  } catch (err) {
    dialog.setAttribute('open', 'true');
  }
  document.body.classList.add('modal-open');
}

function closeLightbox() {
  var dialog = document.getElementById('photo-lightbox');
  if (!dialog) return;
  try {
    if (typeof dialog.close === 'function') {
      dialog.close();
    } else {
      dialog.removeAttribute('open');
    }
  } catch (err) {
    dialog.removeAttribute('open');
  }
  document.body.classList.remove('modal-open');
}

// Global click event delegation - guarantees clicks work on every element!
document.addEventListener('click', function (e) {
  var partTrigger = e.target.closest('[data-action="open-part-dialog"], .check-row-item, .card-inspect-btn, .action-dialog-btn, .key-finding-interactive-card, .tyre-modern-card');
  if (partTrigger) {
    e.preventDefault();
    openPartDialog(partTrigger);
    return;
  }

  var closeBtn = e.target.closest('[data-action="close-part-dialog"]') || e.target.closest('#part-detail-dialog .dialog-close-btn');
  if (closeBtn) {
    e.preventDefault();
    closePartDialog();
    return;
  }

  var lbClose = e.target.closest('[data-action="close-lightbox"]') || e.target.closest('#photo-lightbox .lightbox-close-btn');
  if (lbClose) {
    e.preventDefault();
    closeLightbox();
    return;
  }

  var photoBox = e.target.closest('[data-action="open-lightbox"], .part-photo-box, .gallery-masonry-card, .gallery-photo-card');
  if (photoBox && !photoBox.closest('#part-detail-dialog') && !photoBox.closest('.key-finding-interactive-card')) {
    e.preventDefault();
    openLightbox(photoBox);
    return;
  }
});

// Keyboard support: Enter / Space triggers active item, Escape closes modals
document.addEventListener('keydown', function (e) {
  if (e.key === 'Escape') {
    closePartDialog();
    closeLightbox();
  } else if (e.key === 'Enter' || e.key === ' ') {
    var active = document.activeElement;
    if (active && active.matches('[data-action="open-part-dialog"], .check-row-item, .card-inspect-btn, .action-dialog-btn, .key-finding-interactive-card, .tyre-modern-card')) {
      e.preventDefault();
      openPartDialog(active);
    }
  }
});

document.addEventListener('DOMContentLoaded', function () {
  // Smooth count-up animation for the prominent score percentage
  var scoreEl = document.querySelector('.score-large-number');
  if (scoreEl) {
    var rawText = scoreEl.textContent || '';
    var match = rawText.match(/(\d+)/);
    if (match) {
      var targetNum = parseInt(match[1], 10);
      var current = 0;
      var step = Math.max(1, Math.round(targetNum / 28));
      var timer = setInterval(function () {
        current += step;
        if (current >= targetNum) {
          current = targetNum;
          clearInterval(timer);
        }
        scoreEl.textContent = current + '%';
      }, 30);
    }
  }

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

  // Showcase Category Filter (Tabs: All, Exterior, Interior, Mechanical, Imperfections, Underbody)
  var galleryFilterButtons = document.querySelectorAll('[data-gallery-filter], .gallery-tab');
  var galleryCards = document.querySelectorAll('.gallery-masonry-card, .gallery-photo-card');

  galleryFilterButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      galleryFilterButtons.forEach(function (b) {
        b.classList.remove('active');
        b.classList.remove('tab-active');
      });
      btn.classList.add('active');
      btn.classList.add('tab-active');
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

  // Interactive Exterior Damage Map Zone Switcher
  function selectDamageZone(zoneId) {
    if (!zoneId) return;
    var allZoneBtns = document.querySelectorAll('.damage-zone-btn');
    var allHotspots = document.querySelectorAll('.zone-svg-hotspot');
    var allPanels = document.querySelectorAll('.damage-zone-detail-panel');

    allZoneBtns.forEach(function (btn) {
      if (btn.getAttribute('data-zone-id') === zoneId) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });

    allHotspots.forEach(function (spot) {
      if (spot.getAttribute('data-zone-target') === zoneId) {
        spot.classList.add('is-active-pin');
      } else {
        spot.classList.remove('is-active-pin');
      }
    });

    allPanels.forEach(function (panel) {
      if (panel.getAttribute('data-zone-panel') === zoneId) {
        panel.classList.add('active');
      } else {
        panel.classList.remove('active');
      }
    });
  }

  var damageZoneBtns = document.querySelectorAll('.damage-zone-btn');
  damageZoneBtns.forEach(function (btn) {
    btn.addEventListener('click', function () {
      var zoneId = btn.getAttribute('data-zone-id');
      selectDamageZone(zoneId);
    });
  });

  var damageHotspots = document.querySelectorAll('.zone-svg-hotspot');
  damageHotspots.forEach(function (spot) {
    spot.addEventListener('click', function () {
      var zoneId = spot.getAttribute('data-zone-target');
      selectDamageZone(zoneId);
    });
    spot.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        var zoneId = spot.getAttribute('data-zone-target');
        selectDamageZone(zoneId);
      }
    });
  });

  // Sticky Nav Active Link ScrollSpy
  var navLinks = document.querySelectorAll('.report-nav .report-nav-chip, .quick-nav-bar .nav-chip, .report-sticky-nav .sticky-nav-pill');
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

  // Report Share Button (Web Share API or Clipboard Copy)
  var shareBtn = document.getElementById('reportShareBtn');
  if (shareBtn) {
    shareBtn.addEventListener('click', function () {
      if (navigator.share) {
        navigator.share({
          title: document.title,
          url: window.location.href
        }).catch(function () {});
      } else if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(window.location.href).then(function () {
          shareBtn.classList.add('copied');
          setTimeout(function () {
            shareBtn.classList.remove('copied');
          }, 2000);
        }).catch(function () {});
      }
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
