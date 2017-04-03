# frozen_string_literal: true

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
end
