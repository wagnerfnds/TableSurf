import * as THREE from "three";

const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
const small = matchMedia("(max-width: 720px)").matches;

/* =========================================================
   O mar de células: cada bloco é uma célula de tabela.
   Na onda ele surfa; quando a onda assenta, vira planilha.
   ========================================================= */
function sea() {
  const canvas = document.getElementById("sea");
  let renderer;
  try {
    renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: "high-performance" });
  } catch {
    canvas.remove();
    return;
  }
  renderer.setPixelRatio(Math.min(devicePixelRatio, small ? 1.5 : 1.75));
  renderer.setClearColor(0x05142a);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(50, 1, 0.1, 400);

  const COLS = small ? 34 : 56;
  const ROWS = small ? 80 : 110;
  const CW = 2.2, RH = 1.0;

  const box = new THREE.BoxGeometry(CW * 0.9, 0.5, RH * 0.82);
  const geo = new THREE.InstancedBufferGeometry();
  geo.index = box.index;
  geo.attributes.position = box.attributes.position;
  geo.attributes.normal = box.attributes.normal;
  geo.instanceCount = COLS * ROWS;

  const cells = new Float32Array(COLS * ROWS * 4);
  let i = 0;
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      cells[i++] = (c - (COLS - 1) / 2) * CW;
      cells[i++] = (r - ROWS + 36) * RH; // linhas se estendem para o fundo
      cells[i++] = r;
      cells[i++] = c;
    }
  }
  geo.setAttribute("aCell", new THREE.InstancedBufferAttribute(cells, 4));

  const uniforms = {
    uTime: { value: 0 },
    uAmp: { value: 1 },
    uGrid: { value: 0 },
    uMouse: { value: new THREE.Vector2(999, 999) },
    uRows: { value: ROWS },
    uFog: { value: new THREE.Color(0x05142a) },
  };

  const mat = new THREE.ShaderMaterial({
    uniforms,
    vertexShader: /* glsl */ `
      attribute vec4 aCell;
      uniform float uTime, uAmp, uGrid, uRows;
      uniform vec2 uMouse;
      varying vec3 vColor;
      varying vec3 vN;
      varying float vFog;
      varying float vTop;

      float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

      float swellAt(vec2 p, float t) {
        // uma ondulação grande que vem do fundo até a praia
        float front = mod(t * 9.0, 150.0) - 110.0;
        float d = (p.y - front) + sin(p.x * 0.06 + t * 0.3) * 6.0;
        float body = exp(-d * d / 60.0);
        float lip = exp(-pow(max(d, 0.0), 2.0) / 6.0) * step(0.0, d);
        return body * 4.2 + lip * 1.4 * body;
      }

      float waveAt(vec2 p, float t) {
        float h = 0.0;
        h += sin(p.x * 0.11 + t * 0.9) * 0.9;
        h += sin(p.y * 0.21 + t * 1.3 + p.x * 0.04) * 0.75;
        h += sin((p.x * 0.6 + p.y) * 0.09 - t * 0.6) * 1.3;
        h += sin(p.x * 0.33 - p.y * 0.17 + t * 2.1) * 0.25;
        h += swellAt(p, t);
        return h;
      }

      void main() {
        vec2 p = aCell.xy;
        float row = aCell.z;
        float col = aCell.w;
        float t = uTime;

        // ondinha do mouse — vale nos dois modos
        float md = distance(p * vec2(0.7, 1.0), uMouse * vec2(0.7, 1.0));
        float ripple = sin(md * 0.9 - t * 5.0) * exp(-md * 0.11) * 1.6;

        float h = waveAt(p, t) * uAmp + ripple * mix(1.0, 0.25, uGrid);

        vec3 pos = position;
        pos.y *= mix(1.0 + max(h, 0.0) * 0.35, 0.35, uGrid);
        pos.xz += p;
        pos.y += h;

        vec4 mv = modelViewMatrix * vec4(pos, 1.0);
        gl_Position = projectionMatrix * mv;

        vN = normalize(normalMatrix * normal);
        vTop = step(0.5, normal.y);
        vFog = smoothstep(30.0, 120.0, -mv.z);

        // --- cor do mar
        vec3 abyss = vec3(0.02, 0.07, 0.15);
        vec3 deep  = vec3(0.05, 0.22, 0.32);
        vec3 blue  = vec3(0.04, 0.40, 0.78);
        vec3 cyan  = vec3(0.18, 0.78, 0.86);
        vec3 foam  = vec3(0.91, 0.98, 1.0);
        vec3 sea = mix(abyss, deep, smoothstep(-3.0, -0.5, h));
        sea = mix(sea, blue, smoothstep(-0.5, 1.8, h));
        sea = mix(sea, cyan, smoothstep(1.6, 3.6, h));
        sea = mix(sea, foam, smoothstep(3.8, 5.4, h) * (0.6 + 0.4 * hash(aCell.zw)));

        // --- cor da planilha
        float stripe = mod(row, 2.0);
        vec3 grid = mix(vec3(0.075, 0.13, 0.21), vec3(0.09, 0.16, 0.26), stripe);
        float sel = floor(mod(t * 2.2, uRows - 14.0));
        float isSel = 1.0 - step(0.5, abs(row - (uRows - 1.0 - sel)));
        grid = mix(grid, vec3(0.20, 0.47, 0.96), isSel * 0.85);
        float blip = step(0.9965, hash(aCell.zw + floor(t * 1.5)));
        grid = mix(grid, cyan, blip * 0.9);
        float hover = 1.0 - smoothstep(1.2, 2.6, md);
        grid = mix(grid, cyan, hover * 0.7);

        vColor = mix(sea, grid, uGrid);
      }
    `,
    fragmentShader: /* glsl */ `
      uniform vec3 uFog;
      varying vec3 vColor;
      varying vec3 vN;
      varying float vFog;
      varying float vTop;
      void main() {
        vec3 L = normalize(vec3(0.3, 1.0, 0.45));
        float diff = max(dot(vN, L), 0.0);
        vec3 c = vColor * (0.45 + 0.75 * diff) + vColor * vTop * 0.12;
        c = mix(c, uFog, vFog);
        gl_FragColor = vec4(c, 1.0);
      }
    `,
  });

  const mesh = new THREE.Mesh(geo, mat);
  mesh.frustumCulled = false;
  scene.add(mesh);

  // --- câmera por "maré": cada seção pede um estado
  const STATES = {
    wave: { pos: new THREE.Vector3(0, 7.5, 30), look: new THREE.Vector3(0, 1, -14), amp: 1, grid: 0 },
    grid: { pos: new THREE.Vector3(0, 44, 18), look: new THREE.Vector3(0, 0, -10), amp: 0, grid: 1 },
    calm: { pos: new THREE.Vector3(-6, 12, 30), look: new THREE.Vector3(0, 0, -30), amp: 0.25, grid: 0 },
  };
  let target = STATES.wave;
  const camPos = target.pos.clone();
  const camLook = target.look.clone();

  const sections = [...document.querySelectorAll("[data-sea]")];
  function pickState() {
    const mid = innerHeight / 2;
    for (const s of sections) {
      const r = s.getBoundingClientRect();
      if (r.top <= mid && r.bottom >= mid) {
        target = STATES[s.dataset.sea] || STATES.wave;
        return;
      }
    }
  }
  addEventListener("scroll", pickState, { passive: true });
  pickState();

  // --- mouse → ponto no mar
  const ndc = new THREE.Vector2(9, 9);
  const ray = new THREE.Raycaster();
  const plane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);
  const hit = new THREE.Vector3();
  const mouseWorld = new THREE.Vector2(999, 999);
  let hasPointer = false;
  addEventListener("pointermove", (e) => {
    ndc.set((e.clientX / innerWidth) * 2 - 1, -(e.clientY / innerHeight) * 2 + 1);
    hasPointer = true;
  }, { passive: true });
  document.addEventListener("pointerleave", () => { hasPointer = false; });

  function resize() {
    const w = innerWidth, h = innerHeight;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.fov = w < h ? 68 : 50;
    camera.updateProjectionMatrix();
  }
  addEventListener("resize", resize);
  resize();

  const clock = new THREE.Clock();
  let t = 0;
  let visible = true;
  document.addEventListener("visibilitychange", () => { visible = !document.hidden; clock.getDelta(); });

  function frame() {
    requestAnimationFrame(frame);
    if (!visible) return;
    const dt = Math.min(clock.getDelta(), 0.05);
    t += dt * (reduced ? 0.2 : 1);

    const k = 1 - Math.pow(0.0015, dt); // suavização independente de fps
    camPos.lerp(target.pos, k);
    camLook.lerp(target.look, k);
    uniforms.uAmp.value += (target.amp - uniforms.uAmp.value) * k;
    uniforms.uGrid.value += (target.grid - uniforms.uGrid.value) * k;

    // leve balanço da câmera, como prancha na água
    const bob = (1 - uniforms.uGrid.value) * (reduced ? 0 : 1);
    camera.position.set(
      camPos.x + Math.sin(t * 0.4) * 1.2 * bob + ndc.x * 1.5 * (hasPointer ? 1 : 0),
      camPos.y + Math.sin(t * 0.9) * 0.5 * bob,
      camPos.z
    );
    camera.lookAt(camLook);
    camera.rotateZ(Math.sin(t * 0.6) * 0.02 * bob);

    if (hasPointer) {
      ray.setFromCamera(ndc, camera);
      if (ray.ray.intersectPlane(plane, hit)) {
        mouseWorld.lerp(new THREE.Vector2(hit.x, hit.z), 0.2);
      }
    } else {
      mouseWorld.set(999, 999);
    }
    uniforms.uMouse.value.copy(mouseWorld);
    uniforms.uTime.value = t;

    renderer.render(scene, camera);
  }
  frame();
}

