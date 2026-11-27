# frozen_string_literal: true

require 'fat_table'
require 'digest'
require 'json'

row_count = Integer(ENV.fetch('BENCH_ROWS', '200'))
raise ArgumentError, 'row count must be positive' unless row_count.positive?

# Duplicate keys on each side, with partial overlap and unmatched rows.
# Build expected rows independently, outside the measured operations.
left_rows = Array.new(row_count) { |i| { id: i / 2, left_value: "Left #{i}" } }
right_rows = Array.new(row_count) { |i| { id: i / 2 + row_count / 4, right_value: "Right #{i}" } }
left = FatTable::Table.from_aoh(left_rows)
right = FatTable::Table.from_aoh(right_rows)
inner_expected = []
full_expected = []
matched_right = {}
left_rows.each do |left_row|
  matches = right_rows.each_with_index.select { |right_row, _| left_row[:id] == right_row[:id] }
  if matches.empty?
    full_expected << left_row.merge(id_b: nil, right_value: nil)
  else
    matches.each do |right_row, index|
      matched_right[index] = true
      inner_expected << left_row.merge(right_value: right_row[:right_value])
      full_expected << left_row.merge(id_b: right_row[:id], right_value: right_row[:right_value])
    end
  end
end
right_rows.each_with_index do |row, index|
  full_expected << {
    id: nil,
    left_value: nil,
    id_b: row[:id],
    right_value: row[:right_value]
  } unless matched_right[index]
end

operations = {
  natural_inner: [-> { left.join(right) }, inner_expected],
  symbol_inner: [-> { left.join(right, :id) }, inner_expected],
  natural_full: [-> { left.full_join(right) }, full_expected],
}
text_output = ARGV.include?('--text')
if text_output
  puts "FatTable join benchmarks — Ruby #{RUBY_VERSION}"
  puts "Rows per input: #{row_count} | Duplicate keys, partial overlap | 3 samples after warmup"
  puts
  printf "%-20s %10s %12s %12s %12s %14s\n",
         'Operation',
         'Rows out',
         'Median (ms)',
         'Min (ms)',
         'Max (ms)',
         'Allocations'
end
operations.each do |name, (operation, expected)|
  raise "Unexpected result for #{name}" unless operation.call.rows == expected

  samples = Array.new(3) do
    GC.start
    before = GC.stat(:total_allocated_objects)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = operation.call
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    allocated = GC.stat(:total_allocated_objects) - before
    output = result.rows
    raise "Unexpected result for #{name}" unless output == expected

    { seconds: elapsed, allocations: allocated, digest: Digest::SHA256.hexdigest(Marshal.dump(output)) }
  end
  if text_output
    times = samples.map { |sample| sample[:seconds] * 1000 }.sort
    allocations = samples.map { |sample| sample[:allocations] }.sort
    printf "%-20s %10d %12.3f %12.3f %12.3f %14d\n",
           name,
           expected.size,
           times[1],
           times.first,
           times.last,
           allocations[1]
  else
    puts JSON.generate(name: name, rows: row_count, output_rows: expected.size, ruby: RUBY_VERSION, samples: samples)
  end
end
puts "\nAllocations are medians. Setup, output verification, and hashing are excluded." if text_output
