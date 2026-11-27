# frozen_string_literal: true

# Run with: scripts/benchmark-sort 4000
require 'fat_table'
require 'digest'
require 'json'

row_count = Integer(ENV.fetch('BENCH_ROWS', '4000'))
raise ArgumentError, 'row count must be positive' unless row_count.positive?

data = Array.new(row_count) { |i|
  {
    id: i,
    score: i % 64,
    category: "Category #{i % 4}",
    active: [nil, false, true][i % 3],
    date: Date.new(2026, 1, 1) + i % 8,
  }
}.shuffle(random: Random.new(42))
table = FatTable::Table.from_aoh(data)
operations = {
  numeric_sort: -> { table.order_by(:score) },
  mixed_sort: -> { table.order_by(:category, :active!, :date) },
  expression_sort: -> { table.order_with('score % 16') },
}

text_output = ARGV.include?('--text')
if text_output
  puts "FatTable sort benchmarks — Ruby #{RUBY_VERSION}"
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

puts "\nAllocations are median object counts. Input construction and hashing are excluded." if text_output
