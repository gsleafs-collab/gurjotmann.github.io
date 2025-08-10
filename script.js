
// Sticky nav smooth scroll
document.querySelectorAll('a[href^="#"]').forEach(a=>{
  a.addEventListener('click',e=>{e.preventDefault(); document.querySelector(a.getAttribute('href')).scrollIntoView({behavior:'smooth'});});
});

// Constellation background (animated lines + points)
const canvas = document.getElementById('bg');
const ctx = canvas.getContext('2d');
let w,h,dpr=Math.max(1,window.devicePixelRatio||1);
function size(){w=canvas.clientWidth;h=canvas.clientHeight;canvas.width=Math.floor(w*dpr);canvas.height=Math.floor(h*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);}
size(); window.addEventListener('resize', size);

const N = 85;
const pts = Array.from({length:N}, ()=>({x:Math.random()*w,y:Math.random()*h,vx:(Math.random()-.5)*.5,vy:(Math.random()-.5)*.5}));
function tick(){
  ctx.clearRect(0,0,w,h);
  for(let i=0;i<N;i++){
    const p=pts[i]; p.x+=p.vx; p.y+=p.vy;
    if(p.x<0||p.x>w) p.vx*=-1; if(p.y<0||p.y>h) p.vy*=-1;
    ctx.beginPath(); ctx.arc(p.x,p.y,1.6,0,Math.PI*2); ctx.fillStyle='#9bd4ff'; ctx.fill();
    for(let j=i+1;j<N;j++){
      const q=pts[j]; const dx=p.x-q.x, dy=p.y-q.y, dist=Math.hypot(dx,dy);
      if(dist<140){ctx.globalAlpha=1-dist/140; ctx.beginPath(); ctx.moveTo(p.x,p.y); ctx.lineTo(q.x,q.y); ctx.strokeStyle='#2f4060'; ctx.lineWidth=1; ctx.stroke(); ctx.globalAlpha=1;}
    }
  }
  requestAnimationFrame(tick);
}
tick();
