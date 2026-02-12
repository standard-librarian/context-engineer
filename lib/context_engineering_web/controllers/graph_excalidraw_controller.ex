defmodule ContextEngineeringWeb.GraphExcalidrawController do
  use ContextEngineeringWeb, :controller

  def visualize(conn, _params) do
    html(conn, """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Knowledge Graph • Excalidraw Style</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        body {
          font-family: 'Virgil', 'Segoe UI Emoji', sans-serif;
          background: #fafafa;
          color: #1e1e1e;
          overflow: hidden;
        }

        #canvas-container {
          width: 100vw;
          height: 100vh;
          position: relative;
          overflow: hidden;
        }

        canvas {
          display: block;
          cursor: grab;
        }

        canvas:active {
          cursor: grabbing;
        }

        .controls {
          position: fixed;
          top: 20px;
          left: 20px;
          z-index: 1000;
          background: rgba(255, 255, 255, 0.95);
          border: 2px solid #1e1e1e;
          border-radius: 8px;
          padding: 16px;
          min-width: 280px;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
        }

        .controls h3 {
          margin: 0 0 12px 0;
          font-size: 14px;
          font-weight: 700;
          color: #1e1e1e;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          cursor: pointer;
          user-select: none;
        }

        .controls.collapsed {
          min-width: 180px;
        }

        .controls.collapsed .control-content {
          display: none;
        }

        .toggle-btn {
          background: transparent !important;
          border: none;
          color: #666;
          font-size: 20px;
          cursor: pointer;
          padding: 0 !important;
          width: auto !important;
          line-height: 1;
          margin: 0 !important;
          transition: transform 0.2s;
        }

        .toggle-btn:hover {
          color: #1e1e1e;
        }

        .controls.collapsed .toggle-btn {
          transform: rotate(180deg);
        }

        .control-group {
          margin-bottom: 12px;
        }

        .control-group:last-child {
          margin-bottom: 0;
        }

        .control-group label {
          display: block;
          font-size: 12px;
          margin-bottom: 6px;
          color: #666;
          font-weight: 500;
        }

        .control-group select,
        .control-group input[type="range"] {
          width: 100%;
          padding: 8px;
          border: 2px solid #1e1e1e;
          border-radius: 4px;
          background: white;
          font-size: 12px;
        }

        .control-group input[type="range"] {
          padding: 0;
          height: 6px;
        }

        button {
          background: #1e1e1e;
          color: white;
          border: none;
          padding: 10px 16px;
          border-radius: 4px;
          cursor: pointer;
          font-size: 12px;
          font-weight: 600;
          width: 100%;
          transition: background 0.2s;
          margin-top: 4px;
        }

        button:hover {
          background: #333;
        }

        button:active {
          background: #000;
        }

        .stats {
          position: fixed;
          bottom: 20px;
          left: 20px;
          z-index: 1000;
          background: rgba(255, 255, 255, 0.95);
          border: 2px solid #1e1e1e;
          border-radius: 8px;
          padding: 12px 16px;
          font-size: 13px;
          color: #666;
          font-family: 'Virgil', 'Segoe UI Emoji', sans-serif;
          font-weight: 400;
        }

        .stats div {
          margin-bottom: 4px;
        }

        .stats div:last-child {
          margin-bottom: 0;
        }

        .stats .value {
          color: #1e1e1e;
          font-weight: 700;
        }

        .loading {
          position: fixed;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          font-size: 18px;
          color: #1e1e1e;
          z-index: 2000;
          text-align: center;
        }

        .spinner {
          border: 3px solid #f0f0f0;
          border-top: 3px solid #1e1e1e;
          border-radius: 50%;
          width: 40px;
          height: 40px;
          animation: spin 1s linear infinite;
          margin: 0 auto 12px;
        }

        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }

        .info-panel {
          position: fixed;
          top: 20px;
          right: 20px;
          z-index: 1000;
          background: rgba(255, 255, 255, 0.95);
          border: 2px solid #1e1e1e;
          border-radius: 8px;
          padding: 16px;
          min-width: 320px;
          max-width: 400px;
          max-height: calc(100vh - 100px);
          overflow-y: auto;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
          display: none;
        }

        .info-panel.visible {
          display: block;
        }

        .info-panel h3 {
          margin: 0 0 12px 0;
          font-size: 16px;
          font-weight: 700;
          color: #1e1e1e;
          display: flex;
          align-items: center;
          justify-content: space-between;
        }

        .close-btn {
          background: transparent !important;
          border: none;
          color: #666;
          font-size: 24px;
          cursor: pointer;
          padding: 0 !important;
          width: auto !important;
          line-height: 1;
          margin: 0 !important;
        }

        .close-btn:hover {
          color: #1e1e1e;
        }

        .info-section {
          margin-bottom: 16px;
          padding-bottom: 16px;
          border-bottom: 2px solid #f0f0f0;
        }

        .info-section:last-child {
          border-bottom: none;
          margin-bottom: 0;
          padding-bottom: 0;
        }

        .info-section h4 {
          font-size: 11px;
          text-transform: uppercase;
          color: #666;
          margin-bottom: 8px;
          letter-spacing: 1px;
          font-weight: 700;
        }

        .info-row {
          display: flex;
          justify-content: space-between;
          margin-bottom: 6px;
          font-size: 13px;
        }

        .info-row .label {
          color: #666;
          font-weight: 500;
        }

        .info-row .value {
          color: #1e1e1e;
          font-weight: 600;
        }

        .node-badge {
          display: inline-block;
          padding: 6px 12px;
          border-radius: 4px;
          font-size: 11px;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 12px;
          border: 2px solid #1e1e1e;
        }

        .node-badge.adr { background: #e9d5ff; color: #6b21a8; }
        .node-badge.failure { background: #fecaca; color: #991b1b; }
        .node-badge.meeting { background: #bfdbfe; color: #1e3a8a; }
        .node-badge.snapshot { background: #bbf7d0; color: #065f46; }
        .node-badge.context { background: #bbf7d0; color: #065f46; }

        .tag-list {
          display: flex;
          flex-wrap: wrap;
          gap: 6px;
          margin-top: 8px;
        }

        .tag {
          background: #f0f0f0;
          color: #666;
          padding: 4px 8px;
          border-radius: 4px;
          font-size: 11px;
          border: 1px solid #ddd;
          font-weight: 600;
        }

        .reference-list {
          margin-top: 8px;
        }

        .reference-item {
          background: #fafafa;
          border: 2px solid #e5e5e5;
          border-radius: 6px;
          padding: 10px;
          margin-bottom: 8px;
          cursor: pointer;
          transition: all 0.2s;
        }

        .reference-item:hover {
          border-color: #1e1e1e;
          background: #fff;
        }

        .reference-item .ref-title {
          font-size: 13px;
          font-weight: 600;
          color: #1e1e1e;
          margin-bottom: 4px;
        }

        .reference-item .ref-meta {
          font-size: 11px;
          color: #666;
          display: flex;
          gap: 12px;
        }
      </style>
    </head>
    <body>
      <div id="loading" class="loading">
        <div class="spinner"></div>
        Loading graph data...
      </div>

      <div class="controls">
        <h3 id="controls-header">
          <span>Graph Controls</span>
          <button class="toggle-btn" id="toggle-controls" title="Minimize/Maximize">▼</button>
        </h3>

        <div class="control-content">
        <div class="control-group">
          <label for="layout-type">Layout Algorithm</label>
          <select id="layout-type">
            <option value="dagre">Dagre (Hierarchical)</option>
            <option value="force">Force-Directed</option>
            <option value="circular">Circular</option>
          </select>
        </div>

        <div class="control-group">
          <label for="roughness">Roughness: <span id="roughness-value">2</span></label>
          <input type="range" id="roughness" min="0" max="3" value="2" step="0.5">
        </div>

        <div class="control-group">
          <label for="node-spacing">Node Spacing: <span id="spacing-value">150</span></label>
          <input type="range" id="node-spacing" min="50" max="300" value="150" step="10">
        </div>

        <div class="control-group">
        </div>

        <div class="control-group">
          <button id="regenerate">Regenerate Layout</button>
          <button id="download-excalidraw">Download .excalidraw</button>
          <button id="reset-view">Reset View</button>
        </div>
        </div>
      </div>

      <div id="info-panel" class="info-panel">
        <h3>
          <span id="info-title">Node Details</span>
          <button class="close-btn" id="close-info">&times;</button>
        </h3>
        <div id="info-content"></div>
      </div>

      <div class="stats">
        <div>Nodes: <span class="value" id="node-count">0</span></div>
        <div>Edges: <span class="value" id="edge-count">0</span></div>
        <div>Layout: <span class="value" id="layout-name">Dagre</span></div>
      </div>

      <div id="canvas-container">
        <canvas id="graph-canvas"></canvas>
      </div>

      <!-- Load dependencies -->
      <script src="https://unpkg.com/dagre@0.8.5/dist/dagre.min.js"></script>
      <script src="https://d3js.org/d3.v7.min.js"></script>
      <script src="https://cdn.jsdelivr.net/npm/roughjs@4.5.2/bundled/rough.js"></script>

      <!-- Load Virgil font for hand-drawn text -->
      <style>
        @font-face {
          font-family: 'Virgil';
          src: url('https://excalidraw.com/Virgil.woff2') format('woff2');
        }
      </style>

      <script>
        // Type colors
        const TYPE_COLORS = {
          adr: '#a855f7',
          failure: '#ef4444',
          meeting: '#3b82f6',
          context: '#10b981',
          snapshot: '#10b981',
          default: '#6b7280'
        };

        let graphData = { nodes: [], links: [] };
        let canvas, ctx, rc;
        let viewOffset = { x: 0, y: 0 };
        let viewScale = 1;
        let isDragging = false;
        let dragStart = { x: 0, y: 0 };
        let nodePositions = {};
        let hoveredNode = null;
        let selectedNode = null;
        let drawnNodes = new Map(); // Cache drawn node elements
        let drawnArrows = new Map(); // Cache drawn arrow elements

        // Fetch graph data
        async function fetchGraphData() {
          try {
            const response = await fetch('/api/graph/export?max_nodes=100');
            const data = await response.json();
            return data;
          } catch (error) {
            console.error('Error fetching graph data:', error);
            return { nodes: [], edges: [] };
          }
        }

        // Generate unique ID
        function generateId() {
          return Math.random().toString(36).substring(2, 15);
        }

        // Dagre layout
        function calculateDagreLayout(nodes, links, spacing = 150) {
          const g = new dagre.graphlib.Graph();
          g.setGraph({
            rankdir: 'TB',
            nodesep: spacing,
            ranksep: spacing,
            marginx: 100,
            marginy: 100
          });
          g.setDefaultEdgeLabel(() => ({}));

          nodes.forEach(node => {
            g.setNode(node.id, { width: 150, height: 80 });
          });

          links.forEach(link => {
            g.setEdge(link.source, link.target);
          });

          dagre.layout(g);

          const positions = {};
          nodes.forEach(node => {
            const n = g.node(node.id);
            positions[node.id] = { x: n.x, y: n.y };
          });

          return positions;
        }

        // Force-directed layout
        function calculateForceLayout(nodes, links, spacing = 150) {
          const simulation = d3.forceSimulation(nodes)
            .force('link', d3.forceLink(links).id(d => d.id).distance(spacing))
            .force('charge', d3.forceManyBody().strength(-spacing * 2))
            .force('center', d3.forceCenter(canvas.width / 2, canvas.height / 2))
            .force('collision', d3.forceCollide(80))
            .stop();

          for (let i = 0; i < 300; i++) {
            simulation.tick();
          }

          const positions = {};
          nodes.forEach(node => {
            positions[node.id] = { x: node.x, y: node.y };
          });

          return positions;
        }

        // Circular layout
        function calculateCircularLayout(nodes, links, spacing = 150) {
          const radius = Math.max(300, nodes.length * 30);
          const angleStep = (2 * Math.PI) / nodes.length;
          const centerX = canvas.width / 2;
          const centerY = canvas.height / 2;

          const positions = {};
          nodes.forEach((node, i) => {
            const angle = i * angleStep;
            positions[node.id] = {
              x: centerX + radius * Math.cos(angle),
              y: centerY + radius * Math.sin(angle)
            };
          });

          return positions;
        }

        // Transform point to screen coordinates
        function toScreen(x, y) {
          return {
            x: (x + viewOffset.x) * viewScale,
            y: (y + viewOffset.y) * viewScale
          };
        }

        // Transform point to world coordinates
        function toWorld(x, y) {
          return {
            x: x / viewScale - viewOffset.x,
            y: y / viewScale - viewOffset.y
          };
        }

        // Draw hand-drawn node (circle with title above)
        function drawNode(node, position, roughness) {
          const radius = 40;
          const screenPos = toScreen(position.x, position.y);

          const isHovered = hoveredNode && hoveredNode.id === node.id;
          const isSelected = selectedNode && selectedNode.id === node.id;

          // Create cache key based on node properties that affect drawing
          const cacheKey = `${node.id}-${roughness}-${node.type}`;

          // Get or create cached drawing
          if (!drawnNodes.has(cacheKey)) {
            const options = {
              fill: TYPE_COLORS[node.type] || TYPE_COLORS.default,
              fillStyle: 'hachure',
              stroke: '#333',
              strokeWidth: 2,
              roughness: roughness,
              hachureAngle: 60,
              hachureGap: 4,
              seed: Math.floor(Math.random() * 1000000) // Fixed seed per node
            };

            // Generate and cache the drawable
            const drawable = rc.generator.circle(0, 0, radius * 2, options);
            drawnNodes.set(cacheKey, drawable);
          }

          // Draw the cached circle
          const drawable = drawnNodes.get(cacheKey);
          ctx.save();
          ctx.translate(screenPos.x, screenPos.y);
          ctx.scale(viewScale, viewScale);
          rc.draw(drawable);
          ctx.restore();

          // Highlight if hovered or selected
          if (isHovered || isSelected) {
            ctx.save();
            ctx.strokeStyle = '#1e1e1e';
            ctx.lineWidth = 3;
            ctx.beginPath();
            const scaledRadius = radius * viewScale;
            ctx.arc(screenPos.x, screenPos.y, scaledRadius, 0, 2 * Math.PI);
            ctx.stroke();
            ctx.restore();
          }

          // Draw title above the circle with hand-drawn style
          ctx.save();
          ctx.font = `${Math.max(12, 16 * viewScale)}px Virgil, "Segoe UI Emoji", sans-serif`;
          ctx.fillStyle = '#1e1e1e';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'bottom';

          // Add slight variation to make text look hand-drawn
          ctx.shadowColor = 'rgba(0, 0, 0, 0.1)';
          ctx.shadowBlur = 1;
          ctx.shadowOffsetX = 0.5;
          ctx.shadowOffsetY = 0.5;

          const text = node.name.length > 25 ? node.name.substring(0, 22) + '...' : node.name;
          const scaledRadius = radius * viewScale;
          const textY = screenPos.y - scaledRadius - (10 * viewScale);

          // Draw text with slight roughness
          ctx.fillText(text, screenPos.x, textY);
          ctx.restore();
        }

        // Draw hand-drawn arrow
        function drawArrow(link, positions, roughness) {
          const source = positions[link.source];
          const target = positions[link.target];

          if (!source || !target) return;

          const sourceScreen = toScreen(source.x, source.y);
          const targetScreen = toScreen(target.x, target.y);

          const isHighlighted = (hoveredNode &&
            (hoveredNode.id === link.source || hoveredNode.id === link.target));

          // Create cache key
          const cacheKey = `${link.source}-${link.target}-${roughness}`;

          // Get or create cached line
          if (!drawnArrows.has(cacheKey)) {
            const options = {
              stroke: '#9ca3af',
              strokeWidth: 1.5,
              roughness: roughness,
              seed: Math.floor(Math.random() * 1000000)
            };

            const drawable = rc.generator.line(0, 0, target.x - source.x, target.y - source.y, options);
            drawnArrows.set(cacheKey, drawable);
          }

          // Draw cached line
          const drawable = drawnArrows.get(cacheKey);
          ctx.save();
          ctx.translate(sourceScreen.x, sourceScreen.y);
          ctx.scale(viewScale, viewScale);
          ctx.strokeStyle = isHighlighted ? '#6b7280' : '#9ca3af';
          ctx.lineWidth = isHighlighted ? 2 : 1.5;
          rc.draw(drawable);
          ctx.restore();

          // Draw arrowhead
          const dx = targetScreen.x - sourceScreen.x;
          const dy = targetScreen.y - sourceScreen.y;
          const angle = Math.atan2(dy, dx);
          const arrowSize = 10 * viewScale;

          const arrowX = targetScreen.x - Math.cos(angle) * 40 * viewScale;
          const arrowY = targetScreen.y - Math.sin(angle) * 40 * viewScale;

          ctx.save();
          ctx.translate(arrowX, arrowY);
          ctx.rotate(angle);
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(-arrowSize, -arrowSize / 2);
          ctx.lineTo(-arrowSize, arrowSize / 2);
          ctx.closePath();
          ctx.fillStyle = isHighlighted ? '#6b7280' : '#9ca3af';
          ctx.fill();
          ctx.restore();
        }

        // Render graph
        function render() {
          ctx.clearRect(0, 0, canvas.width, canvas.height);
          ctx.fillStyle = '#fafafa';
          ctx.fillRect(0, 0, canvas.width, canvas.height);

          const roughness = parseFloat(document.getElementById('roughness').value);

          // Draw arrows
          graphData.links.forEach(link => {
            drawArrow(link, nodePositions, roughness);
          });

          // Draw nodes
          graphData.nodes.forEach(node => {
            const position = nodePositions[node.id];
            if (position) {
              drawNode(node, position, roughness);
            }
          });
        }

        // Get node at position
        function getNodeAtPosition(x, y) {
          const worldPos = toWorld(x, y);

          for (const node of graphData.nodes) {
            const pos = nodePositions[node.id];
            if (!pos) continue;

            const dx = worldPos.x - pos.x;
            const dy = worldPos.y - pos.y;
            const distance = Math.sqrt(dx * dx + dy * dy);

            if (distance < 50) {
              return node;
            }
          }

          return null;
        }

        // Show node info panel
        function showNodeInfo(node) {
          selectedNode = node;
          const panel = document.getElementById('info-panel');
          const title = document.getElementById('info-title');
          const content = document.getElementById('info-content');

          title.textContent = node.name;
          panel.classList.add('visible');

          const connectedLinks = graphData.links.filter(
            link => link.source === node.id || link.target === node.id
          );

          const connectedNodeIds = new Set();
          connectedLinks.forEach(link => {
            connectedNodeIds.add(link.source);
            connectedNodeIds.add(link.target);
          });
          connectedNodeIds.delete(node.id);

          const connectedNodes = Array.from(connectedNodeIds).map(id =>
            graphData.nodes.find(n => n.id === id)
          ).filter(n => n);

          let html = \`
            <div class="info-section">
              <div class="node-badge \${node.type}">\${node.type.toUpperCase()}</div>
              <div class="info-row">
                <span class="label">ID</span>
                <span class="value">\${node.id}</span>
              </div>
              \${node.status ? \`
                <div class="info-row">
                  <span class="label">Status</span>
                  <span class="value">\${node.status}</span>
                </div>
              \` : ''}
              \${node.created_date ? \`
                <div class="info-row">
                  <span class="label">Created</span>
                  <span class="value">\${new Date(node.created_date).toLocaleDateString()}</span>
                </div>
              \` : ''}
            </div>
          \`;

          if (node.tags && node.tags.length > 0) {
            html += \`
              <div class="info-section">
                <h4>Tags</h4>
                <div class="tag-list">
                  \${node.tags.map(tag => \`<span class="tag">\${tag}</span>\`).join('')}
                </div>
              </div>
            \`;
          }

          if (connectedNodes.length > 0) {
            html += \`
              <div class="info-section">
                <h4>Connected Nodes (\${connectedNodes.length})</h4>
                <div class="reference-list">
                  \${connectedNodes.map(cn => \`
                    <div class="reference-item" data-node-id="\${cn.id}">
                      <div class="ref-title">\${cn.title || cn.name || cn.id}</div>
                      <div class="ref-meta">
                        <span class="node-badge \${cn.type}">\${cn.type}</span>
                      </div>
                    </div>
                  \`).join('')}
                </div>
              </div>
            \`;
          }

          html += \`
            <div class="info-section">
              <h4>Connections</h4>
              <div class="info-row">
                <span class="label">Total Links</span>
                <span class="value">\${connectedLinks.length}</span>
              </div>
            </div>
          \`;

          content.innerHTML = html;

          // Add click handlers
          document.querySelectorAll('.reference-item').forEach(item => {
            item.addEventListener('click', () => {
              const nodeId = item.getAttribute('data-node-id');
              const clickedNode = graphData.nodes.find(n => n.id === nodeId);
              if (clickedNode) {
                const pos = nodePositions[clickedNode.id];
                viewOffset.x = canvas.width / 2 / viewScale - pos.x;
                viewOffset.y = canvas.height / 2 / viewScale - pos.y;
                render();
                showNodeInfo(clickedNode);
              }
            });
          });

          render();
        }

        // Export Excalidraw JSON
        function exportExcalidrawJSON() {
          const elements = [];
          const roughness = parseFloat(document.getElementById('roughness').value);

          // Create arrows
          graphData.links.forEach(link => {
            const source = nodePositions[link.source];
            const target = nodePositions[link.target];
            if (source && target) {
              elements.push({
                id: generateId(),
                type: 'arrow',
                x: source.x,
                y: source.y,
                width: target.x - source.x,
                height: target.y - source.y,
                strokeColor: '#6b7280',
                backgroundColor: 'transparent',
                fillStyle: 'hachure',
                strokeWidth: 2,
                strokeStyle: 'solid',
                roughness: roughness,
                opacity: 60,
                roundness: { type: 2 },
                seed: Math.floor(Math.random() * 1000000),
                points: [[0, 0], [target.x - source.x, target.y - source.y]],
                endArrowhead: 'arrow'
              });
            }
          });

          // Create nodes (circles)
          graphData.nodes.forEach(node => {
            const pos = nodePositions[node.id];
            if (pos) {
              const radius = 40;

              // Circle
              elements.push({
                id: generateId(),
                type: 'ellipse',
                x: pos.x - radius,
                y: pos.y - radius,
                width: radius * 2,
                height: radius * 2,
                strokeColor: '#1e1e1e',
                backgroundColor: TYPE_COLORS[node.type] || TYPE_COLORS.default,
                fillStyle: 'hachure',
                strokeWidth: 2,
                roughness: roughness,
                seed: Math.floor(Math.random() * 1000000)
              });

              // Title above circle with Virgil font
              const text = node.name.length > 25 ? node.name.substring(0, 22) + '...' : node.name;
              elements.push({
                id: generateId(),
                type: 'text',
                x: pos.x - 60,
                y: pos.y - radius - 30,
                width: 120,
                height: 25,
                text: text,
                fontSize: 16,
                fontFamily: 3,
                textAlign: 'center',
                verticalAlign: 'top',
                strokeColor: '#1e1e1e',
                backgroundColor: 'transparent',
                fillStyle: 'hachure',
                strokeWidth: 1,
                roughness: 0,
                opacity: 100
              });
            }
          });

          return {
            type: 'excalidraw',
            version: 2,
            source: 'https://excalidraw.com',
            elements: elements,
            appState: {
              viewBackgroundColor: '#ffffff'
            }
          };
        }

        // Download Excalidraw file
        function downloadExcalidrawFile() {
          const data = exportExcalidrawJSON();
          const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = \`knowledge-graph-\${Date.now()}.excalidraw\`;
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        }

        // Regenerate layout
        function regenerateLayout() {
          const layoutType = document.getElementById('layout-type').value;
          const spacing = parseFloat(document.getElementById('node-spacing').value);

          // Clear caches when regenerating layout
          drawnNodes.clear();
          drawnArrows.clear();

          if (layoutType === 'dagre') {
            nodePositions = calculateDagreLayout(graphData.nodes, graphData.links, spacing);
          } else if (layoutType === 'force') {
            nodePositions = calculateForceLayout(graphData.nodes, graphData.links, spacing);
          } else if (layoutType === 'circular') {
            nodePositions = calculateCircularLayout(graphData.nodes, graphData.links, spacing);
          }

          document.getElementById('layout-name').textContent =
            layoutType.charAt(0).toUpperCase() + layoutType.slice(1);

          render();
        }

        // Reset view
        function resetView() {
          viewOffset = { x: 0, y: 0 };
          viewScale = 1;
          render();
        }

        // Initialize
        async function init() {
          canvas = document.getElementById('graph-canvas');
          ctx = canvas.getContext('2d');
          rc = rough.canvas(canvas);

          canvas.width = window.innerWidth;
          canvas.height = window.innerHeight;

          // Mouse event handlers
          canvas.addEventListener('mousedown', (e) => {
            const rect = canvas.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            const node = getNodeAtPosition(x, y);
            if (node) {
              showNodeInfo(node);
            } else {
              isDragging = true;
              dragStart = { x: e.clientX, y: e.clientY };
            }
          });

          canvas.addEventListener('mousemove', (e) => {
            const rect = canvas.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            if (isDragging) {
              const dx = e.clientX - dragStart.x;
              const dy = e.clientY - dragStart.y;
              viewOffset.x += dx / viewScale;
              viewOffset.y += dy / viewScale;
              dragStart = { x: e.clientX, y: e.clientY };
              render();
            } else {
              const node = getNodeAtPosition(x, y);
              if (node !== hoveredNode) {
                hoveredNode = node;
                render();
              }
            }
          });

          canvas.addEventListener('mouseup', () => {
            isDragging = false;
          });

          canvas.addEventListener('wheel', (e) => {
            e.preventDefault();
            const scaleFactor = e.deltaY > 0 ? 0.9 : 1.1;
            viewScale *= scaleFactor;
            viewScale = Math.max(0.1, Math.min(5, viewScale));
            render();
          });

          window.addEventListener('resize', () => {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
            render();
          });

          const data = await fetchGraphData();

          const nodes = (data.nodes || []).map(node => ({
            id: node.id,
            name: node.title || node.label || node.name || node.id,
            title: node.title,
            type: node.type || 'default',
            status: node.status,
            tags: node.tags || [],
            created_date: node.created_date
          }));

          const links = (data.edges || data.links || []).map(link => ({
            source: link.from || link.source,
            target: link.to || link.target,
            type: link.type || link.label || ''
          }));

          const nodeIds = new Set(nodes.map(n => n.id));
          const validLinks = links.filter(link =>
            nodeIds.has(link.source) && nodeIds.has(link.target)
          );

          graphData = { nodes, links: validLinks };

          document.getElementById('node-count').textContent = nodes.length;
          document.getElementById('edge-count').textContent = validLinks.length;

          regenerateLayout();

          document.getElementById('loading').style.display = 'none';
        }

        // Event listeners
        document.getElementById('regenerate').addEventListener('click', regenerateLayout);
        document.getElementById('download-excalidraw').addEventListener('click', downloadExcalidrawFile);
        document.getElementById('reset-view').addEventListener('click', resetView);
        document.getElementById('close-info').addEventListener('click', () => {
          document.getElementById('info-panel').classList.remove('visible');
          selectedNode = null;
          render();
        });

        document.getElementById('roughness').addEventListener('input', () => {
          // Clear caches when roughness changes
          drawnNodes.clear();
          drawnArrows.clear();
          render();
        });

        // Toggle controls panel
        document.getElementById('toggle-controls').addEventListener('click', (e) => {
          e.stopPropagation();
          document.querySelector('.controls').classList.toggle('collapsed');
        });

        document.getElementById('controls-header').addEventListener('click', () => {
          document.querySelector('.controls').classList.toggle('collapsed');
        });

        // Start
        init();
      </script>
    </body>
    </html>
    """)
  end
end
