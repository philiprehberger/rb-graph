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
| `#neighbors(node)` | Get neighbor node ids |
| `#degree(node)` | Number of edges on a node |
| `#nodes` | All node ids |
| `#edges` | All edges as hashes |
| `#bfs(start)` | Breadth-first search |
| `#dfs(start)` | Depth-first search |
| `#shortest_path(from, to)` | Dijkstra's shortest path |
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
