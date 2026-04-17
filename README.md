# philiprehberger-graph

[![Tests](https://github.com/philiprehberger/rb-graph/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-graph/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-graph.svg)](https://rubygems.org/gems/philiprehberger-graph)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-graph)](https://github.com/philiprehberger/rb-graph/commits/main)

Directed and undirected graph data structure with traversal, shortest path, MST, max flow, coloring, and serialization

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-graph"
```

Or install directly:

```bash
gem install philiprehberger-graph
```

## Usage

```ruby
require "philiprehberger/graph"

g = Philiprehberger::Graph.new(directed: true)
g.add_edge(:a, :b, weight: 4)
g.add_edge(:a, :c, weight: 2)
g.add_edge(:c, :b, weight: 1)

g.shortest_path(:a, :b)  # => [:a, :c, :b]
```

### Traversal

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b)
g.add_edge(:a, :c)
g.add_edge(:b, :d)

g.bfs(:a)  # => [:a, :b, :c, :d]
g.dfs(:a)  # => [:a, :b, :d, :c]
```

### Topological Sort

```ruby
g = Philiprehberger::Graph.new(directed: true)
g.add_edge(:build, :test)
g.add_edge(:test, :deploy)
g.topological_sort  # => [:build, :test, :deploy]
```

### Cycle Detection

```ruby
g = Philiprehberger::Graph.new(directed: true)
g.add_edge(:a, :b)
g.add_edge(:b, :a)
g.cycle?  # => true
```

### Connected Components

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b)
g.add_edge(:c, :d)
g.connected_components  # => [[:a, :b], [:c, :d]]
```

### Minimum Spanning Tree

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b, weight: 4)
g.add_edge(:a, :c, weight: 2)
g.add_edge(:b, :c, weight: 1)
g.add_edge(:b, :d, weight: 5)

g.minimum_spanning_tree(algorithm: :kruskal)
# => [{from: :b, to: :c, weight: 1}, {from: :a, to: :c, weight: 2}, {from: :b, to: :d, weight: 5}]
g.minimum_spanning_tree(algorithm: :prim)
```

### Maximum Flow

```ruby
g = Philiprehberger::Graph.new(directed: true)
g.add_edge(:s, :a, weight: 10)
g.add_edge(:s, :b, weight: 5)
g.add_edge(:a, :t, weight: 5)
g.add_edge(:b, :t, weight: 10)
g.add_edge(:a, :b, weight: 15)

g.max_flow(:s, :t)  # => 15
```

### Graph Coloring

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b)
g.add_edge(:b, :c)
g.add_edge(:c, :a)

g.coloring                  # => {:a=>0, :b=>1, :c=>2}
g.chromatic_number_estimate # => 3
```

### Bipartiteness

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b)
g.add_edge(:b, :c)

g.bipartite?      # => true
g.bipartite_sets  # => [#<Set: {:a, :c}>, #<Set: {:b}>]
```

### Strongly Connected Components

```ruby
g = Philiprehberger::Graph.new(directed: true)
g.add_edge(:a, :b)
g.add_edge(:b, :a)
g.add_edge(:b, :c)
g.add_edge(:c, :d)
g.add_edge(:d, :c)

g.strongly_connected_components  # => [[:d, :c], [:b, :a]]
```

### Iteration

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b)
g.add_edge(:a, :c)

g.each_node { |id| puts id }
g.each_edge { |e| puts "#{e[:from]} -> #{e[:to]}" }

# Enumerator chaining
high_degree = g.each_node.select { |id| g.degree(id) > 1 }
heavy_edges = g.each_edge.select { |e| e[:weight] > 5 }
```

### Shortest Path Distance

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b, weight: 1)
g.add_edge(:b, :c, weight: 2)
g.add_edge(:a, :c, weight: 10)

g.shortest_path_distance(:a, :c)  # => 3
```

### Graph Complement

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b)
g.add_edge(:b, :c)

