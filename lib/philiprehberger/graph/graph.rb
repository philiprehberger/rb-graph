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

      # Return the in-degree of a node (directed graphs).
      # For undirected graphs, returns the same as degree.
      #
      # @param node [Object] the node
      # @return [Integer]
      def in_degree(node)
        return degree(node) unless @directed

        count = 0
        @adjacency.each_value do |edges_list|
          edges_list.each { |e| count += 1 if e[:node] == node }
        end
        count
      end

      # Return the out-degree of a node (directed graphs).
      # For undirected graphs, returns the same as degree.
      #
      # @param node [Object] the node
      # @return [Integer]
      def out_degree(node)
        return degree(node) unless @directed

        (@adjacency[node] || []).length
      end

      # Check if a node exists.
      #
      # @param id [Object] the node identifier
      # @return [Boolean]
      def node?(id)
        @adjacency.key?(id)
      end

      # Check if an edge exists between two nodes.
      #
      # @param from [Object] source node
      # @param to [Object] destination node
      # @return [Boolean]
      def edge?(from, to)
        return false unless @adjacency.key?(from)

        @adjacency[from].any? { |e| e[:node] == to }
      end

      # Get the weight of an edge.
      #
      # @param from [Object] source node
      # @param to [Object] destination node
      # @return [Numeric, nil] the edge weight, or nil if no edge exists
      def weight(from, to)
        return nil unless @adjacency.key?(from)

        edge = @adjacency[from].find { |e| e[:node] == to }
        edge&.dig(:weight)
      end

      # Return all node ids.
      #
      # @return [Array<Object>]
      def nodes
        @adjacency.keys
      end

      # Return the number of nodes.
      #
      # @return [Integer]
      def node_count
        @adjacency.length
      end

      # Return the number of edges.
      #
      # @return [Integer]
      def edge_count
        edges.length
      end

      # Whether the graph has no nodes.
      #
      # @return [Boolean]
      def empty?
        @adjacency.empty?
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

      # Check if a path exists between two nodes using BFS.
      #
      # @param from [Object] source node
      # @param to [Object] destination node
      # @return [Boolean]
      def path?(from, to)
        return false unless @adjacency.key?(from) && @adjacency.key?(to)
        return true if from == to

        visited = { from => true }
        queue = [from]

        until queue.empty?
          node = queue.shift
          neighbors(node).each do |neighbor|
            return true if neighbor == to

            unless visited[neighbor]
              visited[neighbor] = true
              queue << neighbor
            end
          end
        end

        false
      end

      # Extract a subgraph containing only the specified nodes and edges between them.
      #
      # @param node_ids [Array<Object>] the nodes to include
      # @return [Graph] a new graph
      def subgraph(node_ids)
        node_set = node_ids.is_a?(Set) ? node_ids : Set.new(node_ids)
        g = self.class.new(directed: @directed)

        node_set.each { |id| g.add_node(id) if @adjacency.key?(id) }

        @adjacency.each do |from, edges_list|
          next unless node_set.include?(from)

          edges_list.each do |edge|
            next unless node_set.include?(edge[:node])
            next if !@directed && from.to_s > edge[:node].to_s

            g.add_edge(from, edge[:node], weight: edge[:weight])
          end
        end

        g
      end

      # Return a new graph with all edges reversed.
      # Only works on directed graphs.
      #
      # @return [Graph] a new graph with reversed edges
      # @raise [Error] if the graph is not directed
      def transpose
        raise Error, 'transpose requires a directed graph' unless @directed

        g = self.class.new(directed: true)
        @adjacency.each_key { |id| g.add_node(id) }
        @adjacency.each do |from, edges_list|
          edges_list.each do |edge|
            g.add_edge(edge[:node], from, weight: edge[:weight])
          end
        end
        g
      end

      # Calculate the density of the graph.
      # Density is the ratio of actual edges to possible edges.
      #
      # @return [Float] density between 0.0 and 1.0
      def density
        n = @adjacency.length
        return 0.0 if n < 2

        m = edge_count.to_f
        max_edges = @directed ? n * (n - 1) : n * (n - 1) / 2.0
        m / max_edges
      end

      # Find connected components (undirected) or weakly connected components (directed).
      #
      # @return [Array<Array<Object>>] arrays of node ids per component
      def connected_components
        visited = {}
        components = []

        @adjacency.each_key do |node|
          next if visited[node]

          component = []
          cc_visit(node, visited, component)
          components << component
        end

        components
      end

      # Find the minimum spanning tree using Kruskal's or Prim's algorithm.
      # Only works on undirected graphs.
      #
      # @param algorithm [Symbol] :kruskal or :prim
      # @return [Array<Hash>] edges in the MST as {from:, to:, weight:} hashes
      # @raise [Error] if the graph is directed or disconnected
      def minimum_spanning_tree(algorithm: :kruskal)
        raise Error, 'minimum spanning tree requires an undirected graph' if @directed
        raise Error, 'graph is empty' if @adjacency.empty?

        components = connected_components
        raise Error, 'graph is disconnected' if components.length > 1

        case algorithm
        when :kruskal then kruskal_mst
        when :prim then prim_mst
        else raise Error, "unknown algorithm: #{algorithm}"
        end
      end

      # Compute the maximum flow from source to sink using Edmonds-Karp (BFS-based Ford-Fulkerson).
      # Only works on directed graphs.
      #
      # @param source [Object] source node
      # @param sink [Object] sink node
      # @return [Numeric] the maximum flow value
      # @raise [Error] if the graph is not directed or nodes don't exist
      def max_flow(source, sink)
        raise Error, 'max_flow requires a directed graph' unless @directed
        raise Error, 'source node not found' unless @adjacency.key?(source)
        raise Error, 'sink node not found' unless @adjacency.key?(sink)
        return 0 if source == sink

        edmonds_karp(source, sink)
      end

      # Greedy graph coloring. Assigns the smallest available color (integer) to each node.
      #
      # @return [Hash] mapping of node => color (integer starting from 0)
      def coloring
        result = {}
        @adjacency.each_key do |node|
          used_colors = Set.new
          neighbors(node).each do |neighbor|
            used_colors << result[neighbor] if result.key?(neighbor)
          end
          color = 0
          color += 1 while used_colors.include?(color)
          result[node] = color
        end
        result
      end

      # Estimate the chromatic number using greedy coloring.
      #
      # @return [Integer] estimated chromatic number
      def chromatic_number_estimate
        return 0 if @adjacency.empty?

        colors = coloring
        (colors.values.max || 0) + 1
      end

      # Check whether the graph is bipartite.
      #
      # @return [Boolean]
      def bipartite?
        !bipartite_sets.nil?
      end

      # Find bipartite partition sets using BFS 2-coloring.
      #
      # @return [Array<Set, Set>, nil] two sets of nodes, or nil if not bipartite
      def bipartite_sets
        color = {}
        set_a = Set.new
        set_b = Set.new

        @adjacency.each_key do |start|
          next if color.key?(start)

          color[start] = 0
          set_a << start
          queue = [start]

          until queue.empty?
            node = queue.shift
            all_neighbors = bipartite_neighbors(node)
            all_neighbors.each do |neighbor|
              if color.key?(neighbor)
                return nil if color[neighbor] == color[node]
              else
                color[neighbor] = 1 - color[node]
                if color[neighbor].zero?
                  set_a << neighbor
                else
                  set_b << neighbor
                end
                queue << neighbor
              end
            end
          end
        end

        [set_a, set_b]
      end

      # Find strongly connected components using Tarjan's algorithm.
      # Only works on directed graphs.
      #
      # @return [Array<Array<Object>>] arrays of node ids per SCC
      # @raise [Error] if the graph is not directed
      def strongly_connected_components
        raise Error, 'strongly_connected_components requires a directed graph' unless @directed

        tarjan_scc
      end

      # Serialize the graph to DOT format.
      #
      # @return [String] DOT format string
      def to_dot
        type = @directed ? 'digraph' : 'graph'
        connector = @directed ? '->' : '--'
        lines = ["#{type} G {"]

        @adjacency.each_key do |node|
          lines << "  #{dot_escape(node)};"
        end

        seen = {}
        @adjacency.each do |from, edges_list|
          edges_list.each do |edge|
            key = @directed ? [from, edge[:node]] : [from, edge[:node]].sort
            next if seen[key]

            seen[key] = true
            attrs = edge[:weight] == 1 ? '' : " [weight=#{edge[:weight]}]"
            lines << "  #{dot_escape(from)} #{connector} #{dot_escape(edge[:node])}#{attrs};"
          end
        end

        lines << '}'
        lines.join("\n")
      end

      # Serialize the graph to JSON.
      #
      # @return [String] JSON string
      def to_json(*_args)
        require 'json'
        data = {
          directed: @directed,
          nodes: @adjacency.keys,
          edges: edges.map { |e| { from: e[:from], to: e[:to], weight: e[:weight] } }
        }
        JSON.generate(data)
      end

      # Deserialize a graph from JSON.
      #
      # @param json_str [String] JSON string
      # @return [Graph] a new graph instance
      def self.from_json(json_str)
        require 'json'
        data = JSON.parse(json_str, symbolize_names: true)
        graph = new(directed: data[:directed])
        (data[:nodes] || []).each { |n| graph.add_node(n.is_a?(String) ? n.to_sym : n) }
        (data[:edges] || []).each do |e|
          from = e[:from].is_a?(String) ? e[:from].to_sym : e[:from]
          to = e[:to].is_a?(String) ? e[:to].to_sym : e[:to]
          graph.add_edge(from, to, weight: e[:weight] || 1)
        end
        graph
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
          return true if !visited[node] && undirected_cycle_visit(node, nil, visited)
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

      # ── MST helpers ──

      def kruskal_mst
        all_edges = edges.sort_by { |e| e[:weight] }
        parent = {}
        rank = Hash.new(0)

        @adjacency.each_key { |n| parent[n] = n }

        mst = []
        all_edges.each do |edge|
          root_from = uf_find(parent, edge[:from])
          root_to = uf_find(parent, edge[:to])
          next if root_from == root_to

          mst << edge
          uf_union(parent, rank, root_from, root_to)
          break if mst.length == @adjacency.length - 1
        end

        mst
      end

      def prim_mst
        start = @adjacency.keys.first
        in_mst = { start => true }
        mst = []
        candidate_edges = (@adjacency[start] || []).map { |e| { from: start, to: e[:node], weight: e[:weight] } }

        until candidate_edges.empty? || mst.length == @adjacency.length - 1
          candidate_edges.sort_by! { |e| e[:weight] }
          idx = candidate_edges.index { |e| !in_mst[e[:to]] }
          break if idx.nil?

          edge = candidate_edges.delete_at(idx)
          next if in_mst[edge[:to]]

          in_mst[edge[:to]] = true
          mst << edge
          (@adjacency[edge[:to]] || []).each do |e|
            candidate_edges << { from: edge[:to], to: e[:node], weight: e[:weight] } unless in_mst[e[:node]]
          end
        end

        mst
      end

      def uf_find(parent, node)
        root = node
        root = parent[root] while parent[root] != root

        # Path compression
        while parent[node] != root
          next_node = parent[node]
          parent[node] = root
          node = next_node
        end

        root
      end

      def uf_union(parent, rank, a, b)
        if rank[a] < rank[b]
          parent[a] = b
        elsif rank[a] > rank[b]
          parent[b] = a
        else
          parent[b] = a
          rank[a] += 1
        end
      end

      # ── Max flow helpers ──

      def edmonds_karp(source, sink)
        # Build residual capacity graph
        capacity = Hash.new { |h, k| h[k] = Hash.new(0) }
        @adjacency.each do |from, edges_list|
          edges_list.each do |edge|
            capacity[from][edge[:node]] += edge[:weight]
          end
        end

        total_flow = 0
        loop do
          # BFS to find augmenting path
          parent = { source => nil }
          visited = { source => true }
          queue = [source]

          until queue.empty?
            node = queue.shift
            break if node == sink

            capacity[node].each do |neighbor, cap|
              next unless cap.positive? && !visited[neighbor]

              visited[neighbor] = true
              parent[neighbor] = node
              queue << neighbor
            end
          end

          break unless visited[sink]

          # Find bottleneck
          path_flow = Float::INFINITY
          node = sink
          while parent[node]
            path_flow = [path_flow, capacity[parent[node]][node]].min
            node = parent[node]
          end

          # Update residual capacities
          node = sink
          while parent[node]
            capacity[parent[node]][node] -= path_flow
            capacity[node][parent[node]] += path_flow
            node = parent[node]
          end

          total_flow += path_flow
        end

        total_flow
      end

      # ── Bipartite helpers ──

      def bipartite_neighbors(node)
        result = Set.new
        (@adjacency[node] || []).each { |e| result << e[:node] }
        if @directed
          @adjacency.each do |from, edges_list|
            edges_list.each { |e| result << from if e[:node] == node }
          end
        end
        result
      end

      # ── Tarjan's SCC ──

      def tarjan_scc
        index_counter = [0]
        stack = []
        on_stack = {}
        index = {}
        lowlink = {}
        result = []

        @adjacency.each_key do |node|
          tarjan_visit(node, index_counter, stack, on_stack, index, lowlink, result) unless index.key?(node)
        end

        result
      end

      def tarjan_visit(node, index_counter, stack, on_stack, index, lowlink, result)
        index[node] = index_counter[0]
        lowlink[node] = index_counter[0]
        index_counter[0] += 1
        stack.push(node)
        on_stack[node] = true

        neighbors(node).each do |neighbor|
          if !index.key?(neighbor)
            tarjan_visit(neighbor, index_counter, stack, on_stack, index, lowlink, result)
            lowlink[node] = [lowlink[node], lowlink[neighbor]].min
          elsif on_stack[neighbor]
            lowlink[node] = [lowlink[node], index[neighbor]].min
          end
        end

        return unless lowlink[node] == index[node]

        component = []
        loop do
          w = stack.pop
          on_stack[w] = false
          component << w
          break if w == node
        end
        result << component
      end

      # ── DOT helpers ──

      def dot_escape(value)
        str = value.to_s
        if str.match?(/\A[a-zA-Z_]\w*\z/)
          str
        else
          "\"#{str.gsub('"', '\\"')}\""
        end
      end
    end
  end
end
