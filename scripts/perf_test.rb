#!/usr/bin/ruby

require 'benchmark'
require 'lib/spool_pool'

N = 10000

pool = SpoolPool::Pool.new 'test_spool'

Benchmark.bm( 7 ) do |bm|

  bm.report( "Put:" ) { N.times { pool.put :my_spool, "foo" } }
  bm.report( "Get:" ) { N.times { pool.get :my_spool } }
  bm.report( "Mixed:" ) { N.times { pool.put :my_spool, "foo"; pool.get :my_spool } }

end
