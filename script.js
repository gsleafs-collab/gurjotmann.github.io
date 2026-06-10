// Footer year 
const year = document.getElementById('year');
if (year) year.textContent = new Date().getFullYear();

// Scroll progress bar + header shadow
const progress = document.getElementById('progress');
const header = document.querySelector('.site-header');
function onScroll() {
  const doc = document.documentElement;
  const max = doc.scrollHeight - doc.clientHeight;
  if (progress) progress.style.width = (max > 0 ? (doc.scrollTop / max) * 100 : 0) + '%';
  if (header) header.classList.toggle('scrolled', doc.scrollTop > 10);
}
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

// Reveal-on-scroll
const observer = new IntersectionObserver(
  entries => entries.forEach(e => {
    if (e.isIntersecting) {
      e.target.classList.add('visible');
      observer.unobserve(e.target);
    }
  }),
  { threshold: 0.12 }
);
function observeReveals(root) {
  (root || document).querySelectorAll('.reveal:not(.visible)').forEach(el => observer.observe(el));
}
observeReveals();

// Experience timeline from JSON
async function loadExperience() {
  const el = document.getElementById('experience-list');
  if (!el) return;
  try {
    const res = await fetch('data/experience.json');
    const items = await res.json();
    if (!Array.isArray(items) || !items.length) return;
    el.innerHTML = items.map(it => `
      <li class="tl-item reveal">
        <span class="tl-date">${it.start} — ${it.end || 'Present'}</span>
        <div class="tl-card">
          <h3 class="tl-role">${it.role}</h3>
          <p class="tl-company">${it.company}</p>
          <p class="tl-summary">${it.summary}</p>
          ${it.skills && it.skills.length
            ? `<div class="chips">${it.skills.map(s => `<span class="chip">${s}</span>`).join('')}</div>`
            : ''}
        </div>
      </li>
    `).join('');
    observeReveals(el);
  } catch (e) {
    console.warn('Could not load experience data', e);
  }
}
loadExperience();

// Contact copy-to-clipboard helper
const btn = document.getElementById('sendBtn');
if (btn) {
  btn.addEventListener('click', () => {
    const name  = (document.getElementById('name')    || {}).value || '';
    const email = (document.getElementById('email')   || {}).value || '';
    const msg   = (document.getElementById('message') || {}).value || '';
    const text  = `From: ${name} <${email}>\n\n${msg}`;
    navigator.clipboard.writeText(text).then(() => {
      btn.textContent = 'Copied! Paste into your email';
      setTimeout(() => (btn.textContent = 'Copy message'), 2500);
    });
  });
}
