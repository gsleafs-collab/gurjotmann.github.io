
// Smooth scroll
document.querySelectorAll('a[href^="#"]').forEach(a=>{
  a.addEventListener('click',(e)=>{e.preventDefault();document.querySelector(a.getAttribute('href')).scrollIntoView({behavior:'smooth'});});
});
// Modals
function closeAll(){document.querySelectorAll('.modal').forEach(m=>m.setAttribute('aria-hidden','true'));}
document.querySelectorAll('[data-open]').forEach(el=>{
  el.addEventListener('click',()=>{document.getElementById(el.dataset.open).setAttribute('aria-hidden','false');});
});
document.addEventListener('click',e=>{if(e.target.matches('[data-close]')||e.target.classList.contains('modal-backdrop')) closeAll();});
document.addEventListener('keydown',e=>{if(e.key==='Escape') closeAll();});

// Canvas particles (animated background)
const c = document.getElementById('bg');
const ctx = c.getContext('2d');
let w, h, dpr = Math.max(1, window.devicePixelRatio||1);
function resize(){w = c.clientWidth; h = c.clientHeight; c.width = Math.floor(w*dpr); c.height = Math.floor(h*dpr); ctx.scale(dpr,dpr);}
resize(); window.addEventListener('resize', resize);
const N = 70;
const pts = Array.from({length:N}, ()=>({x:Math.random()*window.innerWidth,y:Math.random()*window.innerHeight,vx:(Math.random()-0.5)*0.6,vy:(Math.random()-0.5)*0.6}));
function tick(){
  ctx.clearRect(0,0,w,h);
  for(let i=0;i<N;i++){
    const p = pts[i];
    p.x += p.vx; p.y += p.vy;
    if(p.x<0||p.x>w) p.vx*=-1;
    if(p.y<0||p.y>h) p.vy*=-1;
    ctx.beginPath(); ctx.arc(p.x,p.y,1.6,0,Math.PI*2); ctx.fillStyle = '#8fb6ff'; ctx.fill();
    for(let j=i+1;j<N;j++){
      const q = pts[j];
      const dx = p.x-q.x, dy=p.y-q.y, dist = Math.hypot(dx,dy);
      if(dist<120){
        ctx.globalAlpha = 1 - dist/120;
        ctx.beginPath(); ctx.moveTo(p.x,p.y); ctx.lineTo(q.x,q.y); ctx.strokeStyle='#304a78'; ctx.lineWidth=1; ctx.stroke();
        ctx.globalAlpha = 1;
      }
    }
  }
  requestAnimationFrame(tick);
}
tick();