c = g.complement
c.edge?(:a, :c)  # => true
c.edge?(:a, :b)  # => false
```

### Query Methods

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b, weight: 3)
g.add_edge(:b, :c)
g.add_node(:d)

g.node?(:a)       # => true
g.edge?(:a, :b)   # => true
g.weight(:a, :b)  # => 3
g.node_count       # => 4
g.edge_count       # => 2
g.empty?           # => false
g.path?(:a, :c)   # => true
g.path?(:a, :d)   # => false
g.density          # => 0.333...
```

### Directed Degree

```ruby
g = Philiprehberger::Graph.new(directed: true)
g.add_edge(:a, :b)
g.add_edge(:a, :c)
g.add_edge(:b, :c)

g.in_degree(:c)   # => 2
g.out_degree(:a)  # => 2
```

### Subgraph

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b)
g.add_edge(:b, :c)
g.add_edge(:c, :d)

sg = g.subgraph([:a, :b, :c])
sg.nodes  # => [:a, :b, :c]
sg.edge?(:a, :b)  # => true
sg.node?(:d)      # => false
```

### Transpose

```ruby
g = Philiprehberger::Graph.new(directed: true)
g.add_edge(:a, :b)
g.add_edge(:b, :c)

t = g.transpose
t.edge?(:b, :a)  # => true
t.edge?(:c, :b)  # => true
```

### Serialization

```ruby
g = Philiprehberger::Graph.new
g.add_edge(:a, :b, weight: 3)

g.to_dot
# => "graph G {\n  a;\n  b;\n  a -- b [weight=3];\n}"

g.to_json
# => '{"directed":false,"nodes":["a","b"],"edges":[{"from":"a","to":"b","weight":3}]}'

g2 = Philiprehberger::Graph::Graph.from_json(g.to_json)
```

## API

| Method | Description |
|--------|-------------|
| `.new(directed:)` | Create a new graph |
| `#add_node(id)` | Add a node |
| `#add_edge(from, to, weight:)` | Add a weighted edge |
| `#remove_node(id)` | Remove a node and its edges |
| `#remove_edge(from, to)` | Remove an edge |
| `#node?(id)` | Check if a node exists |
| `#edge?(from, to)` | Check if an edge exists |
| `#weight(from, to)` | Get edge weight (nil if none) |
| `#neighbors(node)` | Get neighbor node ids |
| `#degree(node)` | Number of edges on a node |
| `#in_degree(node)` | Incoming edges (directed) |
| `#out_degree(node)` | Outgoing edges (directed) |
| `#nodes` | All node ids |
| `#edges` | All edges as hashes |
| `#node_count` | Number of nodes |
| `#edge_count` | Number of edges |
| `#empty?` | Whether the graph has no nodes |
| `#each_node` | Iterate nodes (yields or returns Enumerator) |
| `#each_edge` | Iterate edges (yields or returns Enumerator) |
| `#path?(from, to)` | Check if a path exists |
| `#bfs(start)` | Breadth-first search |
| `#dfs(start)` | Depth-first search |
| `#shortest_path(from, to)` | Dijkstra's shortest path |
| `#shortest_path_distance(from, to)` | Shortest distance (numeric) |
| `#topological_sort` | Topological ordering (DAG only) |
| `#cycle?` | Check for cycles |
| `#connected_components` | Find connected components |
| `#minimum_spanning_tree(algorithm:)` | Kruskal's or Prim's MST |
| `#max_flow(source, sink)` | Edmonds-Karp maximum flow |
| `#coloring` | Greedy graph coloring |
| `#chromatic_number_estimate` | Estimated chromatic number |
| `#bipartite?` | Check if graph is bipartite |
| `#bipartite_sets` | Get bipartite partition sets |
| `#strongly_connected_components` | Tarjan's SCC algorithm |
| `#subgraph(nodes)` | Extract a subgraph |
| `#transpose` | Reverse all edges (directed) |
| `#density` | Graph density (0.0 to 1.0) |
| `#complement` | Graph complement (missing edges) |
| `#to_dot` | Serialize to DOT format |
| `#to_json` | Serialize to JSON |
| `.from_json(str)` | Deserialize from JSON |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-graph)

🐛 [Report issues](https://github.com/philiprehberger/rb-graph/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-graph/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
