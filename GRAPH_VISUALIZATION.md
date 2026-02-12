# Graph Visualization Guide

## Overview

Context Engineering includes a built-in interactive graph visualization powered by **Cytoscape.js**, a battle-tested graph visualization library used in biological research, drug discovery, and network analysis. The visualization shows how your organizational knowledge is connected - ADRs, Failures, Meetings, and Snapshots reference each other, forming a knowledge graph that helps you understand relationships and dependencies.

### Why Cytoscape.js?

- **Battle-tested**: Used by major research institutions and pharmaceutical companies
- **Performance**: Handles thousands of nodes efficiently
- **Layouts**: Multiple algorithms (force-directed, circular, grid, hierarchical)
- **Extensible**: Rich ecosystem of plugins and extensions
- **Well-documented**: Extensive API documentation and examples
- **Active development**: Regular updates and community support

## Quick Start

### Web Visualization

The easiest way to visualize your knowledge graph:

```bash
# Start the server
mix phx.server

# Open browser to:
http://localhost:4000/graph
```

Or use the Mix task to auto-open:

```bash
mix context.graph --web
```

### Command-Line View

Get graph statistics without starting the web server:

```bash
mix context.graph
```

Output:
```
Knowledge Graph Statistics:
---------------------------
Total Nodes: 42
  - ADRs: 15
  - Failures: 18
  - Meetings: 7
  - Snapshots: 2

Total Edges: 67

Relationship Types:
  - references: 67

Most Referenced Items:
  - ADR-001: Use PostgreSQL (12 references)
  - FAIL-023: DB timeout (8 references)
```

## Understanding the Graph

### Node Types

Each knowledge item is a node in the graph:

- **ADR (Blue, Box)** - Architecture Decision Records
  - Size increases with reference count
  - Shows which decisions are most influential
  
- **Failure (Red, Diamond)** - Incident/Outage records
  - Highlights what went wrong
  - Links to related ADRs and meetings
  
- **Meeting (Green, Ellipse)** - Meeting notes and decisions
  - Connects discussions to actions
  - References ADRs and failures discussed
  
- **Snapshot (Orange, Triangle)** - Git commit snapshots
  - Shows code state at specific points
  - Links to relevant decisions

### Edges (Relationships)

Edges represent references between items:

- **"references"** - One item explicitly mentions another
  - Example: FAIL-023 mentions "see ADR-001"
  - Auto-detected from content (ADR-\d+, FAIL-\d+, etc.)
  - Strength indicates relevance (default: 1.0)

### How Relationships Form

When you create content with IDs like:

```
This failure occurred because we didn't follow ADR-001.
See also FAIL-023 and MEET-005 for context.
```

The system automatically creates edges:
- Current item -> ADR-001
- Current item -> FAIL-023
- Current item -> MEET-005

## Using the Web Interface

### Controls

Located at the top of the visualization:

- **Include Archived Items** - Show/hide archived nodes
- **Max Nodes** - Limit displayed nodes (10-5000)
- **Refresh Graph** - Reload with current settings
- **Fit to Screen** - Reset zoom and center view

### Layout Options

Choose different layout algorithms from the dropdown:

- **Force-Directed (CoSE)** - Physics-based simulation (default)
- **Circle** - Nodes arranged in a circle
- **Grid** - Nodes in a regular grid
- **Concentric** - Circular rings by reference count

### Interactions

- **Click node** - View details in info panel (bottom-right)
- **Drag node** - Reposition manually (temporary)
- **Scroll** - Zoom in/out
- **Drag background** - Pan around
- **Hover node** - Highlight with thicker border
- **Click background** - Deselect and hide info panel

### Legend

Color key shown in top-right corner:
- Blue = ADR
- Red = Failure
- Green = Meeting
- Orange = Snapshot

## Exporting Graph Data

### JSON Export

Export the entire graph as JSON:

```bash
mix context.graph --export graph.json
```

Include archived items:

```bash
mix context.graph --export graph.json --include-archived
```

Limit node count:

```bash
mix context.graph --export graph.json --max-nodes 500
```

### JSON Format

```json
{
  "nodes": [
    {
      "id": "ADR-001",
      "type": "adr",
      "title": "Use PostgreSQL for persistence",
      "status": "active",
      "tags": ["database", "postgresql"],
      "created_date": "2024-01-15",
      "reference_count": 12
    },
    {
      "id": "FAIL-023",
      "type": "failure",
      "title": "Database connection timeout",
      "severity": "high",
      "status": "resolved",
      "tags": ["database", "performance"],
      "created_date": "2024-02-01",
      "reference_count": 8
    }
  ],
  "edges": [
    {
      "from": "FAIL-023",
      "from_type": "failure",
      "to": "ADR-001",
      "to_type": "adr",
      "type": "references",
      "strength": 1.0
    }
  ]
}
```

