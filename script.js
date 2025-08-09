// Minimal JS to fill Experience/Projects from JSON and copy contact message.
const year = document.getElementById('year');
if (year) year.textContent = new Date().getFullYear();

async function loadData() {
  try {
    const [expRes, projRes] = await Promise.all([
      fetch('data/experience.json'),
      fetch('data/projects.json')
    ]);
    const exp = await expRes.json().catch(()=>[]);
    const projects = await projRes.json().catch(()=>[]);
    renderExperience(exp);
    renderProjects(projects);
  } catch (e) {
    console.warn('Data load error', e);
  }
}
function renderExperience(items){
  const el = document.getElementById('experience-list');
  if (!el) return;
  if (!items || !items.length){
    el.innerHTML = '<div class="card"><p>No experience data yet. Add items in <code>data/experience.json</code>.</p></div>';
    return;
  }
  el.innerHTML = items.map(it=>`
    <article class="card">
      <h3>${it.role} · ${it.company}</h3>
      <p>${it.start} — ${it.end || 'Present'}</p>
      <p>${it.summary}</p>
      ${it.skills && it.skills.length ? `<div class="badges">${it.skills.map(s=>`<span class="badge">${s}</span>`).join('')}</div>`:''}
    </article>
  `).join('');
}
function renderProjects(items){
  const el = document.getElementById('projects-list');
  if (!el) return;
  if (!items || !items.length){
    el.innerHTML = '<div class="card"><p>No projects yet. Add items in <code>data/projects.json</code>.</p></div>';
    return;
  }
  el.innerHTML = items.map(it=>`
    <article class="card">
      <h3>${it.name}</h3>
      <p>${it.summary}</p>
      ${it.link ? `<p><a href="${it.link}" target="_blank" rel="noopener">View</a></p>`:''}
      ${it.tags && it.tags.length ? `<div class="badges">${it.tags.map(s=>`<span class="badge">${s}</span>`).join('')}</div>`:''}
    </article>
  `).join('');
}
loadData();

// Contact copy helper
const btn = document.getElementById('sendBtn');
if (btn){
  btn.addEventListener('click', ()=>{
    const name = (document.getElementById('name')||{}).value||'';
    const email = (document.getElementById('email')||{}).value||'';
    const msg = (document.getElementById('message')||{}).value||'';
    const text = `From: ${name} <${email}>

${msg}`;
    navigator.clipboard.writeText(text).then(()=>{
      btn.textContent = 'Copied! Paste into your email';
      setTimeout(()=>btn.textContent='Copy message', 2000);
    });
  });
}
