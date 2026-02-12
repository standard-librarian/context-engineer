# Graph Visualizations

This project includes two distinct graph visualization interfaces, each with its own aesthetic and interaction model. All visualizations use the same backend API (`/api/graph/export`) but present the data differently.

## Available Visualizations

### 1. Retro-Futuristic Terminal (`/graph`)
**Style**: 1970s/80s analog computing aesthetic  
**File**: `graph_controller.ex`

A warm, vintage-inspired visualization featuring:
- **Color Palette**: Amber phosphor (`#ffb000`), green CRT (`#33ff33`), aged paper cream
- **Typography**: Orbitron (geometric display), Courier Prime (vintage monospace), Share Tech Mono
- **Effects**: CRT scan lines, analog warmth, terminal boot sequence
- **Library**: D3.js force-directed layout

**Features**:
- Animated scan lines and CRT flicker effects
- Retro-styled control panel with bracketed UI elements
- Phosphor green indicators and amber glowing borders
- Technical documentation aesthetic

---

### 2. Obsidian-Style Force Graph (`/graph/obsidian`)
**Style**: High-performance force-directed graph inspired by Obsidian.md  
**File**: `graph_obsidian_controller.ex`

A professional knowledge graph visualization featuring:
- **Color Palette**: Dark background (`#1e1e1e`), purple accent (`#7c3aed`), subtle grays
- **Typography**: System fonts (-apple-system, BlinkMacSystemFont, Segoe UI)
- **Effects**: Smooth node glow, collision detection, physics-based layout
- **Library**: react-force-graph-2d with WebGL renderer

**Features**:
- **High Performance**: WebGL-based rendering for hundreds of nodes at 60fps
- **Physics Controls**: 
  - Adjustable repulsion force (node separation)
  - Configurable link distance
  - Collision radius (prevents node overlap)
  - Center gravity (keeps graph centered)
- **Visual Controls**:
  - Toggle node labels on/off
  - Toggle directional arrows
  - Show/hide labels based on zoom level
- **Interactions**:
  - Click and drag to pan
  - Scroll to zoom
  - Drag nodes to reposition (physics adjusts)
  - Hover to highlight node and connections
  - Click node to center and zoom
  - Reset view button
- **Smart Highlighting**: 
  - Hover over node to highlight it and all connected nodes/edges
  - Dimmed non-connected nodes for focus
  - Glow effects on hovered nodes
- **Real-time Stats**: 
  - Node count
  - Edge count
  - FPS counter
- **Aesthetic**:
  - Small, clean circles for nodes
  - Thin, subtle lines for edges (fade when not highlighted)
  - Type-based color coding (ADRs purple, Failures red, Meetings blue, etc.)
  - Labels appear on zoom or when highlighted

**Why Obsidian-style?**
This visualization replicates the popular "floating nodes" aesthetic from Obsidian.md, using force-directed physics to create an organic, intuitive layout. It's optimized for exploring knowledge graphs and understanding relationships between concepts.

---

## Common Features

Both visualizations share these capabilities:

### Navigation
- **Pan**: Click and drag background
- **Zoom**: Scroll wheel
- **Reset**: Button to reset camera position

### Interaction
- **Node Selection**: Click nodes to view details or center on them
- **Node Dragging**: Drag nodes to reposition (force simulation adjusts)
- **Hover Effects**: Nodes enlarge and glow on hover

### Data Loading
- **Max Nodes**: Configurable limits (default: 500 for Obsidian)
- **Type Support**: ADRs, Failures, Meetings, Contexts
- **Real-time Data**: Fetches from `/api/graph/export`

---

## API Endpoints

### Visualization Routes
```
GET /graph              - Retro-futuristic terminal style
GET /graph/obsidian     - Obsidian-style force graph (recommended)
```

### Data API
```
GET /api/graph/export?max_nodes=500
    - Returns graph data in standard format:
    {
      "nodes": [{ "id": "...", "type": "...", "label": "...", "name": "..." }],
      "links": [{ "source": "...", "target": "..." }]
    }

GET /api/graph/related/:id?type=adr&depth=2
    - Returns related nodes for a specific item
```

---

## Design Philosophy

Each visualization was designed with a specific aesthetic vision:

1. **Retro Terminal**: Nostalgic warmth, analog computing history, technical documentation feel
2. **Obsidian Graph**: Modern knowledge management, organic layouts, professional aesthetics optimized for understanding relationships

Choose the style that best fits your use case:
- **Terminal**: Great for technical presentations, retro-themed dashboards, terminal enthusiasts
- **Obsidian**: Perfect for knowledge exploration, understanding complex relationships, professional presentations

---

## Technology Stack

### Retro Terminal
- **D3.js v7**: Force-directed graph layout and SVG manipulation
- **Pure CSS**: Custom styling with retro effects
- **Google Fonts**: Distinctive typography

### Obsidian Graph
- **react-force-graph-2d**: High-performance WebGL force-directed layout
- **React 18**: Component-based UI
- **D3-force v3**: Physics simulation engine
- **HTML5 Canvas**: Efficient rendering

### Backend
- **Phoenix/Elixir**: Backend API serving graph data
- **Ecto**: Graph relationship queries

---

## Performance Comparison

| Feature | Retro Terminal | Obsidian Graph |
|---------|---------------|----------------|
| Rendering | SVG | Canvas (WebGL) |
| Recommended Max Nodes | 300 | 500+ |
| FPS Target | 60fps | 60fps |
| Mobile Support | Good | Excellent |
| Physics Customization | Limited | Extensive |
| Load Time | Fast | Fast |

---

## Customization

### Retro Terminal
Located in `graph_controller.ex`, modify:
1. **Colors**: Update CSS variables in `<style>` section
2. **Physics**: Change D3 force simulation parameters
3. **Typography**: Swap Google Font imports

### Obsidian Graph
Located in `graph_obsidian_controller.ex`, modify:
1. **Colors**: Update `TYPE_COLORS` object and CSS variables
2. **Physics**: Adjust default slider values in state initialization
3. **Node Rendering**: Customize `paintNode()` method
4. **Link Rendering**: Customize `paintLink()` method
5. **Controls**: Add/remove control sliders in the controls panel

---

## Physics Parameters (Obsidian Graph)

Understanding the physics controls:

- **Repulsion Force** (-1000 to -50): How strongly nodes push away from each other. More negative = more spread out.
- **Link Distance** (20-200): Ideal distance between connected nodes. Higher = more spacing.
- **Collision Radius** (5-30): Minimum distance between nodes. Prevents overlap.
- **Center Gravity** (0-1): How strongly nodes are pulled toward the center. 0 = no centering, 1 = strong centering.

Recommended settings:
- **Dense graphs**: Lower repulsion (-200), smaller link distance (40)
- **Sparse graphs**: Higher repulsion (-500), larger link distance (80)
- **Prevent overlap**: Increase collision radius to 15-20

---

## Browser Support

Tested and working on:
- Chrome/Edge (latest) - **Recommended**
- Firefox (latest)
- Safari (latest)

**Obsidian Graph** requires:
- ES6 module support
- Canvas API
- Import maps
- Modern JavaScript (async/await, classes)

---

## Migration from Variants

Previous variant controllers (`graph_variant1-5_controller.ex`) have been removed in favor of the unified Obsidian-style graph. If you were using a specific variant, the Obsidian graph provides:

- All physics controls from variants
- Better performance with WebGL rendering
- More intuitive interactions
- Professional aesthetic matching modern tools
- Extensive customization through the controls panel

The retro terminal style is preserved for those who prefer the vintage aesthetic.