## API Endpoints

### Get Full Graph

```bash
curl http://localhost:4000/api/graph/export
```

With query parameters:

```bash
curl "http://localhost:4000/api/graph/export?max_nodes=100&include_archived=false"
```

Response: JSON with `nodes` and `edges` arrays

### Get Related Items

Find items connected to a specific node:

```bash
curl http://localhost:4000/api/graph/related/ADR-001?depth=2
```

Parameters:
- `depth` - How many hops to traverse (default: 2)
- Returns all items within N relationships

Response:
```json
{
  "item_id": "ADR-001",
  "related": [
    {
      "id": "FAIL-023",
      "type": "failure",
      "relationship": "references",
      "strength": 1.0
    }
  ]
}
```

## Use Cases

### 1. Impact Analysis

**Question:** "If I change this ADR, what might break?"

```bash
curl http://localhost:4000/api/graph/related/ADR-001?depth=3
```

Shows all failures, meetings, and snapshots that reference this decision.

### 2. Root Cause Investigation

**Question:** "Why do we keep having this failure?"

Open the graph visualization and click on a failure node. Follow edges to see:
- Related ADRs (was this anticipated?)
- Related failures (is this a pattern?)
- Related meetings (was this discussed?)

### 3. Decision Archaeology

**Question:** "Why did we make this decision?"

Click an ADR in the graph to see:
- What failures led to this decision
- Which meetings discussed it
- What snapshots show the implementation

### 4. Knowledge Gaps

**Question:** "What's not connected?"

Look for isolated nodes (no edges):
- ADRs with no failures = untested decisions
- Failures with no ADRs = undocumented incidents
- Meetings with no outcomes = unactionable discussions

### 5. Over-Referenced Items

**Question:** "What are our most important decisions?"

Look at node size - larger nodes have more references:
- These are your architectural keystones
- Changes here have wide impact
- Should be well-documented and tested

## Advanced: External Visualization

The exported JSON works with many battle-tested graph visualization tools:

### Alternative Visualization Libraries

If you want to customize the visualization, consider these proven alternatives:

**1. Cytoscape.js** (current implementation)
- Website: https://js.cytoscape.org/
- Use case: Network graphs, biological pathways, social networks
- Pros: Most flexible, excellent documentation, multiple layouts
- Best for: Production applications requiring customization

**2. Sigma.js**
- Website: https://www.sigmajs.org/
- Use case: Large graphs (10K+ nodes)
- Pros: WebGL rendering, excellent performance
- Best for: Very large knowledge bases

**3. Apache ECharts**
- Website: https://echarts.apache.org/
- Use case: Data visualization with graph components
- Pros: Charts + graphs in one library, huge community
- Best for: Dashboards combining graphs and charts

**4. vis.js (Network)**
- Website: https://visjs.org/
- Use case: Interactive networks and timelines
- Pros: Easy to use, good physics simulation
- Best for: Quick prototypes

### Standalone Tools

**Gephi** (Desktop Application)
- Download: https://gephi.org/
- Industry standard for graph analysis
- Steps:
  1. Export graph: `mix context.graph --export graph.json`
  2. Convert to GEXF format or use JSON import plugin
  3. Apply layout algorithms (ForceAtlas2 recommended)
  4. Analyze metrics (betweenness, clustering, PageRank)
  5. Export high-resolution images

**Neo4j** (Graph Database)
- Download: https://neo4j.com/
- Import the graph for Cypher queries:

```cypher
// Example: Find all failures related to database decisions
MATCH (f:Failure)-[:REFERENCES]->(a:ADR)
WHERE a.tags CONTAINS 'database'
RETURN f, a

// Find shortest path between two items
MATCH path = shortestPath(
  (start {id: 'ADR-001'})-[*]-(end {id: 'FAIL-023'})
)
RETURN path
```

**Graphviz** (Command-line)
- Website: https://graphviz.org/
- Convert to DOT format:

```bash
# Export graph
mix context.graph --export graph.json
# Convert JSON to DOT (custom script needed)
# Render with Graphviz
dot -Tpng graph.dot -o graph.png
neato -Tsvg graph.dot -o graph.svg
```

