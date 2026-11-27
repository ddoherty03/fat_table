# frozen_string_literal: true

# Run with: bundle exec ruby -Ilib benchmark/transform_and_render.rb
# Set BENCH_ROWS and BENCH_GROUP_SIZE to vary the synthetic workload.
require 'fat_table'
require 'digest'
require 'json'

row_count = Integer(ENV.fetch('BENCH_ROWS', '4000'))
group_size = Integer(ENV.fetch('BENCH_GROUP_SIZE', '1'))
raise ArgumentError, 'row and group sizes must be positive' unless row_count.positive? && group_size.positive?

data = Array.new(row_count) { |i| { id: i, amount: i * 3, label: "Item #{i}" } }
table = FatTable::Table.from_aoh(data)
table.explicit_boundaries = (group_size - 1...row_count).step(group_size).to_a
report = FatTable::Table.from_aoh(data)
operations = {
  select_groups: -> { table.select(:id, group_no: '@group')[:group_no] },
  where_groups: -> { table.where('@group.even?')[:id] },
  text_report: -> { report.to_text },
}

text_output = ARGV.include?('--text')
if text_output
  puts "FatTable benchmarks — Ruby #{RUBY_VERSION}"
  puts "Rows: #{row_count} | Group size: #{group_size} | 3 samples after warmup"
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
    { seconds: elapsed, allocations: allocated, digest: Digest::SHA256.hexdigest(Marshal.dump(result)) }
  end
  if text_output
    times = samples.map { |sample| sample[:seconds] * 1000 }.sort
    allocations = samples.map { |sample| sample[:allocations] }.sort
    printf "% -20s %12.3f %12.3f %12.3f %14d\n", name, times[1], times.first, times.last, allocations[1]
  else
    puts JSON.generate(name: name, rows: row_count, group_size: group_size, samples: samples)
  end
end

puts "\nAllocations are median object counts. Input construction and hashing are excluded." if text_output
