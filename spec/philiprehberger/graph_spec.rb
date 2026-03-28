# frozen_string_literal: true

require 'json'
require 'spec_helper'

RSpec.describe Philiprehberger::Graph do
  describe 'VERSION' do
    it 'has a version number' do
      expect(Philiprehberger::Graph::VERSION).not_to be_nil
    end
  end

  describe '.new' do
    it 'creates an undirected graph by default' do
      g = described_class.new
      expect(g.directed?).to be false
    end

    it 'creates a directed graph when specified' do
      g = described_class.new(directed: true)
      expect(g.directed?).to be true
    end
  end

  describe '#add_node' do
    it 'adds a node to the graph' do
      g = described_class.new
      g.add_node(:a)
      expect(g.nodes).to include(:a)
    end

    it 'is idempotent' do
      g = described_class.new
      g.add_node(:a)
      g.add_node(:a)
      expect(g.nodes.count(:a)).to eq(1)
    end
  end

  describe '#add_edge' do
    it 'adds an edge between two nodes' do
      g = described_class.new
      g.add_edge(:a, :b)
      expect(g.neighbors(:a)).to include(:b)
    end

    it 'creates both directions for undirected graph' do
      g = described_class.new
      g.add_edge(:a, :b)
      expect(g.neighbors(:b)).to include(:a)
    end

    it 'creates only forward direction for directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      expect(g.neighbors(:a)).to include(:b)
      expect(g.neighbors(:b)).not_to include(:a)
    end

    it 'auto-creates nodes' do
      g = described_class.new
      g.add_edge(:x, :y)
      expect(g.nodes).to include(:x, :y)
    end

    it 'accepts a weight' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 5)
      edges = g.edges
      expect(edges.first[:weight]).to eq(5)
    end
  end

  describe '#remove_node' do
    it 'removes a node and its edges' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.remove_node(:b)
      expect(g.nodes).not_to include(:b)
      expect(g.neighbors(:a)).not_to include(:b)
    end
  end

  describe '#remove_edge' do
    it 'removes an edge' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.remove_edge(:a, :b)
      expect(g.neighbors(:a)).not_to include(:b)
    end

    it 'removes both directions for undirected graph' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.remove_edge(:a, :b)
      expect(g.neighbors(:b)).not_to include(:a)
    end
  end

  describe '#neighbors' do
    it 'returns neighbor node ids' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:a, :c)
      expect(g.neighbors(:a)).to contain_exactly(:b, :c)
    end

    it 'returns empty array for isolated node' do
      g = described_class.new
      g.add_node(:x)
      expect(g.neighbors(:x)).to eq([])
    end

    it 'returns empty array for unknown node' do
      g = described_class.new
      expect(g.neighbors(:missing)).to eq([])
    end
  end

  describe '#degree' do
    it 'returns the number of edges' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:a, :c)
      expect(g.degree(:a)).to eq(2)
    end

    it 'returns zero for isolated node' do
      g = described_class.new
      g.add_node(:x)
      expect(g.degree(:x)).to eq(0)
    end
  end

  describe '#nodes' do
    it 'returns all node ids' do
      g = described_class.new
      g.add_node(:a)
      g.add_node(:b)
      expect(g.nodes).to contain_exactly(:a, :b)
    end
  end

  describe '#edges' do
    it 'returns all edges' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 2)
      g.add_edge(:b, :c, weight: 3)
      expect(g.edges.length).to eq(2)
    end

    it 'does not duplicate undirected edges' do
      g = described_class.new
      g.add_edge(:a, :b)
      expect(g.edges.length).to eq(1)
    end
  end

  describe '#bfs' do
    it 'traverses in breadth-first order' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:a, :c)
      g.add_edge(:b, :d)
      result = g.bfs(:a)
      expect(result.first).to eq(:a)
      expect(result).to contain_exactly(:a, :b, :c, :d)
      # b and c should come before d
      expect(result.index(:d)).to be > [result.index(:b), result.index(:c)].max
    end

    it 'returns empty array for unknown node' do
      g = described_class.new
      expect(g.bfs(:missing)).to eq([])
    end
  end

  describe '#dfs' do
    it 'traverses in depth-first order' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:a, :c)
      g.add_edge(:b, :d)
      result = g.dfs(:a)
      expect(result.first).to eq(:a)
      expect(result).to contain_exactly(:a, :b, :c, :d)
    end

    it 'returns empty array for unknown node' do
      g = described_class.new
      expect(g.dfs(:missing)).to eq([])
    end
  end

  describe '#shortest_path' do
    it 'finds the shortest path' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 1)
      g.add_edge(:b, :c, weight: 1)
      g.add_edge(:a, :c, weight: 10)
      path = g.shortest_path(:a, :c)
      expect(path).to eq(%i[a b c])
    end

    it 'returns single-node path for same source and destination' do
      g = described_class.new
      g.add_node(:a)
      expect(g.shortest_path(:a, :a)).to eq([:a])
    end

    it 'returns nil when no path exists' do
      g = described_class.new(directed: true)
      g.add_node(:a)
      g.add_node(:b)
      expect(g.shortest_path(:a, :b)).to be_nil
    end

    it 'returns nil for unknown nodes' do
      g = described_class.new
      expect(g.shortest_path(:a, :b)).to be_nil
    end

    it 'works with weighted directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b, weight: 4)
      g.add_edge(:a, :c, weight: 2)
      g.add_edge(:c, :b, weight: 1)
      path = g.shortest_path(:a, :b)
      expect(path).to eq(%i[a c b])
    end
  end

  describe '#topological_sort' do
    it 'returns nodes in topological order' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:a, :c)
      g.add_edge(:b, :d)
      g.add_edge(:c, :d)
      result = g.topological_sort
      expect(result.index(:a)).to be < result.index(:b)
      expect(result.index(:a)).to be < result.index(:c)
      expect(result.index(:b)).to be < result.index(:d)
      expect(result.index(:c)).to be < result.index(:d)
    end

    it 'raises for undirected graph' do
      g = described_class.new
      expect { g.topological_sort }.to raise_error(Philiprehberger::Graph::Error)
    end

    it 'raises for cyclic graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :a)
      expect { g.topological_sort }.to raise_error(Philiprehberger::Graph::Error)
    end
  end

  describe '#cycle?' do
    it 'detects cycle in directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :a)
      expect(g.cycle?).to be true
    end

    it 'returns false for acyclic directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      expect(g.cycle?).to be false
    end

    it 'detects cycle in undirected graph' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :a)
      expect(g.cycle?).to be true
    end

    it 'returns false for acyclic undirected graph (tree)' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      expect(g.cycle?).to be false
    end
  end

  describe '#connected_components' do
    it 'finds connected components in undirected graph' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:c, :d)
      components = g.connected_components
      expect(components.length).to eq(2)
    end

    it 'returns single component for fully connected graph' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      components = g.connected_components
      expect(components.length).to eq(1)
      expect(components.first).to contain_exactly(:a, :b, :c)
    end

    it 'treats isolated nodes as their own component' do
      g = described_class.new
      g.add_node(:a)
      g.add_node(:b)
      components = g.connected_components
      expect(components.length).to eq(2)
    end

    it 'finds weakly connected components in directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:c, :d)
      components = g.connected_components
      expect(components.length).to eq(2)
    end
  end

  # ── Additional edge-case and coverage tests ──

  describe 'empty graph' do
    it 'has no nodes' do
      g = described_class.new
      expect(g.nodes).to eq([])
    end

    it 'has no edges' do
      g = described_class.new
      expect(g.edges).to eq([])
    end

    it 'returns empty BFS for empty graph' do
      g = described_class.new
      expect(g.bfs(:a)).to eq([])
    end

    it 'returns empty DFS for empty graph' do
      g = described_class.new
      expect(g.dfs(:a)).to eq([])
    end

    it 'has no connected components' do
      g = described_class.new
      expect(g.connected_components).to eq([])
    end

    it 'has no cycle' do
      g = described_class.new
      expect(g.cycle?).to be false
    end

    it 'has no cycle in directed empty graph' do
      g = described_class.new(directed: true)
      expect(g.cycle?).to be false
    end
  end

  describe 'self-loops' do
    it 'allows adding a self-loop' do
      g = described_class.new
      g.add_edge(:a, :a)
      expect(g.neighbors(:a)).to include(:a)
    end

    it 'detects self-loop as cycle in undirected graph' do
      g = described_class.new
      g.add_edge(:a, :a)
      expect(g.cycle?).to be true
    end

    it 'detects self-loop as cycle in directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :a)
      expect(g.cycle?).to be true
    end

    it 'counts self-loop degree in directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :a)
      expect(g.degree(:a)).to eq(1)
    end
  end

  describe 'method chaining' do
    it 'returns self from add_node' do
      g = described_class.new
      expect(g.add_node(:a)).to be(g)
    end

    it 'returns self from add_edge' do
      g = described_class.new
      expect(g.add_edge(:a, :b)).to be(g)
    end

    it 'returns self from remove_node' do
      g = described_class.new
      g.add_node(:a)
      expect(g.remove_node(:a)).to be(g)
    end

    it 'returns self from remove_edge' do
      g = described_class.new
      g.add_edge(:a, :b)
      expect(g.remove_edge(:a, :b)).to be(g)
    end

    it 'supports chaining multiple operations' do
      g = described_class.new
      g.add_node(:a).add_node(:b).add_edge(:a, :b)
      expect(g.neighbors(:a)).to include(:b)
    end
  end

  describe 'removal edge cases' do
    it 'handles remove_node on non-existent node without error' do
      g = described_class.new
      g.add_node(:a)
      expect { g.remove_node(:missing) }.not_to raise_error
      expect(g.nodes).to contain_exactly(:a)
    end

    it 'handles remove_edge on non-existent edge without error' do
      g = described_class.new
      g.add_node(:a)
      g.add_node(:b)
      expect { g.remove_edge(:a, :b) }.not_to raise_error
    end

    it 'handles remove_edge on non-existent nodes without error' do
      g = described_class.new
      expect { g.remove_edge(:x, :y) }.not_to raise_error
    end

    it 'removes only the forward edge in directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :a)
      g.remove_edge(:a, :b)
      expect(g.neighbors(:a)).not_to include(:b)
      expect(g.neighbors(:b)).to include(:a)
    end

    it 'preserves other edges when removing a node' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :d)
      g.remove_node(:b)
      expect(g.neighbors(:c)).to include(:d)
      expect(g.neighbors(:c)).not_to include(:b)
    end
  end

  describe '#degree edge cases' do
    it 'returns zero for unknown node' do
      g = described_class.new
      expect(g.degree(:nonexistent)).to eq(0)
    end
  end

  describe '#edges in directed graph' do
    it 'lists both directions as separate edges' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :a)
      expect(g.edges.length).to eq(2)
    end

    it 'preserves weight on directed edges' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b, weight: 3)
      g.add_edge(:b, :a, weight: 7)
      weights = g.edges.map { |e| e[:weight] }.sort
      expect(weights).to eq([3, 7])
    end
  end

  describe 'BFS on disconnected graph' do
    it 'only visits the connected component of the start node' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:c, :d)
      result = g.bfs(:a)
      expect(result).to contain_exactly(:a, :b)
      expect(result).not_to include(:c, :d)
    end
  end

  describe 'DFS on disconnected graph' do
    it 'only visits the connected component of the start node' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:c, :d)
      result = g.dfs(:a)
      expect(result).to contain_exactly(:a, :b)
      expect(result).not_to include(:c, :d)
    end
  end

  describe 'shortest_path edge cases' do
    it 'returns nil when source exists but destination does not' do
      g = described_class.new
      g.add_node(:a)
      expect(g.shortest_path(:a, :missing)).to be_nil
    end

    it 'finds shortest path in a linear chain' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 1)
      g.add_edge(:b, :c, weight: 1)
      g.add_edge(:c, :d, weight: 1)
      expect(g.shortest_path(:a, :d)).to eq(%i[a b c d])
    end

    it 'returns nil for disconnected nodes' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_node(:c)
      expect(g.shortest_path(:a, :c)).to be_nil
    end

    it 'prefers lower-weight path over fewer-hop path' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 10)
      g.add_edge(:a, :c, weight: 1)
      g.add_edge(:c, :d, weight: 1)
      g.add_edge(:d, :b, weight: 1)
      path = g.shortest_path(:a, :b)
      expect(path).to eq(%i[a c d b])
    end
  end

  describe 'topological_sort edge cases' do
    it 'returns a single node' do
      g = described_class.new(directed: true)
      g.add_node(:a)
      expect(g.topological_sort).to eq([:a])
    end

    it 'returns empty array for empty directed graph' do
      g = described_class.new(directed: true)
      expect(g.topological_sort).to eq([])
    end

    it 'handles a linear chain' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :d)
      result = g.topological_sort
      expect(result).to eq(%i[a b c d])
    end

    it 'raises for a longer cycle' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :a)
      expect { g.topological_sort }.to raise_error(Philiprehberger::Graph::Error, /cycle/)
    end
  end

  describe 'string node identifiers' do
    it 'works with string keys' do
      g = described_class.new
      g.add_edge('hello', 'world')
      expect(g.neighbors('hello')).to include('world')
      expect(g.bfs('hello')).to contain_exactly('hello', 'world')
    end
  end

  describe 'connected_components in directed graph' do
    it 'groups weakly connected nodes via reverse edges' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      components = g.connected_components
      expect(components.length).to eq(1)
      expect(components.first).to contain_exactly(:a, :b, :c)
    end

    it 'separates truly disconnected directed components' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_node(:c)
      components = g.connected_components
      expect(components.length).to eq(2)
    end
  end

  describe '#cycle? edge cases' do
    it 'returns false for a single isolated node' do
      g = described_class.new
      g.add_node(:a)
      expect(g.cycle?).to be false
    end

    it 'returns false for a single directed node' do
      g = described_class.new(directed: true)
      g.add_node(:a)
      expect(g.cycle?).to be false
    end

    it 'detects cycle in larger directed graph with branch' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :d)
      g.add_edge(:d, :b)
      g.add_edge(:a, :e)
      expect(g.cycle?).to be true
    end

    it 'returns false after removing the edge that caused the cycle' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :a)
      expect(g.cycle?).to be true
      g.remove_edge(:c, :a)
      expect(g.cycle?).to be false
    end
  end

  describe 'integer node identifiers' do
    it 'supports integer keys for nodes and edges' do
      g = described_class.new
      g.add_edge(1, 2)
      g.add_edge(2, 3)
      expect(g.nodes).to contain_exactly(1, 2, 3)
      expect(g.neighbors(1)).to eq([2])
    end

    it 'finds shortest path with integer keys' do
      g = described_class.new
      g.add_edge(1, 2, weight: 1)
      g.add_edge(2, 3, weight: 1)
      g.add_edge(1, 3, weight: 10)
      expect(g.shortest_path(1, 3)).to eq([1, 2, 3])
    end
  end

  describe 'default edge weight' do
    it 'uses weight 1 when no weight is specified' do
      g = described_class.new
      g.add_edge(:a, :b)
      expect(g.edges.first[:weight]).to eq(1)
    end

    it 'uses weight 1 for directed edges by default' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      expect(g.edges.first[:weight]).to eq(1)
    end
  end

  describe 'BFS on directed graph' do
    it 'follows only outgoing edges' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:c, :a)
      result = g.bfs(:a)
      expect(result).to contain_exactly(:a, :b)
      expect(result).not_to include(:c)
    end

    it 'visits all reachable nodes in a diamond' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:a, :c)
      g.add_edge(:b, :d)
      g.add_edge(:c, :d)
      result = g.bfs(:a)
      expect(result.first).to eq(:a)
      expect(result).to contain_exactly(:a, :b, :c, :d)
      expect(result.index(:d)).to be > [result.index(:b), result.index(:c)].max
    end
  end

  describe 'DFS on directed graph' do
    it 'follows only outgoing edges' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:c, :a)
      result = g.dfs(:a)
      expect(result).to contain_exactly(:a, :b)
      expect(result).not_to include(:c)
    end

    it 'explores depth before breadth' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:a, :d)
      result = g.dfs(:a)
      # DFS from :a visits :b then :c (deep) before :d
      expect(result.index(:c)).to be < result.index(:d)
    end
  end

  describe 'self-loop edge cases' do
    it 'includes self-loop in edges list for undirected graph' do
      g = described_class.new
      g.add_edge(:a, :a)
      edges = g.edges
      expect(edges.length).to eq(1)
      expect(edges.first[:from]).to eq(:a)
      expect(edges.first[:to]).to eq(:a)
    end

    it 'can remove a self-loop' do
      g = described_class.new
      g.add_edge(:a, :a)
      g.remove_edge(:a, :a)
      expect(g.neighbors(:a)).not_to include(:a)
    end

    it 'counts self-loop degree as 2 in undirected graph' do
      g = described_class.new
      g.add_edge(:a, :a)
      # undirected self-loop stores both directions
      expect(g.degree(:a)).to eq(2)
    end

    it 'includes self-loop node in connected components' do
      g = described_class.new
      g.add_edge(:a, :a)
      g.add_node(:b)
      components = g.connected_components
      expect(components.length).to eq(2)
    end
  end

  describe 'topological_sort with disconnected components' do
    it 'includes all nodes from disconnected DAG' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:c, :d)
      result = g.topological_sort
      expect(result).to contain_exactly(:a, :b, :c, :d)
      expect(result.index(:a)).to be < result.index(:b)
      expect(result.index(:c)).to be < result.index(:d)
    end

    it 'handles isolated nodes in topological sort' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_node(:z)
      result = g.topological_sort
      expect(result).to contain_exactly(:a, :b, :z)
      expect(result.index(:a)).to be < result.index(:b)
    end
  end

  describe 'edges structure' do
    it 'returns correct from, to, and weight keys' do
      g = described_class.new(directed: true)
      g.add_edge(:x, :y, weight: 42)
      edge = g.edges.first
      expect(edge).to have_key(:from)
      expect(edge).to have_key(:to)
      expect(edge).to have_key(:weight)
      expect(edge[:from]).to eq(:x)
      expect(edge[:to]).to eq(:y)
      expect(edge[:weight]).to eq(42)
    end

    it 'returns empty edges for graph with only nodes' do
      g = described_class.new
      g.add_node(:a)
      g.add_node(:b)
      expect(g.edges).to eq([])
    end
  end

  describe 'remove_node from empty graph' do
    it 'handles remove_node on completely empty graph without error' do
      g = described_class.new
      expect { g.remove_node(:anything) }.not_to raise_error
      expect(g.nodes).to eq([])
    end
  end

  describe 'shortest_path with equal-weight alternatives' do
    it 'returns a valid shortest path when multiple exist' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 1)
      g.add_edge(:a, :c, weight: 1)
      g.add_edge(:b, :d, weight: 1)
      g.add_edge(:c, :d, weight: 1)
      path = g.shortest_path(:a, :d)
      expect(path.first).to eq(:a)
      expect(path.last).to eq(:d)
      expect(path.length).to eq(3)
    end
  end

  # ── Minimum Spanning Tree ──

  describe '#minimum_spanning_tree' do
    it 'raises for directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      expect { g.minimum_spanning_tree }.to raise_error(Philiprehberger::Graph::Error, /undirected/)
    end

    it 'raises for empty graph' do
      g = described_class.new
      expect { g.minimum_spanning_tree }.to raise_error(Philiprehberger::Graph::Error, /empty/)
    end

    it 'raises for disconnected graph' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:c, :d)
      expect { g.minimum_spanning_tree }.to raise_error(Philiprehberger::Graph::Error, /disconnected/)
    end

    it 'raises for unknown algorithm' do
      g = described_class.new
      g.add_edge(:a, :b)
      expect { g.minimum_spanning_tree(algorithm: :unknown) }.to raise_error(Philiprehberger::Graph::Error, /unknown/)
    end

    context 'with Kruskal' do
      it 'returns MST edges for a simple triangle' do
        g = described_class.new
        g.add_edge(:a, :b, weight: 1)
        g.add_edge(:b, :c, weight: 2)
        g.add_edge(:a, :c, weight: 3)
        mst = g.minimum_spanning_tree(algorithm: :kruskal)
        total_weight = mst.sum { |e| e[:weight] }
        expect(mst.length).to eq(2)
        expect(total_weight).to eq(3)
      end

      it 'returns MST for a larger graph' do
        g = described_class.new
        g.add_edge(:a, :b, weight: 4)
        g.add_edge(:a, :c, weight: 2)
        g.add_edge(:b, :c, weight: 1)
        g.add_edge(:b, :d, weight: 5)
        g.add_edge(:c, :d, weight: 8)
        mst = g.minimum_spanning_tree(algorithm: :kruskal)
        total_weight = mst.sum { |e| e[:weight] }
        expect(mst.length).to eq(3)
        expect(total_weight).to eq(8) # 1 + 2 + 5
      end

      it 'returns empty array for single-node graph' do
        g = described_class.new
        g.add_node(:a)
        mst = g.minimum_spanning_tree(algorithm: :kruskal)
        expect(mst).to eq([])
      end
    end

    context 'with Prim' do
      it 'returns MST edges for a simple triangle' do
        g = described_class.new
        g.add_edge(:a, :b, weight: 1)
        g.add_edge(:b, :c, weight: 2)
        g.add_edge(:a, :c, weight: 3)
        mst = g.minimum_spanning_tree(algorithm: :prim)
        total_weight = mst.sum { |e| e[:weight] }
        expect(mst.length).to eq(2)
        expect(total_weight).to eq(3)
      end

      it 'returns MST for a larger graph' do
        g = described_class.new
        g.add_edge(:a, :b, weight: 4)
        g.add_edge(:a, :c, weight: 2)
        g.add_edge(:b, :c, weight: 1)
        g.add_edge(:b, :d, weight: 5)
        g.add_edge(:c, :d, weight: 8)
        mst = g.minimum_spanning_tree(algorithm: :prim)
        total_weight = mst.sum { |e| e[:weight] }
        expect(mst.length).to eq(3)
        expect(total_weight).to eq(8)
      end

      it 'returns empty array for single-node graph' do
        g = described_class.new
        g.add_node(:a)
        mst = g.minimum_spanning_tree(algorithm: :prim)
        expect(mst).to eq([])
      end
    end

    it 'kruskal and prim produce same total weight' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 7)
      g.add_edge(:a, :d, weight: 5)
      g.add_edge(:b, :c, weight: 8)
      g.add_edge(:b, :d, weight: 9)
      g.add_edge(:b, :e, weight: 7)
      g.add_edge(:c, :e, weight: 5)
      g.add_edge(:d, :e, weight: 15)
      kruskal_weight = g.minimum_spanning_tree(algorithm: :kruskal).sum { |e| e[:weight] }
      prim_weight = g.minimum_spanning_tree(algorithm: :prim).sum { |e| e[:weight] }
      expect(kruskal_weight).to eq(prim_weight)
    end
  end

  # ── Maximum Flow ──

  describe '#max_flow' do
    it 'raises for undirected graph' do
      g = described_class.new
      g.add_edge(:a, :b)
      expect { g.max_flow(:a, :b) }.to raise_error(Philiprehberger::Graph::Error, /directed/)
    end

    it 'raises for missing source' do
      g = described_class.new(directed: true)
      g.add_node(:b)
      expect { g.max_flow(:a, :b) }.to raise_error(Philiprehberger::Graph::Error, /source/)
    end

    it 'raises for missing sink' do
      g = described_class.new(directed: true)
      g.add_node(:a)
      expect { g.max_flow(:a, :b) }.to raise_error(Philiprehberger::Graph::Error, /sink/)
    end

    it 'returns 0 when source equals sink' do
      g = described_class.new(directed: true)
      g.add_node(:a)
      expect(g.max_flow(:a, :a)).to eq(0)
    end

    it 'computes max flow for simple network' do
      g = described_class.new(directed: true)
      g.add_edge(:s, :a, weight: 10)
      g.add_edge(:s, :b, weight: 5)
      g.add_edge(:a, :t, weight: 5)
      g.add_edge(:b, :t, weight: 10)
      g.add_edge(:a, :b, weight: 15)
      expect(g.max_flow(:s, :t)).to eq(15)
    end

    it 'computes max flow for classic textbook network' do
      g = described_class.new(directed: true)
      g.add_edge(:s, :a, weight: 16)
      g.add_edge(:s, :c, weight: 13)
      g.add_edge(:a, :b, weight: 12)
      g.add_edge(:a, :c, weight: 10)
      g.add_edge(:c, :a, weight: 4)
      g.add_edge(:b, :c, weight: 9)
      g.add_edge(:b, :t, weight: 20)
      g.add_edge(:c, :d, weight: 14)
      g.add_edge(:d, :b, weight: 7)
      g.add_edge(:d, :t, weight: 4)
      expect(g.max_flow(:s, :t)).to eq(23)
    end

    it 'returns 0 when no path exists from source to sink' do
      g = described_class.new(directed: true)
      g.add_node(:s)
      g.add_node(:t)
      expect(g.max_flow(:s, :t)).to eq(0)
    end

    it 'handles single edge' do
      g = described_class.new(directed: true)
      g.add_edge(:s, :t, weight: 42)
      expect(g.max_flow(:s, :t)).to eq(42)
    end

    it 'handles parallel paths' do
      g = described_class.new(directed: true)
      g.add_edge(:s, :a, weight: 5)
      g.add_edge(:s, :b, weight: 5)
      g.add_edge(:a, :t, weight: 5)
      g.add_edge(:b, :t, weight: 5)
      expect(g.max_flow(:s, :t)).to eq(10)
    end
  end

  # ── Graph Coloring ──

  describe '#coloring' do
    it 'returns empty hash for empty graph' do
      g = described_class.new
      expect(g.coloring).to eq({})
    end

    it 'assigns color 0 to isolated nodes' do
      g = described_class.new
      g.add_node(:a)
      g.add_node(:b)
      colors = g.coloring
      expect(colors[:a]).to eq(0)
      expect(colors[:b]).to eq(0)
    end

    it 'assigns different colors to adjacent nodes' do
      g = described_class.new
      g.add_edge(:a, :b)
      colors = g.coloring
      expect(colors[:a]).not_to eq(colors[:b])
    end

    it 'uses at most 2 colors for a bipartite graph' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :d)
      colors = g.coloring
      expect(colors.values.uniq.length).to be <= 2
    end

    it 'colors a complete graph K4 with 4 colors or fewer' do
      g = described_class.new
      %i[a b c d].combination(2) { |x, y| g.add_edge(x, y) }
      colors = g.coloring
      # All adjacent nodes must have different colors
      g.edges.each do |edge|
        expect(colors[edge[:from]]).not_to eq(colors[edge[:to]])
      end
    end

    it 'works on directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      colors = g.coloring
      expect(colors[:a]).not_to eq(colors[:b])
    end
  end

  describe '#chromatic_number_estimate' do
    it 'returns 0 for empty graph' do
      g = described_class.new
      expect(g.chromatic_number_estimate).to eq(0)
    end

    it 'returns 1 for single node' do
      g = described_class.new
      g.add_node(:a)
      expect(g.chromatic_number_estimate).to eq(1)
    end

    it 'returns 2 for a single edge' do
      g = described_class.new
      g.add_edge(:a, :b)
      expect(g.chromatic_number_estimate).to eq(2)
    end

    it 'returns 3 for a triangle' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :a)
      expect(g.chromatic_number_estimate).to eq(3)
    end
  end

  # ── Bipartiteness ──

  describe '#bipartite?' do
    it 'returns true for empty graph' do
      g = described_class.new
      expect(g.bipartite?).to be true
    end

    it 'returns true for single node' do
      g = described_class.new
      g.add_node(:a)
      expect(g.bipartite?).to be true
    end

    it 'returns true for a single edge' do
      g = described_class.new
      g.add_edge(:a, :b)
      expect(g.bipartite?).to be true
    end

    it 'returns true for even cycle' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :d)
      g.add_edge(:d, :a)
      expect(g.bipartite?).to be true
    end

    it 'returns false for odd cycle (triangle)' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :a)
      expect(g.bipartite?).to be false
    end

    it 'returns false for K4' do
      g = described_class.new
      %i[a b c d].combination(2) { |x, y| g.add_edge(x, y) }
      expect(g.bipartite?).to be false
    end

    it 'works on directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      expect(g.bipartite?).to be true
    end

    it 'detects non-bipartite directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :a)
      expect(g.bipartite?).to be false
    end
  end

  describe '#bipartite_sets' do
    it 'returns two empty sets for empty graph' do
      g = described_class.new
      sets = g.bipartite_sets
      expect(sets).not_to be_nil
      expect(sets[0]).to be_empty
      expect(sets[1]).to be_empty
    end

    it 'returns correct partition for a path' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      sets = g.bipartite_sets
      expect(sets).not_to be_nil
      set_a, set_b = sets
      # a and c should be in the same set, b in the other
      expect(set_a | set_b).to eq(Set.new(%i[a b c]))
      expect(set_a & set_b).to be_empty
    end

    it 'returns nil for non-bipartite graph' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :a)
      expect(g.bipartite_sets).to be_nil
    end

    it 'handles disconnected bipartite components' do
      g = described_class.new
      g.add_edge(:a, :b)
      g.add_edge(:c, :d)
      sets = g.bipartite_sets
      expect(sets).not_to be_nil
      expect(sets[0] | sets[1]).to eq(Set.new(%i[a b c d]))
    end
  end

  # ── Strongly Connected Components ──

  describe '#strongly_connected_components' do
    it 'raises for undirected graph' do
      g = described_class.new
      expect { g.strongly_connected_components }.to raise_error(Philiprehberger::Graph::Error, /directed/)
    end

    it 'returns empty array for empty graph' do
      g = described_class.new(directed: true)
      expect(g.strongly_connected_components).to eq([])
    end

    it 'each node is its own SCC in a DAG' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      sccs = g.strongly_connected_components
      expect(sccs.length).to eq(3)
      sccs.each { |scc| expect(scc.length).to eq(1) }
    end

    it 'finds single SCC in a cycle' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :c)
      g.add_edge(:c, :a)
      sccs = g.strongly_connected_components
      expect(sccs.length).to eq(1)
      expect(sccs.first).to contain_exactly(:a, :b, :c)
    end

    it 'finds multiple SCCs' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      g.add_edge(:b, :a)
      g.add_edge(:b, :c)
      g.add_edge(:c, :d)
      g.add_edge(:d, :c)
      sccs = g.strongly_connected_components
      expect(sccs.length).to eq(2)
      scc_sets = sccs.map { |s| Set.new(s) }
      expect(scc_sets).to include(Set.new(%i[a b]))
      expect(scc_sets).to include(Set.new(%i[c d]))
    end

    it 'handles isolated nodes as individual SCCs' do
      g = described_class.new(directed: true)
      g.add_node(:a)
      g.add_node(:b)
      sccs = g.strongly_connected_components
      expect(sccs.length).to eq(2)
    end

    it 'handles complex graph with multiple SCCs' do
      g = described_class.new(directed: true)
      g.add_edge(1, 2)
      g.add_edge(2, 3)
      g.add_edge(3, 1)
      g.add_edge(3, 4)
      g.add_edge(4, 5)
      g.add_edge(5, 4)
      sccs = g.strongly_connected_components
      scc_sets = sccs.map { |s| Set.new(s) }
      expect(scc_sets).to include(Set.new([1, 2, 3]))
      expect(scc_sets).to include(Set.new([4, 5]))
    end
  end

  # ── Graph Serialization ──

  describe '#to_dot' do
    it 'produces valid DOT for undirected graph' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 3)
      dot = g.to_dot
      expect(dot).to include('graph G {')
      expect(dot).to include('a -- b')
      expect(dot).to include('[weight=3]')
    end

    it 'produces valid DOT for directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:a, :b)
      dot = g.to_dot
      expect(dot).to include('digraph G {')
      expect(dot).to include('a -> b')
    end

    it 'omits weight attribute when weight is 1' do
      g = described_class.new
      g.add_edge(:a, :b)
      dot = g.to_dot
      expect(dot).not_to include('weight=')
    end

    it 'includes isolated nodes' do
      g = described_class.new
      g.add_node(:lonely)
      dot = g.to_dot
      expect(dot).to include('lonely;')
    end

    it 'handles empty graph' do
      g = described_class.new
      dot = g.to_dot
      expect(dot).to include('graph G {')
      expect(dot).to include('}')
    end
  end

  describe '#to_json' do
    it 'produces valid JSON for undirected graph' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 5)
      json = g.to_json
      data = JSON.parse(json, symbolize_names: true)
      expect(data[:directed]).to be false
      expect(data[:nodes]).to contain_exactly('a', 'b')
      expect(data[:edges].length).to eq(1)
      expect(data[:edges].first[:weight]).to eq(5)
    end

    it 'produces valid JSON for directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:x, :y)
      json = g.to_json
      data = JSON.parse(json, symbolize_names: true)
      expect(data[:directed]).to be true
    end

    it 'handles empty graph' do
      g = described_class.new
      json = g.to_json
      data = JSON.parse(json, symbolize_names: true)
      expect(data[:nodes]).to eq([])
      expect(data[:edges]).to eq([])
    end
  end

  describe '.from_json' do
    it 'round-trips an undirected graph' do
      g = described_class.new
      g.add_edge(:a, :b, weight: 3)
      g.add_edge(:b, :c, weight: 7)
      json = g.to_json
      g2 = Philiprehberger::Graph::Graph.from_json(json)
      expect(g2.directed?).to be false
      expect(g2.nodes).to contain_exactly(:a, :b, :c)
      expect(g2.edges.length).to eq(2)
    end

    it 'round-trips a directed graph' do
      g = described_class.new(directed: true)
      g.add_edge(:x, :y, weight: 10)
      json = g.to_json
      g2 = Philiprehberger::Graph::Graph.from_json(json)
      expect(g2.directed?).to be true
      expect(g2.neighbors(:x)).to include(:y)
      expect(g2.neighbors(:y)).not_to include(:x)
    end

    it 'preserves isolated nodes' do
      g = described_class.new
      g.add_node(:solo)
      json = g.to_json
      g2 = Philiprehberger::Graph::Graph.from_json(json)
      expect(g2.nodes).to include(:solo)
    end

    it 'handles empty graph' do
      g = described_class.new
      json = g.to_json
      g2 = Philiprehberger::Graph::Graph.from_json(json)
      expect(g2.nodes).to eq([])
      expect(g2.edges).to eq([])
    end
  end
end
