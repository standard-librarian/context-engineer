defmodule ContextEngineeringWeb.GraphController do
  use ContextEngineeringWeb, :controller

  alias ContextEngineering.Contexts.Relationships.Graph

  def related(conn, %{"id" => id} = params) do
    type = Map.get(params, "type", "adr")
    depth = Map.get(params, "depth", "2") |> String.to_integer()

    related = Graph.find_related(id, type, depth: depth)
    json(conn, %{item_id: id, related: related})
  end

  def export(conn, params) do
    include_archived = Map.get(params, "include_archived", "false") == "true"
    max_nodes =
      case Integer.parse(Map.get(params, "max_nodes", "1000")) do
        {value, ""} when value > 0 -> value
        _ -> 1000
      end

    {:ok, graph_data} =
      Graph.export_graph(
        include_archived: include_archived,
        max_nodes: max_nodes
      )

    json(conn, graph_data)
  end

  def visualize(conn, _params) do
    html(conn, """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Graph View · Context Engineering</title>
      <script src="https://d3js.org/d3.v7.min.js"></script>
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        :root {
          --bg-primary: #1e1e1e;
          --bg-secondary: #252525;
          --bg-tertiary: #2d2d2d;
          --text-primary: #dcddde;
          --text-secondary: #b9bbbe;
          --text-muted: #72767d;
          --accent-purple: #9580ff;
          --accent-blue: #64b5f6;
          --accent-green: #69db7c;
          --accent-orange: #ffa94d;
          --accent-red: #ff6b6b;
          --accent-yellow: #ffd43b;
          --border: #3a3a3a;
          --node-adr: #9580ff;
          --node-context: #64b5f6;
          --node-glossary: #69db7c;
          --node-meeting: #ffd43b;
          --node-failure: #ff6b6b;
          --node-other: #ffa94d;
        }

        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
          background: var(--bg-primary);
          color: var(--text-primary);
          overflow: hidden;
          -webkit-font-smoothing: antialiased;
          -moz-osx-font-smoothing: grayscale;
        }

        #graph-container {
          width: 100vw;
          height: 100vh;
          cursor: grab;
        }

        #graph-container:active {
          cursor: grabbing;
        }

        #graph-container svg {
          display: block;
        }

        /* Control Panel */
        .controls {
          position: fixed;
          top: 20px;
          right: 20px;
          background: rgba(37, 37, 37, 0.95);
          border: 1px solid var(--border);
          border-radius: 8px;
          padding: 16px;
          backdrop-filter: blur(10px);
          z-index: 1000;
          min-width: 280px;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
        }

        .controls-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 16px;
          padding-bottom: 12px;
          border-bottom: 1px solid var(--border);
        }

        .controls-title {
          font-size: 14px;
          font-weight: 600;
          color: var(--text-primary);
        }

        .controls-close {
          background: none;
          border: none;
          color: var(--text-muted);
          font-size: 20px;
          cursor: pointer;
          padding: 0;
          width: 24px;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 4px;
          transition: all 0.2s;
        }

        .controls-close:hover {
          background: var(--bg-tertiary);
          color: var(--text-primary);
        }

        .control-group {
          margin-bottom: 16px;
        }

        .control-group:last-child {
          margin-bottom: 0;
        }

        .control-label {
          display: block;
          font-size: 12px;
          font-weight: 500;
          color: var(--text-secondary);
          margin-bottom: 8px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .control-row {
          display: flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 8px;
        }

        .control-row:last-child {
          margin-bottom: 0;
        }

        .slider {
          flex: 1;
          -webkit-appearance: none;
          height: 4px;
          background: var(--bg-tertiary);
          border-radius: 2px;
          outline: none;
        }

        .slider::-webkit-slider-thumb {
          -webkit-appearance: none;
          appearance: none;
          width: 14px;
          height: 14px;
          background: var(--accent-purple);
          border-radius: 50%;
          cursor: pointer;
          transition: transform 0.2s;
        }

        .slider::-webkit-slider-thumb:hover {
          transform: scale(1.2);
        }

        .slider::-moz-range-thumb {
          width: 14px;
          height: 14px;
          background: var(--accent-purple);
          border-radius: 50%;
          border: none;
          cursor: pointer;
          transition: transform 0.2s;
        }

        .slider::-moz-range-thumb:hover {
          transform: scale(1.2);
        }

        .slider-value {
          font-size: 12px;
          color: var(--accent-purple);
          font-weight: 500;
          min-width: 35px;
          text-align: right;
        }

        .checkbox-group {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .checkbox-item {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 6px 8px;
          border-radius: 4px;
          cursor: pointer;
          transition: background 0.2s;
        }

        .checkbox-item:hover {
          background: var(--bg-tertiary);
        }

        .checkbox {
          width: 16px;
          height: 16px;
          border: 2px solid var(--border);
          border-radius: 3px;
          background: transparent;
          cursor: pointer;
          appearance: none;
          position: relative;
          transition: all 0.2s;
          flex-shrink: 0;
        }

        .checkbox:checked {
          background: var(--accent-purple);
          border-color: var(--accent-purple);
        }

        .checkbox:checked::after {
          content: "✓";
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          color: white;
          font-size: 10px;
          font-weight: bold;
        }

        .checkbox-label {
          font-size: 13px;
          color: var(--text-secondary);
          cursor: pointer;
          flex: 1;
        }

        .checkbox-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
          flex-shrink: 0;
        }

        .button {
          width: 100%;
          padding: 8px 12px;
          background: var(--bg-tertiary);
          border: 1px solid var(--border);
          border-radius: 6px;
          color: var(--text-primary);
          font-size: 13px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s;
          font-family: 'Inter', sans-serif;
        }

        .button:hover {
          background: var(--accent-purple);
          border-color: var(--accent-purple);
        }

        /* Stats Bar */
        .stats-bar {
          position: fixed;
          bottom: 20px;
          left: 20px;
          background: rgba(37, 37, 37, 0.95);
          border: 1px solid var(--border);
          border-radius: 8px;
          padding: 12px 16px;
          backdrop-filter: blur(10px);
          display: flex;
          gap: 24px;
          z-index: 1000;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
        }

        .stat-item {
          display: flex;
          align-items: center;
          gap: 8px;
          font-size: 13px;
        }

        .stat-label {
          color: var(--text-muted);
        }

        .stat-value {
          color: var(--accent-purple);
          font-weight: 600;
        }

        /* Node Info Panel */
        .node-info {
          position: fixed;
          top: 20px;
          left: 20px;
          background: rgba(37, 37, 37, 0.95);
          border: 1px solid var(--border);
          border-radius: 8px;
          padding: 16px;
          backdrop-filter: blur(10px);
          z-index: 1000;
          max-width: 350px;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
          display: none;
        }

        .node-info.visible {
          display: block;
          animation: slideIn 0.3s ease;
        }

        @keyframes slideIn {
          from {
            opacity: 0;
            transform: translateX(-10px);
          }
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }

        .node-info-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 12px;
          padding-bottom: 12px;
          border-bottom: 1px solid var(--border);
        }

        .node-info-type {
          display: inline-block;
          padding: 3px 8px;
          border-radius: 4px;
          font-size: 11px;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 6px;
        }

        .node-info-title {
          font-size: 16px;
          font-weight: 600;
          color: var(--text-primary);
          margin-bottom: 4px;
        }

        .node-info-id {
          font-size: 12px;
          color: var(--text-muted);
          font-family: monospace;
        }

        .node-info-close {
          background: none;
          border: none;
          color: var(--text-muted);
          font-size: 20px;
          cursor: pointer;
          padding: 0;
          width: 24px;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 4px;
          transition: all 0.2s;
        }

        .node-info-close:hover {
          background: var(--bg-tertiary);
          color: var(--text-primary);
        }

        .node-info-content {
          font-size: 13px;
          line-height: 1.6;
          color: var(--text-secondary);
        }

        .node-info-section {
          margin-top: 12px;
          padding-top: 12px;
          border-top: 1px solid var(--border);
        }

        .node-info-section-title {
          font-size: 11px;
          font-weight: 600;
          color: var(--text-muted);
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 8px;
        }

        .node-info-meta {
          display: grid;
          grid-template-columns: auto 1fr;
          gap: 6px 12px;
          font-size: 12px;
        }

        .node-info-meta-key {
          color: var(--text-muted);
        }

        .node-info-meta-value {
          color: var(--text-secondary);
          word-break: break-word;
        }

        /* Loading */
        .loading {
          position: fixed;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          text-align: center;
          z-index: 2000;
        }

        .loading-spinner {
          width: 48px;
          height: 48px;
          border: 3px solid var(--bg-tertiary);
          border-top-color: var(--accent-purple);
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin: 0 auto 12px;
        }

        @keyframes spin {
          to { transform: rotate(360deg); }
        }

        .loading-text {
          color: var(--text-secondary);
          font-size: 14px;
        }

        /* Graph Styles */
        .link {
          stroke: var(--border);
          stroke-opacity: 0.3;
          fill: none;
          transition: stroke-opacity 0.2s;
        }

        .link.highlighted {
          stroke-opacity: 0.8;
          stroke-width: 2px;
        }

        .node-group {
          cursor: pointer;
          transition: opacity 0.2s;
        }

        .node-circle {
          stroke: rgba(255, 255, 255, 0.3);
          stroke-width: 2;
          filter: drop-shadow(0 0 8px currentColor);
        }

        .node-label {
          font-size: 11px;
          font-weight: 500;
          fill: var(--text-secondary);
          text-anchor: middle;
          pointer-events: none;
          user-select: none;
          opacity: 0;
          transition: opacity 0.2s;
        }

        .node-group:hover .node-label,
        .node-group.selected .node-label {
          opacity: 1;
        }

        .node-group:hover .node-circle {
          stroke-width: 3;
          filter: drop-shadow(0 0 12px currentColor);
        }

        .node-group.selected .node-circle {
          stroke: white;
          stroke-width: 3;
          filter: drop-shadow(0 0 16px currentColor);
        }

        /* Toggle Button */
        .toggle-controls {
          position: fixed;
          top: 20px;
          right: 20px;
          width: 40px;
          height: 40px;
          background: rgba(37, 37, 37, 0.95);
          border: 1px solid var(--border);
          border-radius: 8px;
          backdrop-filter: blur(10px);
          z-index: 999;
          display: none;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: all 0.2s;
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
        }

        .toggle-controls:hover {
          background: var(--bg-tertiary);
          transform: scale(1.05);
        }

        .toggle-controls svg {
          width: 20px;
          height: 20px;
          stroke: var(--text-secondary);
        }
      </style>
    </head>
    <body>
      <div id="graph-container"></div>

      <div class="loading" id="loading">
        <div class="loading-spinner"></div>
        <div class="loading-text">Loading graph...</div>
      </div>

      <div class="toggle-controls" id="toggle-controls">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="3" y1="12" x2="21" y2="12"></line>
          <line x1="3" y1="6" x2="21" y2="6"></line>
          <line x1="3" y1="18" x2="21" y2="18"></line>
        </svg>
      </div>

      <div class="controls" id="controls">
        <div class="controls-header">
          <div class="controls-title">Graph Controls</div>
          <button class="controls-close" onclick="toggleControls()">×</button>
        </div>

        <div class="control-group">
          <label class="control-label">Physics</label>
          <div class="control-row">
            <input type="range" class="slider" id="charge" min="10" max="500" value="150" oninput="updatePhysics()">
            <span class="slider-value" id="charge-value">150</span>
          </div>
          <div class="control-row">
            <input type="range" class="slider" id="distance" min="20" max="200" value="80" oninput="updatePhysics()">
            <span class="slider-value" id="distance-value">80</span>
          </div>
        </div>

        <div class="control-group">
          <label class="control-label">Node Size</label>
          <div class="control-row">
            <input type="range" class="slider" id="node-size" min="3" max="15" value="6" oninput="updateNodeSize()">
            <span class="slider-value" id="node-size-value">6</span>
          </div>
        </div>

        <div class="control-group">
          <label class="control-label">Filter Types</label>
          <div class="checkbox-group">
            <label class="checkbox-item">
              <input type="checkbox" class="checkbox" checked data-type="adr" onchange="updateFilters()">
              <span class="checkbox-label">Architecture</span>
              <div class="checkbox-dot" style="background: var(--node-adr);"></div>
            </label>
            <label class="checkbox-item">
              <input type="checkbox" class="checkbox" checked data-type="context" onchange="updateFilters()">
              <span class="checkbox-label">Context</span>
              <div class="checkbox-dot" style="background: var(--node-context);"></div>
            </label>
            <label class="checkbox-item">
              <input type="checkbox" class="checkbox" checked data-type="glossary" onchange="updateFilters()">
              <span class="checkbox-label">Glossary</span>
              <div class="checkbox-dot" style="background: var(--node-glossary);"></div>
            </label>
            <label class="checkbox-item">
              <input type="checkbox" class="checkbox" checked data-type="meeting" onchange="updateFilters()">
              <span class="checkbox-label">Meeting</span>
              <div class="checkbox-dot" style="background: var(--node-meeting);"></div>
            </label>
            <label class="checkbox-item">
              <input type="checkbox" class="checkbox" checked data-type="failure" onchange="updateFilters()">
              <span class="checkbox-label">Failure</span>
              <div class="checkbox-dot" style="background: var(--node-failure);"></div>
            </label>
            <label class="checkbox-item">
              <input type="checkbox" class="checkbox" checked data-type="other" onchange="updateFilters()">
              <span class="checkbox-label">Other</span>
              <div class="checkbox-dot" style="background: var(--node-other);"></div>
            </label>
          </div>
        </div>

        <div class="control-group">
          <button class="button" onclick="resetView()">Reset View</button>
        </div>
      </div>

      <div class="stats-bar" id="stats-bar">
        <div class="stat-item">
          <span class="stat-label">Nodes:</span>
          <span class="stat-value" id="node-count">0</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">Links:</span>
          <span class="stat-value" id="link-count">0</span>
        </div>
      </div>

      <div class="node-info" id="node-info">
        <div class="node-info-header">
          <div>
            <div class="node-info-type" id="node-type">Type</div>
            <div class="node-info-title" id="node-title">Node Title</div>
            <div class="node-info-id" id="node-id">node-id</div>
          </div>
          <button class="node-info-close" onclick="closeNodeInfo()">×</button>
        </div>
        <div class="node-info-content" id="node-content"></div>
      </div>

      <script>
        // Global state
        let svg, g, zoom;
        let simulation;
        let graphData = null;
        let width, height;
        let selectedNode = null;

        // Color mapping
        const nodeColors = {
          adr: '#9580ff',
          context: '#64b5f6',
          glossary: '#69db7c',
          meeting: '#ffd43b',
          failure: '#ff6b6b',
          other: '#ffa94d'
        };

        // Initialize
        function init() {
          const container = document.getElementById('graph-container');
          width = container.clientWidth;
          height = container.clientHeight;

          // Create SVG
          svg = d3.select('#graph-container')
            .append('svg')
            .attr('width', width)
            .attr('height', height);

          // Create zoom behavior
          zoom = d3.zoom()
            .scaleExtent([0.1, 8])
            .on('zoom', (event) => {
              g.attr('transform', event.transform);
            });

          svg.call(zoom);

          // Main group
          g = svg.append('g');

          // Create layers (order matters for rendering)
          g.append('g').attr('class', 'links-layer');
          g.append('g').attr('class', 'nodes-layer');

          // Handle resize
          window.addEventListener('resize', () => {
            width = container.clientWidth;
            height = container.clientHeight;
            svg.attr('width', width).attr('height', height);
            if (simulation) {
              simulation.force('center', d3.forceCenter(width / 2, height / 2));
              simulation.alpha(0.3).restart();
            }
          });

          // Click outside to deselect
          svg.on('click', (event) => {
            if (event.target === event.currentTarget || event.target.tagName === 'svg') {
              deselectNode();
            }
          });

          loadGraph();
        }

        // Load graph data
        async function loadGraph() {
          const loading = document.getElementById('loading');

          try {
            const response = await fetch('/api/graph/export?max_nodes=500');
            const data = await response.json();

            graphData = {
              nodes: (data.nodes || []).map(node => ({
                ...node,
                id: node.id
              })),
              links: (data.edges || []).map(edge => ({
                source: edge.from || edge.source,
                target: edge.to || edge.target
              }))
            };

            updateStats();
            initSimulation();
            renderGraph();

            loading.style.display = 'none';
          } catch (error) {
            console.error('Error loading graph:', error);
            document.querySelector('.loading-text').textContent = 'Error loading graph data';
          }
        }

        // Initialize D3 force simulation
        function initSimulation() {
          const charge = -parseInt(document.getElementById('charge').value);
          const distance = parseInt(document.getElementById('distance').value);

          simulation = d3.forceSimulation(graphData.nodes)
            .force('link', d3.forceLink(graphData.links)
              .id(d => d.id)
              .distance(distance))
            .force('charge', d3.forceManyBody().strength(charge))
            .force('center', d3.forceCenter(width / 2, height / 2))
            .force('collision', d3.forceCollide().radius(15))
            .on('tick', ticked);
        }

        // Render graph elements
        function renderGraph() {
          if (!graphData) return;

          const nodeSize = parseInt(document.getElementById('node-size').value);

          // Clear existing
          g.select('.links-layer').selectAll('*').remove();
          g.select('.nodes-layer').selectAll('*').remove();

          // Create links
          const links = g.select('.links-layer')
            .selectAll('path')
            .data(graphData.links)
            .enter()
            .append('path')
            .attr('class', 'link')
            .attr('stroke', d => {
              const sourceType = d.source.type || 'other';
              return nodeColors[sourceType] || nodeColors.other;
            })
            .attr('stroke-width', 1.5);

          // Create node groups
          const nodes = g.select('.nodes-layer')
            .selectAll('g')
            .data(graphData.nodes)
            .enter()
            .append('g')
            .attr('class', 'node-group')
            .call(d3.drag()
              .on('start', dragStarted)
              .on('drag', dragged)
              .on('end', dragEnded))
            .on('click', (event, d) => {
              event.stopPropagation();
              selectNode(d);
            });

          // Node circles
          nodes.append('circle')
            .attr('class', 'node-circle')
            .attr('r', nodeSize)
            .attr('fill', d => nodeColors[d.type] || nodeColors.other)
            .style('color', d => nodeColors[d.type] || nodeColors.other);

          // Node labels
          nodes.append('text')
            .attr('class', 'node-label')
            .attr('dy', nodeSize + 12)
            .text(d => {
              const name = d.name || d.label || d.id;
              return name.length > 25 ? name.substring(0, 25) + '...' : name;
            });

          // Store references
          graphData.linkElements = links;
          graphData.nodeElements = nodes;
        }

        // Update positions on simulation tick
        function ticked() {
          // Update links with curved paths
          g.selectAll('.link').attr('d', d => {
            const dx = d.target.x - d.source.x;
            const dy = d.target.y - d.source.y;
            const dr = Math.sqrt(dx * dx + dy * dy) * 1.5;
            return `M${d.source.x},${d.source.y}A${dr},${dr} 0 0,1 ${d.target.x},${d.target.y}`;
          });

          // Update nodes
          g.selectAll('.node-group')
            .attr('transform', d => `translate(${d.x},${d.y})`);
        }

        // Drag handlers
        function dragStarted(event, d) {
          if (!event.active) simulation.alphaTarget(0.3).restart();
          d.fx = d.x;
          d.fy = d.y;
        }

        function dragged(event, d) {
          d.fx = event.x;
          d.fy = event.y;
        }

        function dragEnded(event, d) {
          if (!event.active) simulation.alphaTarget(0);
          d.fx = null;
          d.fy = null;
        }

        // Select node
        function selectNode(node) {
          selectedNode = node;

          // Update visual selection
          g.selectAll('.node-group').classed('selected', d => d.id === node.id);

          // Highlight connected links
          g.selectAll('.link').classed('highlighted', d => {
            const sourceId = d.source.id || d.source;
            const targetId = d.target.id || d.target;
            return sourceId === node.id || targetId === node.id;
          });

          // Show info panel
          showNodeInfo(node);
        }

        // Deselect node
        function deselectNode() {
          selectedNode = null;
          g.selectAll('.node-group').classed('selected', false);
          g.selectAll('.link').classed('highlighted', false);
          closeNodeInfo();
        }

        // Show node info panel
        function showNodeInfo(node) {
          const panel = document.getElementById('node-info');
          const type = document.getElementById('node-type');
          const title = document.getElementById('node-title');
          const id = document.getElementById('node-id');
          const content = document.getElementById('node-content');

          // Set type with color
          type.textContent = (node.type || 'other').toUpperCase();
          type.style.background = nodeColors[node.type] || nodeColors.other;
          type.style.color = '#000';

          // Set title and id
          title.textContent = node.name || node.label || node.id;
          id.textContent = node.id;

          // Build content
          let html = '';

          if (node.content) {
            html += `<div class="node-info-section">
              <div class="node-info-section-title">Content</div>
              <p>${node.content.substring(0, 200)}${node.content.length > 200 ? '...' : ''}</p>
            </div>`;
          }

          // Calculate connections
          const connections = graphData.links.filter(link => {
            const sourceId = link.source.id || link.source;
            const targetId = link.target.id || link.target;
            return sourceId === node.id || targetId === node.id;
          }).length;

          html += `<div class="node-info-section">
            <div class="node-info-section-title">Connections</div>
            <div class="node-info-meta">
              <span class="node-info-meta-key">Links:</span>
              <span class="node-info-meta-value">${connections}</span>
            </div>
          </div>`;

          content.innerHTML = html;
          panel.classList.add('visible');
        }

        // Close node info
        function closeNodeInfo() {
          document.getElementById('node-info').classList.remove('visible');
        }

        // Update physics
        function updatePhysics() {
          const charge = -parseInt(document.getElementById('charge').value);
          const distance = parseInt(document.getElementById('distance').value);

          document.getElementById('charge-value').textContent = Math.abs(charge);
          document.getElementById('distance-value').textContent = distance;

          if (simulation) {
            simulation.force('charge').strength(charge);
            simulation.force('link').distance(distance);
            simulation.alpha(0.3).restart();
          }
        }

        // Update node size
        function updateNodeSize() {
          const size = parseInt(document.getElementById('node-size').value);
          document.getElementById('node-size-value').textContent = size;

          g.selectAll('.node-circle').attr('r', size);
          g.selectAll('.node-label').attr('dy', size + 12);
        }

        // Update filters
        function updateFilters() {
          const activeTypes = Array.from(document.querySelectorAll('.checkbox:checked'))
            .map(cb => cb.dataset.type);

          // Filter nodes
          g.selectAll('.node-group').style('opacity', d => {
            return activeTypes.includes(d.type) ? 1 : 0.1;
          });

          // Filter links
          g.selectAll('.link').style('opacity', d => {
            const sourceType = d.source.type || 'other';
            const targetType = d.target.type || 'other';
            const visible = activeTypes.includes(sourceType) && activeTypes.includes(targetType);
            return visible ? 0.3 : 0.05;
          });
        }

        // Reset view
        function resetView() {
          svg.transition()
            .duration(750)
            .call(zoom.transform, d3.zoomIdentity);
        }

        // Toggle controls
        function toggleControls() {
          const controls = document.getElementById('controls');
          const toggle = document.getElementById('toggle-controls');

          if (controls.style.display === 'none') {
            controls.style.display = 'block';
            toggle.style.display = 'none';
          } else {
            controls.style.display = 'none';
            toggle.style.display = 'flex';
          }
        }

        // Update stats
        function updateStats() {
          if (!graphData) return;
          document.getElementById('node-count').textContent = graphData.nodes.length;
          document.getElementById('link-count').textContent = graphData.links.length;
        }

        // Initialize on load
        init();
      </script>
    </body>
    </html>
    """)
  end
end