/* ---------- UI ---------- */
function ui() {
  const nav = document.querySelector(".nav");
  const onScroll = () => nav.classList.toggle("scrolled", scrollY > 40);
  addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  const io = new IntersectionObserver((entries) => {
    for (const e of entries) {
      if (!e.isIntersecting) continue;
      e.target.classList.add("in");
      io.unobserve(e.target);
    }
  }, { threshold: 0.15, rootMargin: "0px 0px -8% 0px" });
  document.querySelectorAll(".reveal").forEach((el, i) => {
    el.style.transitionDelay = `${(i % 4) * 70}ms`;
    io.observe(el);
  });

  // brilho que segue o cursor nos cards e na janela
  document.querySelectorAll(".card, .window").forEach((el) => {
    el.addEventListener("pointermove", (e) => {
      const r = el.getBoundingClientRect();
      el.style.setProperty("--mx", `${e.clientX - r.left}px`);
      el.style.setProperty("--my", `${e.clientY - r.top}px`);
    });
  });

  if (!reduced) {
    document.querySelectorAll(".tilt").forEach((el) => {
      el.addEventListener("pointermove", (e) => {
        const r = el.getBoundingClientRect();
        const x = (e.clientX - r.left) / r.width - 0.5;
        const y = (e.clientY - r.top) / r.height - 0.5;
        el.style.transform = `perspective(1600px) rotateY(${x * 6}deg) rotateX(${-y * 6}deg)`;
      });
      el.addEventListener("pointerleave", () => { el.style.transform = ""; });
    });
  }

  // contador
  const counter = document.querySelector("[data-count]");
  if (counter) {
    const end = +counter.dataset.count;
    const cio = new IntersectionObserver(([e]) => {
      if (!e.isIntersecting) return;
      cio.disconnect();
      const t0 = performance.now();
      const step = (now) => {
        const p = Math.min((now - t0) / 1600, 1);
        counter.textContent = Math.round(end * (1 - Math.pow(1 - p, 3))).toLocaleString("pt-BR");
        if (p < 1) requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    });
    cio.observe(counter);
  }

  typing();
}

/* ---------- SQL digitado ---------- */
const QUERIES = [
  [["SELECT", "k"], " c.cidade, ", ["COUNT", "f"], "(*) ", ["AS", "k"], " pedidos\n",
   ["FROM", "k"], " pedidos p\n", ["JOIN", "k"], " clientes c ", ["ON", "k"], " c.id = p.cliente_id\n",
   ["WHERE", "k"], " p.status <> ", ["'cancelado'", "s"], "\n", ["GROUP BY", "k"], " c.cidade\n",
   ["ORDER BY", "k"], " pedidos ", ["DESC", "k"], ";"],
  [["UPDATE", "k"], " produtos\n", ["SET", "k"], " preco = preco * ", ["1.1", "n"], "\n",
   ["WHERE", "k"], " categoria = ", ["'pranchas'", "s"], "\n", ["RETURNING", "k"], " id, nome, preco;"],
  [["SELECT", "k"], " *\n", ["FROM", "k"], " ondas\n", ["WHERE", "k"], " altura_m >= ", ["2", "n"],
   "\n  ", ["AND", "k"], " praia = ", ["'Itacaré'", "s"], "\n", ["LIMIT", "k"], " ", ["1000", "n"], ";"],
];

function typing() {
  const out = document.getElementById("typed");
  if (!out) return;
  const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const render = (q, n) => {
    let html = "", left = n;
    for (const tok of q) {
      const [text, cls] = typeof tok === "string" ? [tok, null] : tok;
      const part = text.slice(0, Math.max(0, left));
      left -= text.length;
      if (part) html += cls ? `<span class="${cls}">${esc(part)}</span>` : esc(part);
      if (left <= 0) break;
    }
    return html;
  };
  const len = (q) => q.reduce((a, t) => a + (typeof t === "string" ? t : t[0]).length, 0);

  if (reduced) { out.innerHTML = render(QUERIES[0], Infinity); return; }

  let qi = 0, n = 0, dir = 1, started = false;
  const tick = () => {
    const q = QUERIES[qi];
    n += dir;
    out.innerHTML = render(q, n);
    let delay = dir > 0 ? 28 + Math.random() * 55 : 8;
    if (dir > 0 && n >= len(q)) { dir = -1; delay = 2600; }
    else if (dir < 0 && n <= 0) { dir = 1; qi = (qi + 1) % QUERIES.length; delay = 500; }
    setTimeout(tick, delay);
  };
  new IntersectionObserver(([e], obs) => {
    if (e.isIntersecting && !started) { started = true; obs.disconnect(); tick(); }
  }).observe(out);
}

sea();
ui();
