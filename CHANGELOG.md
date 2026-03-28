# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-03-28

### Added

- Minimum spanning tree with Kruskal's and Prim's algorithms (`minimum_spanning_tree`)
- Maximum flow using Edmonds-Karp algorithm (`max_flow`)
- Greedy graph coloring (`coloring`, `chromatic_number_estimate`)
- Bipartiteness checking (`bipartite?`, `bipartite_sets`)
- Strongly connected components via Tarjan's algorithm (`strongly_connected_components`)
- Graph serialization to DOT and JSON formats (`to_dot`, `to_json`, `Graph.from_json`)

## [0.1.5] - 2026-03-26

### Changed

- Add Sponsor badge and fix License link format in README

## [0.1.4] - 2026-03-24

### Changed
- Expand test coverage to 55+ examples covering edge cases and error paths

## [0.1.3] - 2026-03-24

### Fixed
- Fix README one-liner to remove trailing period

## [0.1.2] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.1.1] - 2026-03-22

### Changed
- Update rubocop configuration for Windows compatibility

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Directed and undirected graph with adjacency list storage
- Add and remove nodes and weighted edges
- Breadth-first search (BFS) and depth-first search (DFS)
- Dijkstra's shortest path algorithm
- Topological sort for directed acyclic graphs
- Cycle detection for both directed and undirected graphs
- Connected component discovery
