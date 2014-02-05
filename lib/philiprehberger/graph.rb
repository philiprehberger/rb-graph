# frozen_string_literal: true

require 'set'

require_relative 'graph/version'
require_relative 'graph/graph'

module Philiprehberger
  module Graph
    class Error < StandardError; end

    # Create a new graph.
    #
    # @param directed [Boolean] whether the graph is directed
    # @return [Graph] a new graph instance
    def self.new(directed: false)
      Graph.new(directed: directed)
    end
  end
end
