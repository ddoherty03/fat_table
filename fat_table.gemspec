# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fat_table/version'

Gem::Specification.new do |spec|
  spec.name          = "fat_table"
  spec.version       = FatTable::VERSION
  spec.authors       = ["Daniel E. Doherty"]
  spec.email         = ["ded-law@ddoherty.net"]

  spec.summary       = %q{Provides tools for working with tables as a data type.}
  spec.description   = %q{
FatTable is a gem that treats tables as a data type. It provides methods for
constructing tables from a variety of sources, building them row-by-row,
extracting rows, columns, and cells, and performing aggregate operations on
columns. It also provides as set of SQL-esque methods for manipulating table
objects: select for filtering by columns or for creating new columns, where
for filtering by rows, order_by for sorting rows, distinct for eliminating
duplicate rows, group_by for aggregating multiple rows into single rows and
applying column aggregate methods to ungrouped columns, a collection of join
methods for combining tables, and more.

Furthermore, FatTable provides methods for formatting tables and producing
output that targets various output media: text, ANSI terminals, ruby data
structures, LaTeX tables, Emacs org-mode tables, and more. The formatting
methods can specify cell formatting in a way that is uniform across all the
output methods and can also decorate the output with any number of footers,
including group footers. FatTable applies formatting directives to the extent
they makes sense for the output medium and treats other formatting directives as
no-ops.

FatTable can be used to perform operations on data that are naturally best
conceived of as tables, which in my experience is quite often. It can also serve
as a foundation for providing reporting functions where flexibility about the
output medium can be quite useful. Finally FatTable can be used within Emacs
org-mode files in code blocks targeting the Ruby language. Org mode tables are
presented to a ruby code block as an array of arrays, so FatTable can read
them in with its .from_aoa constructor. A FatTable table can output as an
array of arrays with its .to_aoa output function and will be rendered in an
org-mode buffer as an org-table, ready for processing by other code blocks.
}

  spec.homepage      = 'https://github.com/ddoherty03/fat_table'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  # 'allowed_push_host' to allow pushing to a single host or delete this section
  # to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = ['ft_console']
  spec.require_paths = ['lib']
  spec.metadata['yard.run'] = 'yri' # use "yard" to build full HTML docs.

  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'redcarpet'

  spec.add_runtime_dependency 'fat_core', '~> 4.0', '>= 4.1'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'rainbow'
  spec.add_runtime_dependency 'dbi'
  spec.add_runtime_dependency 'dbd-pg'
  spec.add_runtime_dependency 'dbd-mysql'
  spec.add_runtime_dependency 'dbd-sqlite3'
end
