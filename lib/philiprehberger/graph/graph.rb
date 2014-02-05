# frozen_string_literal: true

module Philiprehberger
  module Graph
    # A directed or undirected graph with adjacency list storage.
    class Graph
      # @param directed [Boolean] whether the graph is directed
      def initialize(directed: false)
        @directed = directed
        @adjacency = {}
      end

      # Whether the graph is directed.
      #
      # @return [Boolean]
      def directed?
        @directed
      end

      # Add a node to the graph.
      #
      # @param id [Object] the node identifier
      # @return [self]
      def add_node(id)
        @adjacency[id] ||= []
        self
      end

      # Add an edge between two nodes.
      #
      # @param from [Object] source node
      # @param to [Object] destination node
      # @param weight [Numeric] edge weight
      # @return [self]
      def add_edge(from, to, weight: 1)
        add_node(from)
        add_node(to)
        @adjacency[from] << { node: to, weight: weight }
        @adjacency[to] << { node: from, weight: weight } unless @directed
        self
      end

      # Remove a node and all its edges.
      #
      # @param id [Object] the node to remove
      # @return [self]
      def remove_node(id)
        @adjacency.delete(id)
        @adjacency.each_value do |edges|
          edges.reject! { |e| e[:node] == id }
        end
        self
      end

      # Remove an edge between two nodes.
      #
      # @param from [Object] source node
      # @param to [Object] destination node
      # @return [self]
      def remove_edge(from, to)
        @adjacency[from]&.reject! { |e| e[:node] == to }
        @adjacency[to]&.reject! { |e| e[:node] == from } unless @directed
        self
      end

      # Return neighbor node ids for a given node.
      #
      # @param node [Object] the node
      # @return [Array<Object>] neighbor ids
      def neighbors(node)
        (@adjacency[node] || []).map { |e| e[:node] }
      end

      # Return the degree of a node (number of edges).
      #
      # @param node [Object] the node
      # @return [Integer]
      def degree(node)
        (@adjacency[node] || []).length
      end

      # Return all node ids.
      #
      # @return [Array<Object>]
      def nodes
        @adjacency.keys
      end

      # Return all edges as [from, to, weight] tuples.
      #
      # @return [Array<Hash>]
      def edges
        result = []
        seen = {}
        @adjacency.each do |from, edges_list|
          edges_list.each do |edge|
            key = @directed ? [from, edge[:node]] : [from, edge[:node]].sort
            unless seen[key]
              result << { from: from, to: edge[:node], weight: edge[:weight] }
              seen[key] = true
            end
          end
        end
        result
      end

      # Breadth-first search starting from a node.
      #
      # @param start [Object] the starting node
      # @return [Array<Object>] nodes in BFS order
      def bfs(start)
        return [] unless @adjacency.key?(start)

        visited = { start => true }
        queue = [start]
        result = []

        until queue.empty?
          node = queue.shift
          result << node
          neighbors(node).each do |neighbor|
            unless visited[neighbor]
              visited[neighbor] = true
              queue << neighbor
            end
          end
        end

        result
      end

      # Depth-first search starting from a node.
      #
      # @param start [Object] the starting node
      # @return [Array<Object>] nodes in DFS order
      def dfs(start)
        return [] unless @adjacency.key?(start)

        visited = {}
        result = []
        dfs_visit(start, visited, result)
        result
      end

      # Find the shortest path between two nodes using Dijkstra's algorithm.
      #
      # @param from [Object] source node
      # @param to [Object] destination node
      # @return [Array<Object>, nil] the path as an array of nodes, or nil if no path exists
      def shortest_path(from, to)
        return nil unless @adjacency.key?(from) && @adjacency.key?(to)
        return [from] if from == to

        distances = Hash.new(Float::INFINITY)
        distances[from] = 0
        previous = {}
        unvisited = @adjacency.keys.dup

        until unvisited.empty?
          current = unvisited.min_by { |n| distances[n] }
          break if distances[current] == Float::INFINITY

          unvisited.delete(current)

          return build_path(previous, from, to) if current == to

          (@adjacency[current] || []).each do |edge|
            alt = distances[current] + edge[:weight]
            if alt < distances[edge[:node]]
              distances[edge[:node]] = alt
              previous[edge[:node]] = current
            end
          end
        end

        nil
      end

      # Topological sort (directed acyclic graphs only).
      #
      # @return [Array<Object>] nodes in topological order
      # @raise [Error] if the graph contains a cycle or is not directed
      def topological_sort
        raise Error, 'topological sort requires a directed graph' unless @directed
        raise Error, 'graph contains a cycle' if cycle?

        visited = {}
        result = []

        @adjacency.each_key do |node|
          topo_visit(node, visited, result) unless visited[node]
        end

        result.reverse
      end

      # Check if the graph contains a cycle.
      #
      # @return [Boolean]
      def cycle?
        if @directed
          directed_cycle?
        else
          undirected_cycle?
        end
      end

      # Find connected components (undirected) or weakly connected components (directed).
      #
      # @return [Array<Array<Object>>] arrays of node ids per component
      def connected_components
        visited = {}
        components = []

        @adjacency.each_key do |node|
          unless visited[node]
            component = []
            cc_visit(node, visited, component)
            components << component
          end
        end

        components
      end

      private

      def dfs_visit(node, visited, result)
        visited[node] = true
        result << node
        neighbors(node).each do |neighbor|
          dfs_visit(neighbor, visited, result) unless visited[neighbor]
        end
      end

      def build_path(previous, from, to)
        path = [to]
        current = to
        while current != from
          current = previous[current]
          return nil if current.nil?

          path.unshift(current)
        end
        path
      end

      def topo_visit(node, visited, result)
        return if visited[node]

        visited[node] = true
        neighbors(node).each do |neighbor|
          topo_visit(neighbor, visited, result) unless visited[neighbor]
        end
        result << node
      end

      def directed_cycle?
        white = 0
        gray = 1
        black = 2
        colors = Hash.new(white)

        @adjacency.each_key do |node|
          return true if colors[node] == white && directed_cycle_visit(node, colors, gray, black)
        end

        false
      end

      def directed_cycle_visit(node, colors, gray, black)
        colors[node] = gray
        neighbors(node).each do |neighbor|
          return true if colors[neighbor] == gray
          return true if colors[neighbor] != black && directed_cycle_visit(neighbor, colors, gray, black)
        end
        colors[node] = black
        false
      end

      def undirected_cycle?
        visited = {}

        @adjacency.each_key do |node|
          unless visited[node]
            return true if undirected_cycle_visit(node, nil, visited)
          end
        end

        false
      end

      def undirected_cycle_visit(node, parent, visited)
        visited[node] = true
        neighbors(node).each do |neighbor|
          if !visited[neighbor]
            return true if undirected_cycle_visit(neighbor, node, visited)
          elsif neighbor != parent
            return true
          end
        end
        false
      end

      def cc_visit(node, visited, component)
        visited[node] = true
        component << node

        # For connected components, treat as undirected regardless
        all_neighbors = Set.new
        (@adjacency[node] || []).each { |e| all_neighbors << e[:node] }
        if @directed
          @adjacency.each do |from, edges_list|
            edges_list.each { |e| all_neighbors << from if e[:node] == node }
          end
        end

        all_neighbors.each do |neighbor|
          cc_visit(neighbor, visited, component) unless visited[neighbor]
        end
      end
    end
  end
end
