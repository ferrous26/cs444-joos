require 'benchmark'

Benchmark.bmbm do |bm|
  a = [:a, :b, :c]
  b = [:c, :a, :b]
  c = [:d, :a, :c]

  n = 100_000

  [
    [a, b, true],
    [a, c, false]
  ].each do |left, right, value|

    bm.report("- #{value}") { 
      n.times {
        (left - right).empty? && (right - left).empty?
      }
    }
    bm.report("| #{value}") {
      n.times {
        result = (left | right).size
        result == left.size && result == right.size
      }
    }
    bm.report("& #{value}") {
      n.times {
        result = (left & right).size
        result == left.size && result == right.size
      }
    }

  end
end

