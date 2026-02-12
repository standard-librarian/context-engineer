defmodule ContextEngineeringWeb.GraphObsidianController do
  use ContextEngineeringWeb, :controller

  def visualize(conn, _params) do
    html(conn, """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Knowledge Graph • Obsidian Style</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          background: #1e1e1e;
          color: #dcddde;
          overflow: hidden;
        }

        #graph-container {
          width: 100vw;
          height: 100vh;
          background: #1e1e1e;
        }

        .controls {
          position: fixed;
          top: 20px;
          left: 20px;
          z-index: 1000;
          background: rgba(30, 30, 30, 0.95);
          border: 1px solid #3a3a3a;
          border-radius: 8px;
          padding: 16px;
          min-width: 280px;
          max-width: 320px;
          backdrop-filter: blur(10px);
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
        }

        .controls h3 {
          margin: 0 0 12px 0;
          font-size: 14px;
          font-weight: 600;
          color: #fff;
          text-transform: uppercase;
          letter-spacing: 0.5px;
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
          color: #a0a0a0;
        }

        .control-group input[type="range"] {
          width: 100%;
          height: 4px;
          background: #3a3a3a;
          border-radius: 2px;
          outline: none;
          -webkit-appearance: none;
        }

        .control-group input[type="range"]::-webkit-slider-thumb {
          -webkit-appearance: none;
          appearance: none;
          width: 14px;
          height: 14px;
          background: #7c3aed;
          cursor: pointer;
          border-radius: 50%;
        }

        .control-group input[type="range"]::-moz-range-thumb {
          width: 14px;
          height: 14px;
          background: #7c3aed;
          cursor: pointer;
          border-radius: 50%;
          border: none;
        }

        .control-group input[type="checkbox"] {
          margin-right: 8px;
          accent-color: #7c3aed;
        }

        .control-group .checkbox-label {
          display: inline;
          margin-left: 0;
          cursor: pointer;
        }

        .info-panel {
          position: fixed;
          top: 20px;
          right: 20px;
          z-index: 1000;
          background: rgba(30, 30, 30, 0.95);
          border: 1px solid #3a3a3a;
          border-radius: 8px;
          padding: 16px;
          min-width: 320px;
          max-width: 400px;
          max-height: calc(100vh - 100px);
          overflow-y: auto;
          backdrop-filter: blur(10px);
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
          display: none;
        }

        .info-panel.visible {
          display: block;
        }

        .info-panel h3 {
          margin: 0 0 12px 0;
          font-size: 16px;
          font-weight: 600;
          color: #fff;
          display: flex;
          align-items: center;
          justify-content: space-between;
        }

        .info-panel .close-btn {
          background: transparent;
          border: none;
          color: #a0a0a0;
          font-size: 20px;
          cursor: pointer;
          padding: 0;
          width: auto;
          line-height: 1;
        }

        .info-panel .close-btn:hover {
          color: #fff;
        }

        .info-section {
          margin-bottom: 16px;
          padding-bottom: 16px;
          border-bottom: 1px solid #3a3a3a;
        }

        .info-section:last-child {
          border-bottom: none;
          margin-bottom: 0;
          padding-bottom: 0;
        }

        .info-section h4 {
          font-size: 12px;
          text-transform: uppercase;
          color: #7c3aed;
          margin-bottom: 8px;
          letter-spacing: 0.5px;
        }

        .info-row {
          display: flex;
          justify-content: space-between;
          margin-bottom: 6px;
          font-size: 13px;
        }

        .info-row .label {
          color: #a0a0a0;
        }

        .info-row .value {
          color: #fff;
          font-weight: 500;
        }

        .node-badge {
          display: inline-block;
          padding: 4px 10px;
          border-radius: 12px;
          font-size: 11px;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 12px;
        }

        .node-badge.adr { background: #7c3aed; color: #fff; }
        .node-badge.failure { background: #ef4444; color: #fff; }
        .node-badge.meeting { background: #3b82f6; color: #fff; }
        .node-badge.snapshot { background: #10b981; color: #fff; }
        .node-badge.context { background: #10b981; color: #fff; }

        .tag-list {
          display: flex;
          flex-wrap: wrap;
          gap: 6px;
          margin-top: 8px;
        }

        .tag {
          background: #3a3a3a;
          color: #a0a0a0;
          padding: 4px 8px;
          border-radius: 4px;
          font-size: 11px;
        }

        .reference-list {
          margin-top: 8px;
        }

        .reference-item {
          background: #2a2a2a;
          border: 1px solid #3a3a3a;
          border-radius: 6px;
          padding: 10px;
          margin-bottom: 8px;
          cursor: pointer;
          transition: all 0.2s;
        }

        .reference-item:hover {
          border-color: #7c3aed;
          background: #333;
        }

        .reference-item .ref-title {
          font-size: 13px;
          font-weight: 500;
          color: #fff;
          margin-bottom: 4px;
        }

        .reference-item .ref-meta {
          font-size: 11px;
          color: #a0a0a0;
          display: flex;
          gap: 12px;
        }

        .stats {
          position: fixed;
          bottom: 20px;
          left: 20px;
          z-index: 1000;
          background: rgba(30, 30, 30, 0.95);
          border: 1px solid #3a3a3a;
          border-radius: 8px;
          padding: 12px 16px;
          font-size: 11px;
          color: #a0a0a0;
          backdrop-filter: blur(10px);
          font-family: 'Monaco', 'Courier New', monospace;
        }

        .stats div {
          margin-bottom: 4px;
        }

        .stats div:last-child {
          margin-bottom: 0;
        }

        .loading {
          position: fixed;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          font-size: 18px;
          color: #7c3aed;
          z-index: 2000;
        }

        .spinner {
          border: 3px solid #3a3a3a;
          border-top: 3px solid #7c3aed;
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

        button {
          background: #7c3aed;
          color: white;
          border: none;
          padding: 8px 16px;
          border-radius: 6px;
          cursor: pointer;
          font-size: 12px;
          font-weight: 500;
          width: 100%;
          transition: background 0.2s;
        }

        button:hover {
          background: #6d28d9;
        }

        button:active {
          background: #5b21b6;
        }

        .empty-state {
          text-align: center;
          color: #a0a0a0;
          font-size: 13px;
          padding: 20px;
        }

        /* Scrollbar styling */
        .info-panel::-webkit-scrollbar {
          width: 8px;
        }

        .info-panel::-webkit-scrollbar-track {
          background: #2a2a2a;
          border-radius: 4px;
        }

        .info-panel::-webkit-scrollbar-thumb {
          background: #3a3a3a;
          border-radius: 4px;
        }

        .info-panel::-webkit-scrollbar-thumb:hover {
          background: #4a4a4a;
        }
      </style>
    </head>
    <body>
      <div id="loading" class="loading">
        <div class="spinner"></div>
        Loading knowledge graph...
      </div>

      <div class="controls">
        <h3>Graph Controls</h3>

        <div class="control-group">
          <label for="charge-strength">Repulsion Force: <span id="charge-value">-300</span></label>
          <input type="range" id="charge-strength" min="-1000" max="-50" value="-300" step="50">
        </div>

        <div class="control-group">
          <label for="link-distance">Link Distance: <span id="link-value">50</span></label>
          <input type="range" id="link-distance" min="20" max="200" value="50" step="10">
        </div>

        <div class="control-group">
          <label for="collision-radius">Collision Radius: <span id="collision-value">12</span></label>
          <input type="range" id="collision-radius" min="5" max="30" value="12" step="1">
        </div>

        <div class="control-group">
          <label for="center-strength">Center Gravity: <span id="center-value">0.3</span></label>
          <input type="range" id="center-strength" min="0" max="1" value="0.3" step="0.1">
        </div>

        <div class="control-group">
          <input type="checkbox" id="show-labels" checked>
          <label for="show-labels" class="checkbox-label">Show Labels</label>
        </div>

        <div class="control-group">
          <input type="checkbox" id="show-arrows" checked>
          <label for="show-arrows" class="checkbox-label">Show Arrows</label>
        </div>

        <div class="control-group">
          <button id="reset-view">Reset View</button>
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
        <div>Nodes: <span id="node-count">0</span></div>
        <div>Edges: <span id="edge-count">0</span></div>
        <div>FPS: <span id="fps">60</span></div>
      </div>

      <div id="graph-container"></div>

      <!-- Load D3 first since it's needed by react-force-graph -->
      <script src="https://d3js.org/d3-force.v3.min.js"></script>

      <script type="importmap">
      {
        "imports": {
          "react": "https://esm.sh/react@18.2.0",
          "react-dom": "https://esm.sh/react-dom@18.2.0",
          "react-dom/client": "https://esm.sh/react-dom@18.2.0/client",
          "react-force-graph-2d": "https://esm.sh/react-force-graph-2d@1.25.4?deps=react@18.2.0,react-dom@18.2.0"
        }
      }
      </script>

      <script type="module">
        import React from 'react';
        import { createRoot } from 'react-dom/client';
        import ForceGraph2D from 'react-force-graph-2d';

        // Type colors matching Obsidian's aesthetic
        const TYPE_COLORS = {
          adr: '#7c3aed',
          failure: '#ef4444',
          meeting: '#3b82f6',
          context: '#10b981',
          snapshot: '#10b981',
          default: '#94a3b8'
        };

        // Global state for graph data and graph instance
        let fullGraphData = { nodes: [], links: [] };
        let selectedNode = null;
        let graphAppInstance = null;

        // Fetch graph data
        async function fetchGraphData() {
          try {
            const response = await fetch('/api/graph/export?max_nodes=500');
            const data = await response.json();
            return data;
          } catch (error) {
            console.error('Error fetching graph data:', error);
            return { nodes: [], edges: [] };
          }
        }



        // Show info panel with node details
        async function showNodeInfo(node) {
          selectedNode = node;
          const panel = document.getElementById('info-panel');
          const title = document.getElementById('info-title');
          const content = document.getElementById('info-content');

          title.textContent = node.name;
          panel.classList.add('visible');

          // Show loading state
          content.innerHTML = '<div class="empty-state">Loading details...</div>';

          // Get live graph data from the React component instance
          const liveGraphData = graphAppInstance ? graphAppInstance.state.graphData : fullGraphData;

          // Find original node data with full details
          const originalNode = fullGraphData.nodes.find(n => n.id === node.id);

          // Helper function to get node ID from link (handles both string and object references)
          const getNodeId = (nodeOrId) => {
            return typeof nodeOrId === 'object' ? nodeOrId.id : nodeOrId;
          };

          // Find connected nodes - use live graph data which has object references
          const connectedLinks = liveGraphData.links.filter(link => {
            const sourceId = getNodeId(link.source);
            const targetId = getNodeId(link.target);
            return sourceId === node.id || targetId === node.id;
          });

          console.log('Node:', node.id, 'Connected links:', connectedLinks.length);

          const connectedNodeIds = new Set();
          connectedLinks.forEach(link => {
            const sourceId = getNodeId(link.source);
            const targetId = getNodeId(link.target);
            connectedNodeIds.add(sourceId);
            connectedNodeIds.add(targetId);
          });
          connectedNodeIds.delete(node.id);

          const connectedNodes = Array.from(connectedNodeIds).map(id =>
            fullGraphData.nodes.find(n => n.id === id)
          ).filter(n => n);

          // Build info panel HTML
          let html = `
            <div class="info-section">
              <div class="node-badge ${node.type}">${node.type.toUpperCase()}</div>
              <div class="info-row">
                <span class="label">ID</span>
                <span class="value">${node.id}</span>
              </div>
              ${originalNode && originalNode.status ? `
                <div class="info-row">
                  <span class="label">Status</span>
                  <span class="value">${originalNode.status}</span>
                </div>
              ` : ''}
              ${originalNode && originalNode.created_date ? `
                <div class="info-row">
                  <span class="label">Created</span>
                  <span class="value">${new Date(originalNode.created_date).toLocaleDateString()}</span>
                </div>
              ` : ''}
              ${originalNode && originalNode.severity ? `
                <div class="info-row">
                  <span class="label">Severity</span>
                  <span class="value">${originalNode.severity}</span>
                </div>
              ` : ''}
            </div>
          `;

          // Tags
          if (originalNode && originalNode.tags && originalNode.tags.length > 0) {
            html += `
              <div class="info-section">
                <h4>Tags</h4>
                <div class="tag-list">
                  ${originalNode.tags.map(tag => `<span class="tag">${tag}</span>`).join('')}
                </div>
              </div>
            `;
          }

          // Connected nodes
          if (connectedNodes.length > 0) {
            html += `
              <div class="info-section">
                <h4>Connected Nodes (${connectedNodes.length})</h4>
                <div class="reference-list">
                  ${connectedNodes.map(cn => `
                    <div class="reference-item" data-node-id="${cn.id}">
                      <div class="ref-title">${cn.title || cn.name || cn.id}</div>
                      <div class="ref-meta">
                        <span class="node-badge ${cn.type}">${cn.type}</span>
                        ${cn.status ? `<span>Status: ${cn.status}</span>` : ''}
                      </div>
                    </div>
                  `).join('')}
                </div>
              </div>
            `;
          }

          // Connections summary
          html += `
            <div class="info-section">
              <h4>Connections</h4>
              <div class="info-row">
                <span class="label">Total Links</span>
                <span class="value">${connectedLinks.length}</span>
              </div>
              <div class="info-row">
                <span class="label">Incoming</span>
                <span class="value">${connectedLinks.filter(l => getNodeId(l.target) === node.id).length}</span>
              </div>
              <div class="info-row">
                <span class="label">Outgoing</span>
                <span class="value">${connectedLinks.filter(l => getNodeId(l.source) === node.id).length}</span>
              </div>
            </div>
          `;

          content.innerHTML = html;

          // Add click handlers for reference items
          document.querySelectorAll('.reference-item').forEach(item => {
            item.addEventListener('click', () => {
              const nodeId = item.getAttribute('data-node-id');
              const clickedNode = fullGraphData.nodes.find(n => n.id === nodeId);
              if (clickedNode && window.graphInstance) {
                // Center on the clicked node
                window.graphInstance.centerAt(clickedNode.x, clickedNode.y, 1000);
                window.graphInstance.zoom(2, 1000);

                // Update info panel
                setTimeout(() => showNodeInfo(clickedNode), 500);
              }
            });
          });
        }

        // Close info panel
        document.getElementById('close-info').addEventListener('click', () => {
          document.getElementById('info-panel').classList.remove('visible');
          selectedNode = null;
        });

        // Main application
        class GraphApp extends React.Component {
          constructor(props) {
            super(props);
            this.state = {
              graphData: { nodes: [], links: [] },
              loading: true,
              highlightNodes: new Set(),
              highlightLinks: new Set(),
              hoverNode: null
            };
            this.graphRef = React.createRef();
            this.fpsInterval = null;

            // Store instance globally
            graphAppInstance = this;
          }

          async componentDidMount() {
            const data = await fetchGraphData();

            // Process nodes - API returns nodes with 'title' field
            const nodes = (data.nodes || []).map(node => ({
              id: node.id,
              name: node.title || node.label || node.name || node.id,
              title: node.title,
              type: node.type || 'default',
              status: node.status,
              tags: node.tags || [],
              created_date: node.created_date,
              severity: node.severity,
              reference_count: node.reference_count || 0,
              color: TYPE_COLORS[node.type] || TYPE_COLORS.default
            }));

            // Process links - API returns 'edges' with 'from'/'to'
            const links = (data.edges || data.links || []).map(link => ({
              source: link.from || link.source,
              target: link.to || link.target,
              type: link.type || link.label || ''
            }));

            // Filter out any invalid links (where source or target node doesn't exist)
            const nodeIds = new Set(nodes.map(n => n.id));
            const validLinks = links.filter(link => {
              const valid = nodeIds.has(link.source) && nodeIds.has(link.target);
              if (!valid) {
                console.warn('Invalid link - missing node:', link);
              }
              return valid;
            });

            // Store in global state
            fullGraphData = { nodes, links: validLinks };

            console.log('Graph data loaded:', {
              nodes: nodes.length,
              totalLinks: links.length,
              validLinks: validLinks.length,
              sampleNode: nodes[0],
              sampleLink: validLinks[0],
              allLinkSources: validLinks.slice(0, 3).map(l => `${l.source} -> ${l.target}`)
            });

            this.setState({
              graphData: { nodes, links: validLinks },
              loading: false
            });

            // Hide loading screen
            document.getElementById('loading').style.display = 'none';

            // Update stats
            document.getElementById('node-count').textContent = nodes.length;
            document.getElementById('edge-count').textContent = validLinks.length;

            // Show message if no links
            if (validLinks.length === 0) {
              console.warn('No links found in graph data. Check that relationships exist in the database.');
            } else {
              console.log(`✓ Loaded ${validLinks.length} links between ${nodes.length} nodes`);
            }

            // Start FPS counter
            this.startFPSCounter();

            // Setup controls
            this.setupControls();

            // Focus graph and initialize forces
            setTimeout(() => {
              if (this.graphRef.current) {
                this.graphRef.current.zoomToFit(400, 50);
                window.graphInstance = this.graphRef.current;

                // Initialize custom forces with forceX/forceY for center gravity
                const centerX = window.innerWidth / 2;
                const centerY = window.innerHeight / 2;
                this.graphRef.current.d3Force('x', window.d3.forceX(centerX).strength(0.3));
                this.graphRef.current.d3Force('y', window.d3.forceY(centerY).strength(0.3));
                this.graphRef.current.d3Force('collide', window.d3.forceCollide(12));
              }
            }, 500);
          }

          componentWillUnmount() {
            if (this.fpsInterval) {
              clearInterval(this.fpsInterval);
            }
          }

          startFPSCounter() {
            let lastTime = performance.now();
            let frames = 0;

            this.fpsInterval = setInterval(() => {
              const now = performance.now();
              const fps = Math.round((frames * 1000) / (now - lastTime));
              document.getElementById('fps').textContent = fps;
              frames = 0;
              lastTime = now;
            }, 1000);

            const countFrame = () => {
              frames++;
              requestAnimationFrame(countFrame);
            };
            requestAnimationFrame(countFrame);
          }

          setupControls() {
            // Charge strength
            document.getElementById('charge-strength').addEventListener('input', (e) => {
              const value = parseFloat(e.target.value);
              document.getElementById('charge-value').textContent = value;
              if (this.graphRef.current) {
                this.graphRef.current.d3Force('charge').strength(value);
                this.graphRef.current.d3ReheatSimulation();
              }
            });

            // Link distance
            document.getElementById('link-distance').addEventListener('input', (e) => {
              const value = parseFloat(e.target.value);
              document.getElementById('link-value').textContent = value;
              if (this.graphRef.current) {
                this.graphRef.current.d3Force('link').distance(value);
                this.graphRef.current.d3ReheatSimulation();
              }
            });

            // Collision radius
            document.getElementById('collision-radius').addEventListener('input', (e) => {
              const value = parseFloat(e.target.value);
              document.getElementById('collision-value').textContent = value;
              if (this.graphRef.current) {
                this.graphRef.current.d3Force('collide', window.d3.forceCollide(value));
                this.graphRef.current.d3ReheatSimulation();
              }
            });

            // Center strength - use forceX/forceY which support strength
            document.getElementById('center-strength').addEventListener('input', (e) => {
              const value = parseFloat(e.target.value);
              document.getElementById('center-value').textContent = value;
              if (this.graphRef.current) {
                const centerX = window.innerWidth / 2;
                const centerY = window.innerHeight / 2;
                this.graphRef.current.d3Force('x', window.d3.forceX(centerX).strength(value));
                this.graphRef.current.d3Force('y', window.d3.forceY(centerY).strength(value));
                this.graphRef.current.d3ReheatSimulation();
              }
            });

            // Checkboxes
            document.getElementById('show-labels').addEventListener('change', () => {
              this.forceUpdate();
            });

            document.getElementById('show-arrows').addEventListener('change', () => {
              this.forceUpdate();
            });

            // Reset view
            document.getElementById('reset-view').addEventListener('click', () => {
              if (this.graphRef.current) {
                this.graphRef.current.zoomToFit(400, 50);
              }
            });
          }

          handleNodeHover(node) {
            const highlightNodes = new Set();
            const highlightLinks = new Set();

            if (node) {
              highlightNodes.add(node);

              // Highlight connected nodes and links
              this.state.graphData.links.forEach(link => {
                if (link.source.id === node.id || link.target.id === node.id) {
                  highlightLinks.add(link);
                  highlightNodes.add(link.source);
                  highlightNodes.add(link.target);
                }
              });
            }

            this.setState({
              highlightNodes,
              highlightLinks,
              hoverNode: node
            });
          }

          handleNodeClick(node) {
            if (node) {
              showNodeInfo(node);
              if (this.graphRef.current) {
                this.graphRef.current.centerAt(node.x, node.y, 1000);
                this.graphRef.current.zoom(2, 1000);
              }
            }
          }

          render() {
            const { graphData } = this.state;
            const showLabels = document.getElementById('show-labels')?.checked ?? true;
            const showArrows = document.getElementById('show-arrows')?.checked ?? true;

            return React.createElement(ForceGraph2D, {
              ref: this.graphRef,
              graphData: graphData,
              width: window.innerWidth,
              height: window.innerHeight,
              backgroundColor: '#1e1e1e',

              // Node appearance
              nodeLabel: node => node.name,
              nodeColor: node => {
                const { highlightNodes, hoverNode } = this.state;
                const isHighlight = highlightNodes.has(node);
                const isHover = hoverNode === node;
                if (isHighlight || isHover) {
                  return node.color;
                }
                return node.color + '80'; // 50% opacity
              },
              nodeRelSize: 8,
              nodeCanvasObjectMode: () => 'after',
              nodeCanvasObject: (node, ctx, globalScale) => {
                const { highlightNodes, hoverNode } = this.state;
                const isHighlight = highlightNodes.has(node);
                const isHover = hoverNode === node;

                // Draw glow for highlighted nodes
                if (isHover) {
                  ctx.beginPath();
                  ctx.arc(node.x, node.y, 10, 0, 2 * Math.PI);
                  ctx.fillStyle = node.color + '40';
                  ctx.shadowBlur = 20;
                  ctx.shadowColor = node.color;
                  ctx.fill();
                  ctx.shadowBlur = 0;
                }

                // Draw labels
                if (showLabels && (isHighlight || isHover || globalScale > 1.5)) {
                  const label = node.name;
                  const fontSize = isHover ? 14 : 12;
                  ctx.font = `${fontSize}px -apple-system, sans-serif`;
                  ctx.textAlign = 'center';
                  ctx.textBaseline = 'middle';

                  const textWidth = ctx.measureText(label).width;
                  const padding = 6;

                  // Background
                  ctx.fillStyle = 'rgba(30, 30, 30, 0.9)';
                  ctx.fillRect(
                    node.x - textWidth / 2 - padding / 2,
                    node.y + 12,
                    textWidth + padding,
                    fontSize + 4
                  );

                  // Text
                  ctx.fillStyle = isHighlight || isHover ? '#ffffff' : '#a0a0a0';
                  ctx.fillText(label, node.x, node.y + 14 + fontSize / 2);
                }
              },

              // Link appearance
              linkLabel: link => link.type || '',
              linkColor: link => {
                const { highlightLinks } = this.state;
                return highlightLinks.has(link) ?
                  'rgba(124, 58, 237, 0.8)' :
                  'rgba(148, 163, 184, 0.3)';
              },
              linkWidth: link => {
                const { highlightLinks } = this.state;
                return highlightLinks.has(link) ? 2 : 1;
              },
              linkDirectionalArrowLength: showArrows ? 6 : 0,
              linkDirectionalArrowRelPos: 0.8,
              linkDirectionalArrowColor: link => {
                const { highlightLinks } = this.state;
                return highlightLinks.has(link) ?
                  'rgba(124, 58, 237, 0.8)' :
                  'rgba(148, 163, 184, 0.3)';
              },
              linkLineDash: link => {
                const { highlightLinks } = this.state;
                return highlightLinks.has(link) ? null : [2, 2];
              },

              // Interactions
              onNodeHover: node => this.handleNodeHover(node),
              onNodeClick: node => this.handleNodeClick(node),
              onNodeDragEnd: node => {
                node.fx = node.x;
                node.fy = node.y;
              },

              // Physics
              d3AlphaDecay: 0.02,
              d3VelocityDecay: 0.3,
              warmupTicks: 100,
              cooldownTicks: 0,
              d3Force: (simulation) => {
                // Set up initial forces - center gravity will use forceX/forceY
                simulation
                  .force('charge').strength(-300)
                  .force('link').distance(50);
              },

              // Performance
              enableNodeDrag: true,
              enableZoomInteraction: true,
              enablePanInteraction: true
            });
          }
        }

        // Mount the app after D3 is loaded
        window.addEventListener('DOMContentLoaded', () => {
          const root = createRoot(document.getElementById('graph-container'));
          root.render(React.createElement(GraphApp));
        });
      </script>
    </body>
    </html>
    """)
  end
end
