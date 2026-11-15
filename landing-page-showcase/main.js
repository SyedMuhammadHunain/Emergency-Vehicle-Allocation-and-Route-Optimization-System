/**
 * Res-Q Showcase Interactive Engine
 * Inspired by Guillaume Zhu portfolio animations & interactions
 */

(function () {
  'use strict';

  // ---------------------------------------------------------------------------
  // 1. Guillaume Zhu Vertical Scroll Spy
  // ---------------------------------------------------------------------------
  const sections = document.querySelectorAll('section[id]');
  const indicatorItems = document.querySelectorAll('.scroll-indicator__item');

  function updateActiveIndicator() {
    const scrollY = window.pageYOffset;
    const windowHeight = window.innerHeight;

    let currentSectionId = '';

    sections.forEach((section) => {
      const sectionTop = section.offsetTop - windowHeight * 0.35;
      const sectionHeight = section.offsetHeight;
      if (scrollY >= sectionTop && scrollY < sectionTop + sectionHeight) {
        currentSectionId = section.getAttribute('id');
      }
    });

    if (!currentSectionId && sections.length > 0) {
      currentSectionId = sections[0].getAttribute('id');
    }

    indicatorItems.forEach((item) => {
      const href = item.getAttribute('href').replace('#', '');
      if (href === currentSectionId) {
        item.classList.add('is-active');
      } else {
        item.classList.remove('is-active');
      }
    });
  }

  window.addEventListener('scroll', updateActiveIndicator, { passive: true });
  updateActiveIndicator();

  // ---------------------------------------------------------------------------
  // 2. Hero Interactive Karachi Graph Simulation (Canvas)
  // ---------------------------------------------------------------------------
  const canvas = document.getElementById('network-canvas');
  if (canvas) {
    const ctx = canvas.getContext('2d');
    let width, height;
    let nodes = [];
    let pulses = [];
    const nodeCount = 55;
    const maxDistance = 160;

    function resize() {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    }

    window.addEventListener('resize', resize, { passive: true });
    resize();

    // Initialize graph nodes
    for (let i = 0; i < nodeCount; i++) {
      nodes.push({
        x: Math.random() * width,
        y: Math.random() * height,
        vx: (Math.random() - 0.5) * 0.45,
        vy: (Math.random() - 0.5) * 0.45,
        radius: Math.random() > 0.85 ? 3.5 : 2,
        isHospital: i < 3,
        pulsePhase: Math.random() * Math.PI * 2,
      });
    }

    // Interactive mouse tracking
    let mouse = { x: -1000, y: -1000 };
    window.addEventListener('mousemove', (e) => {
      mouse.x = e.clientX;
      mouse.y = e.clientY;
    });

    function spawnPulse() {
      if (nodes.length < 2) return;
      const i1 = Math.floor(Math.random() * nodes.length);
      const i2 = Math.floor(Math.random() * nodes.length);
      const dist = Math.hypot(nodes[i1].x - nodes[i2].x, nodes[i1].y - nodes[i2].y);
      if (dist < maxDistance && dist > 20) {
        pulses.push({
          x1: nodes[i1].x,
          y1: nodes[i1].y,
          x2: nodes[i2].x,
          y2: nodes[i2].y,
          progress: 0,
          speed: 0.02 + Math.random() * 0.02,
        });
      }
    }

    setInterval(spawnPulse, 350);

    function animate() {
      ctx.clearRect(0, 0, width, height);

      // Update and draw nodes
      for (let i = 0; i < nodes.length; i++) {
        const n = nodes[i];
        n.x += n.vx;
        n.y += n.vy;

        if (n.x < 0 || n.x > width) n.vx *= -1;
        if (n.y < 0 || n.y > height) n.vy *= -1;

        // Subtle attraction to mouse
        const dx = mouse.x - n.x;
        const dy = mouse.y - n.y;
        const distMouse = Math.hypot(dx, dy);
        if (distMouse < 180) {
          n.x += (dx / distMouse) * 0.4;
          n.y += (dy / distMouse) * 0.4;
        }

        // Draw node
        ctx.beginPath();
        ctx.arc(n.x, n.y, n.radius, 0, Math.PI * 2);
        if (n.isHospital) {
          ctx.fillStyle = '#dafa9c';
          ctx.shadowColor = '#dafa9c';
          ctx.shadowBlur = 10;
        } else {
          ctx.fillStyle = 'rgba(255, 255, 255, 0.45)';
          ctx.shadowBlur = 0;
        }
        ctx.fill();
      }

      // Draw edges
      for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
          const d = Math.hypot(nodes[i].x - nodes[j].x, nodes[i].y - nodes[j].y);
          if (d < maxDistance) {
            const alpha = (1 - d / maxDistance) * 0.22;
            ctx.beginPath();
            ctx.moveTo(nodes[i].x, nodes[i].y);
            ctx.lineTo(nodes[j].x, nodes[j].y);
            ctx.strokeStyle = `rgba(218, 250, 156, ${alpha})`;
            ctx.lineWidth = 1;
            ctx.stroke();
          }
        }
      }

      // Draw pulses (packet route signals)
      for (let p = pulses.length - 1; p >= 0; p--) {
        const pulse = pulses[p];
        pulse.progress += pulse.speed;
        if (pulse.progress >= 1) {
          pulses.splice(p, 1);
          continue;
        }

        const px = pulse.x1 + (pulse.x2 - pulse.x1) * pulse.progress;
        const py = pulse.y1 + (pulse.y2 - pulse.y1) * pulse.progress;

        ctx.beginPath();
        ctx.arc(px, py, 2.5, 0, Math.PI * 2);
        ctx.fillStyle = '#dafa9c';
        ctx.shadowColor = '#dafa9c';
        ctx.shadowBlur = 8;
        ctx.fill();
        ctx.shadowBlur = 0;
      }

      requestAnimationFrame(animate);
    }

    animate();
  }

  // ---------------------------------------------------------------------------
  // 3. Interactive Knapsack DP Simulator
  // ---------------------------------------------------------------------------
  const surgeSlider = document.getElementById('severity-slider');
  const capacitySlider = document.getElementById('capacity-slider');
  const surgeVal = document.getElementById('surge-val');
  const capacityVal = document.getElementById('capacity-val');
  const knapsackScore = document.getElementById('knapsack-score');
  const knapsackResult = document.getElementById('knapsack-result-output');

  if (surgeSlider && capacitySlider) {
    function runKnapsackSim() {
      const nSurge = parseInt(surgeSlider.value, 10);
      const cap = parseInt(capacitySlider.value, 10);

      surgeVal.textContent = `${nSurge} Incident${nSurge > 1 ? 's' : ''}`;
      capacityVal.textContent = `${cap} Unit${cap > 1 ? 's' : ''}`;

      // Sample emergency pool: [value (severity), weight (unit cost)]
      const emergencyPool = [
        { name: 'Cardiopulmonary Arrest (Civil)', val: 10, wt: 1, unit: 'Amb-01' },
        { name: 'Multi-Vehicle Pileup (Shaheed-e-Millat)', val: 9, wt: 2, unit: 'Amb-02 + Amb-03' },
        { name: 'Commercial Fire (Korangi Industrial)', val: 8, wt: 2, unit: 'Fire-01 + Amb-04' },
        { name: 'Building Structural Collapse (Lyari)', val: 10, wt: 3, unit: 'Heavy-Rescue-01' },
        { name: 'Trauma Hemorrhage (Saddar)', val: 7, wt: 1, unit: 'Amb-05' },
        { name: 'Pediatric Emergency (Gulshan)', val: 8, wt: 1, unit: 'Amb-06' },
        { name: 'Respiratory Distress (Clifton)', val: 6, wt: 1, unit: 'Amb-07' },
        { name: 'Minor Vehicle Incident (PECHS)', val: 4, wt: 1, unit: 'Patrol-01' },
      ];

      const activeList = emergencyPool.slice(0, nSurge);
      const W = cap;
      const N = activeList.length;

      // 0/1 Knapsack DP table
      const dp = Array.from({ length: N + 1 }, () => Array(W + 1).fill(0));

      for (let i = 1; i <= N; i++) {
        const item = activeList[i - 1];
        for (let w = 0; w <= W; w++) {
          if (item.wt <= w) {
            dp[i][w] = Math.max(dp[i - 1][w], dp[i - 1][w - item.wt] + item.val);
          } else {
            dp[i][w] = dp[i - 1][w];
          }
        }
      }

      const optimalVal = dp[N][W];
      knapsackScore.textContent = `Optimal Score: ${optimalVal} pts`;

      // Backtrack selected items
      let w = W;
      const selected = [];
      for (let i = N; i > 0 && optimalVal > 0; i--) {
        if (dp[i][w] !== dp[i - 1][w]) {
          selected.push(activeList[i - 1]);
          w -= activeList[i - 1].wt;
        }
      }

      if (selected.length === 0) {
        knapsackResult.textContent = 'Insufficient fleet capacity for active emergencies.';
      } else {
        const names = selected.map((s) => s.unit).join(', ');
        knapsackResult.textContent = `Optimally deployed ${selected.length} response team(s) [${names}]. Total preserved severity: ${optimalVal} priority points.`;
      }
    }

    surgeSlider.addEventListener('input', runKnapsackSim);
    capacitySlider.addEventListener('input', runKnapsackSim);
    runKnapsackSim();
  }

  // ---------------------------------------------------------------------------
  // 4. Telemetry Radar Screen Canvas
  // ---------------------------------------------------------------------------
  const radarCanvas = document.getElementById('radar-canvas');
  if (radarCanvas) {
    const rctx = radarCanvas.getContext('2d');
    const rWidth = (radarCanvas.width = radarCanvas.offsetWidth || 600);
    const rHeight = (radarCanvas.height = 280);
    const centerX = rWidth / 2;
    const centerY = rHeight / 2;
    let angle = 0;

    const vehicles = [
      { x: centerX - 80, y: centerY - 40, label: 'Amb-01', type: 'amb' },
      { x: centerX + 110, y: centerY + 30, label: 'Amb-02', type: 'amb' },
      { x: centerX - 140, y: centerY + 60, label: 'Fire-01', type: 'fire' },
      { x: centerX + 40, y: centerY - 70, label: 'Amb-03', type: 'amb' },
      { x: centerX + 180, y: centerY - 20, label: 'Rescue-01', type: 'res' },
    ];

    function drawRadar() {
      rctx.fillStyle = 'rgba(3, 3, 5, 0.18)';
      rctx.fillRect(0, 0, rWidth, rHeight);

      // Radar concentric rings
      rctx.strokeStyle = 'rgba(218, 250, 156, 0.12)';
      rctx.lineWidth = 1;
      [40, 80, 120, 160].forEach((r) => {
        rctx.beginPath();
        rctx.arc(centerX, centerY, r, 0, Math.PI * 2);
        rctx.stroke();
      });

      // Crosshairs
      rctx.beginPath();
      rctx.moveTo(centerX - 170, centerY);
      rctx.lineTo(centerX + 170, centerY);
      rctx.moveTo(centerX, centerY - 130);
      rctx.lineTo(centerX, centerY + 130);
      rctx.stroke();

      // Sweep line
      angle += 0.035;
      const sweepX = centerX + Math.cos(angle) * 165;
      const sweepY = centerY + Math.sin(angle) * 165;

      const grad = rctx.createRadialGradient(centerX, centerY, 0, centerX, centerY, 165);
      grad.addColorStop(0, 'rgba(218, 250, 156, 0.25)');
      grad.addColorStop(1, 'rgba(218, 250, 156, 0)');

      rctx.beginPath();
      rctx.moveTo(centerX, centerY);
      rctx.arc(centerX, centerY, 165, angle - 0.35, angle);
      rctx.closePath();
      rctx.fillStyle = grad;
      rctx.fill();

      // Draw vehicles
      vehicles.forEach((v) => {
        rctx.beginPath();
        rctx.arc(v.x, v.y, 4, 0, Math.PI * 2);
        rctx.fillStyle = v.type === 'fire' ? '#fbbf24' : '#dafa9c';
        rctx.shadowColor = v.type === 'fire' ? '#fbbf24' : '#dafa9c';
        rctx.shadowBlur = 8;
        rctx.fill();
        rctx.shadowBlur = 0;

        rctx.font = '10px Geist Mono, monospace';
        rctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
        rctx.fillText(v.label, v.x + 8, v.y + 3);
      });

      requestAnimationFrame(drawRadar);
    }

    drawRadar();
  }
})();
