# frozen_string_literal: true

# Run with: scripts/benchmark-insertion 1000
require 'fat_table'
require 'digest'
require 'json'

row_count = Integer(ENV.fetch('BENCH_ROWS', '1000'))
raise ArgumentError, 'row count must be positive' unless row_count.positive?

operations = [4, 16, 64].to_h do |width|
  heads = Array.new(width) { |i| "column_#{i}".to_sym }
  data = Array.new(row_count) { |i| heads.to_h { |head| [head, i] } }
  operation = lambda do
    table = FatTable::Table.new(*heads)
    data.each { |row| table.add_row(row) }
    table
  end
  ["insert_#{width}_columns", operation]
end

text_output = ARGV.include?('--text')
if text_output
  puts "FatTable row insertion benchmarks — Ruby #{RUBY_VERSION}"
  puts "Rows: #{row_count} | 3 samples after warmup"
  puts
  printf "% -20s %12s %12s %12s %14s\n", 'Operation', 'Median (ms)', 'Min (ms)', 'Max (ms)', 'Allocations'
  puts '-' * 74
end

operations.each do |name, operation|
  operation.call # Warm up before measuring; input construction is excluded.
  samples = Array.new(3) do
    GC.start
    before = GC.stat(:total_allocated_objects)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = operation.call
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    allocated = GC.stat(:total_allocated_objects) - before
    output = [result.headers, result.rows, result.boundaries]
    { seconds: elapsed, allocations: allocated, digest: Digest::SHA256.hexdigest(Marshal.dump(output)) }
  end
  if text_output
    times = samples.map { |sample| sample[:seconds] * 1000 }.sort
    allocations = samples.map { |sample| sample[:allocations] }.sort
    printf "% -20s %12.3f %12.3f %12.3f %14d\n", name, times[1], times.first, times.last, allocations[1]
  else
    puts JSON.generate(name: name, rows: row_count, ruby: RUBY_VERSION, samples: samples)
  end
end

if text_output
  puts "\nAllocations are median object counts. Input data construction and hashing are excluded."
  puts 'Table construction is included.'
end
