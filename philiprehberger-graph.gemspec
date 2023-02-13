# frozen_string_literal: true

require_relative 'lib/philiprehberger/graph/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-graph'
  spec.version = Philiprehberger::Graph::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Directed and undirected graph with traversal, shortest path, and topological sort'
  spec.description = 'Graph data structure supporting directed and undirected modes with adjacency list storage. ' \
                       'Includes BFS, DFS, Dijkstra shortest path, topological sort, cycle detection, ' \
                       'and connected component discovery.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-graph'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-graph'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-graph/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-graph/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