### Custom D3.js Visualization

Use the JSON directly in custom D3.js visualizations:

```javascript
fetch('/api/graph/export')
  .then(r => r.json())
  .then(data => {
    // data.nodes and data.edges are ready for D3
    const simulation = d3.forceSimulation(data.nodes)
      .force("link", d3.forceLink(data.edges).id(d => d.id))
      .force("charge", d3.forceManyBody().strength(-300))
      .force("center", d3.forceCenter(width / 2, height / 2));
    
    // Render nodes and edges
    // ... custom visualization code
  });
```

## Performance

### Large Graphs

For graphs with 1000+ nodes:

1. **Use max_nodes parameter**
   ```bash
   curl "http://localhost:4000/api/graph/export?max_nodes=500"
   ```

2. **Filter by type**
   Query specific node types via API
   
3. **Exclude archived**
   Reduces noise from old items
   
4. **Physics optimization**
   The web UI disables physics after initial layout

### Memory Usage

- Each node: ~1KB
- Each edge: ~200 bytes
- 1000 nodes + 2000 edges = ~2.4MB JSON

## Troubleshooting

### Graph is empty

Check if you have any data:

```bash
# Create some test data
mix context.adr --title "Test Decision" --decision "Test" --context "Test"
mix context.failure --title "Test Failure" --symptoms "Test" --root-cause "Test" --resolution "Test"
```

### Nodes don't connect

Ensure you reference IDs in content:

```
# In ADR context field:
"This supersedes ADR-001 and addresses FAIL-042"
```

The system auto-detects patterns like `ADR-\d+`, `FAIL-\d+`, etc.

### Visualization won't load

1. Check server is running: `curl http://localhost:4000/api/graph/export`
2. Check browser console for JavaScript errors
3. Try clearing browser cache
4. Verify vis.js CDN is accessible

### Mix task fails

If `mix context.graph` fails to start:

```bash
# Check database connection
mix ecto.migrate

# Verify app compiles
mix compile

# Check for errors
iex -S mix
```

## Best Practices

### 1. Consistent Referencing

Always use full IDs when referencing:
- Good: "see ADR-001"
- Bad: "see the postgres ADR"

### 2. Meaningful Relationships

Add context when referencing:
- "This failure was caused by incomplete implementation of ADR-001"
- "Meeting discussed alternatives mentioned in FAIL-023"

### 3. Regular Review

Use the graph to review your knowledge base:
- Weekly: Check for new isolated nodes
- Monthly: Identify over-referenced items needing updates
- Quarterly: Archive obsolete nodes

### 4. Tag Strategy

Use consistent tags to group related items:
- Technical: `database`, `api`, `frontend`, `auth`
- Domains: `billing`, `notifications`, `analytics`
- Status: `experimental`, `deprecated`, `critical`

### 5. Bidirectional Links

When appropriate, create bidirectional references:
- ADR-002: "This supersedes ADR-001"
- ADR-001: "Superseded by ADR-002"

This makes graph traversal more informative.

## Examples

### Example 1: Database Decision Chain

```
ADR-001: Use PostgreSQL
    ^
    |
FAIL-023: Connection pool exhausted
    ^
    |
MEET-005: Discussed scaling strategy
    ^
    |
ADR-015: Add connection pooling
    ^
    |
SNAP-042: Implemented connection pool
```

### Example 2: Authentication Evolution

```
ADR-003: Use JWT tokens
    ^
    |
FAIL-010: Token expiry issues
    |
    v
MEET-012: Security review
    |
    v
ADR-024: Add refresh tokens
    |
    v
FAIL-089: Refresh token leaked
    |
    v
ADR-031: Move to OAuth2
```

## Resources

- [Vis.js Documentation](https://visjs.org/)
- [Graph Theory Basics](https://en.wikipedia.org/wiki/Graph_theory)
- [Force-Directed Graphs](https://en.wikipedia.org/wiki/Force-directed_graph_drawing)

## Future Enhancements

Potential additions to graph visualization:

- [ ] Timeline view (nodes arranged by date)
- [ ] Clustering by tags
- [ ] Path finding (shortest path between two items)
- [ ] Subgraph extraction
- [ ] Impact analysis preview
- [ ] Change history visualization
- [ ] Export to various formats (PNG, SVG, PDF)
- [ ] Collaborative annotations
- [ ] Real-time updates (WebSocket)

---

**Remember:** The knowledge graph is a living representation of your organization's memory. Keep it updated, review it regularly, and use it to guide decisions.