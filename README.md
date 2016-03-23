# philiprehberger-graph

[![Tests](https://github.com/philiprehberger/rb-graph/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-graph/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-graph.svg)](https://rubygems.org/gems/philiprehberger-graph)
[![License](https://img.shields.io/github/license/philiprehberger/rb-graph)](LICENSE)

Directed and undirected graph with traversal, shortest path, and topological sort.

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

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
