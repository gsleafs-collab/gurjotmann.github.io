const year = document.getElementById('year');
if (year) year.textContent = new Date().getFullYear();

// Animated particles background
const canvas = document.getElementById('bg');
const ctx = canvas.getContext('2d');
let w, h, particles;

function resize() {
  w = canvas.width = window.innerWidth;
  h = canvas.height = window.innerHeight;
  init();
}
window.addEventListener('resize', resize);

function init() {
  particles = Array.from(
    { length: Math.max(60, Math.floor((w * h) / 25000)) },
    () => ({
      x: Math.random() * w,
      y: Math.random() * h,
      vx: (Math.random() - 0.5) * 0.6,
      vy: (Math.random() - 0.5) * 0.6,
      r: Math.random() * 1.8 + 0.6
    })
  );
}

function step() {
  ctx.clearRect(0, 0, w, h);

  // Pastel off-white background
  ctx.fillStyle = '#faf7f2';
  ctx.fillRect(0, 0, w, h);

  for (let i = 0; i < particles.length; i++) {
    const p = particles[i];
    p.x += p.vx;
    p.y += p.vy;

    if (p.x < 0 || p.x > w) p.vx *= -1;
    if (p.y < 0 || p.y > h) p.vy *= -1;

    // Dark particle color
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
    ctx.fill();

    // Connection lines
    for (let j = i + 1; j < particles.length; j++) {
      const q = particles[j];
      const dx = p.x - q.x;
      const dy = p.y - q.y;
      const d = dx * dx + dy * dy;

      if (d < 120 * 120) {
        ctx.strokeStyle = 'rgba(0, 0, 0, 0.15)';
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(p.x, p.y);
        ctx.lineTo(q.x, q.y);
        ctx.stroke();
      }
    }
  }

  requestAnimationFrame(step);
}

resize();
step();

// Load data
async function loadData() {
  try {
    const [expRes, projRes] = await Promise.all([
      fetch('data/experience.json'),
      fetch('data/projects.json')
    ]);
    const exp = await expRes.json().catch(() => []);
    const projects = await projRes.json().catch(() => []);
    renderExperience(exp);
    renderProjects(projects);
  } catch (e) {
    console.warn('Data load error', e);
  }
}

function renderExperience(items) {
  const el = document.getElementById('experience-list');
  if (!el) return;
  if (!items || !items.length) {
    el.innerHTML =
      '<div class="card"><p>No experience data yet. Add items in <code>data/experience.json</code>.</p></div>';
    return;
  }
  el.innerHTML = items
    .map(
      it => `
    <article class="card">
      <h3>${it.role} · ${it.company}</h3>
      <p>${it.start} — ${it.end || 'Present'}</p>
      <p>${it.summary}</p>
      ${
        it.skills && it.skills.length
          ? `<div class="badges">${it.skills
              .map(s => `<span class="badge">${s}</span>`)
              .join('')}</div>`
          : ''
      }
    </article>
  `
    )
    .join('');
}

function renderProjects(items) {
  const el = document.getElementById('projects-list');
  if (!el) return;
  if (!items || !items.length) {
    el.innerHTML =
      '<div class="card"><p>No projects yet. Add items in <code>data/projects.json</code>.</p></div>';
    return;
  }
  el.innerHTML = items
    .map(
      it => `
    <article class="card">
      <h3>${it.name}</h3>
      ${
        it.image
          ? `<img src="${it.image}" alt="${it.name}" style="width:100%;border-radius:12px;border:1px solid var(--border);margin:8px 0">`
          : ''
      }
      <p>${it.summary}</p>
      ${
        it.link
          ? `<p><a href="${it.link}" target="_blank" rel="noopener">View</a></p>`
          : ''
      }
      ${
        it.tags && it.tags.length
          ? `<div class="badges">${it.tags
              .map(s => `<span class="badge">${s}</span>`)
              .join('')}</div>`
          : ''
      }
    </article>
  `
    )
    .join('');
}

loadData();

// Contact helper
const btn = document.getElementById('sendBtn');
if (btn) {
  btn.addEventListener('click', () => {
    const name = (document.getElementById('name') || {}).value || '';
    const email = (document.getElementById('email') || {}).value || '';
    const msg = (document.getElementById('message') || {}).value || '';
    const text = `From: ${name} <${email}>\n\n${msg}`;
    navigator.clipboard.writeText(text).then(() => {
      btn.textContent = 'Copied! Paste into your email';
      setTimeout(() => (btn.textContent = 'Copy message'), 2000);
    });
  });
}
