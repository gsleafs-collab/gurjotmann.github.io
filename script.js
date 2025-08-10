
// Smooth scroll
document.querySelectorAll('a[href^="#"]').forEach(a => {
  a.addEventListener('click', e => {
    e.preventDefault();
    document.querySelector(a.getAttribute('href')).scrollIntoView({behavior: 'smooth'});
  });
});

// Modal open/close
document.querySelectorAll('[data-open]').forEach(row => {
  row.addEventListener('click', () => {
    const id = row.getAttribute('data-open');
    const modal = document.getElementById(id);
    if (!modal) return;
    modal.setAttribute('aria-hidden', 'false');
  });
});

document.querySelectorAll('[data-close]').forEach(btn => {
  btn.addEventListener('click', e => {
    const modal = e.target.closest('.modal');
    if (modal) modal.setAttribute('aria-hidden', 'true');
  });
});

document.querySelectorAll('.modal-backdrop').forEach(bg => {
  bg.addEventListener('click', e => {
    const modal = e.target.closest('.modal');
    if (modal) modal.setAttribute('aria-hidden', 'true');
  });
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    document.querySelectorAll('.modal').forEach(m => m.setAttribute('aria-hidden', 'true'));
  }
});
