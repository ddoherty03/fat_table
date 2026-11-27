# frozen_string_literal: true

# Run with: scripts/benchmark-column 10000
require 'fat_table'
require 'digest'
require 'json'

row_count = Integer(ENV.fetch('BENCH_ROWS', '10000'))
raise ArgumentError, 'row count must be positive' unless row_count.positive?

numeric_values = Array.new(row_count) { |i| i.even? ? i : BigDecimal(i.to_s) }
string_values = Array.new(row_count) { |i| "Item #{i}" }
tolerant_values = Array.new(row_count) { |i| i.even? ? i : 'unknown' }
date_values = Array.new(row_count) { |i| Date.new(2026, 1, 1) + i % 28 }
boolean_values = Array.new(row_count, &:even?)
operations = {
  native_numeric: -> { FatTable::Column.new(header: :value, type: 'Numeric', items: numeric_values) },
  strings: -> { FatTable::Column.new(header: :value, type: 'String', items: string_values) },
  native_dates: -> { FatTable::Column.new(header: :value, type: 'DateTime', items: date_values) },
  native_booleans: -> { FatTable::Column.new(header: :value, type: 'Boolean', items: boolean_values) },
  tolerant_numeric: lambda {
    FatTable::Column.new(header: :value, type: 'Numeric', tolerant: true, items: tolerant_values)
  },
}

text_output = ARGV.include?('--text')
if text_output
  puts "FatTable column append benchmarks — Ruby #{RUBY_VERSION}"
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
    output = [result.type, result.items]
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
  puts 'Column construction is included.'
end
