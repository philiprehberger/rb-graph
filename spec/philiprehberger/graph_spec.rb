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
end
