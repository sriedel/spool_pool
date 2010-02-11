Gem::Specification.new do |s|
  s.name = "spool_pool"
  s.version = "0.2"

  s.required_ruby_version = ">= 1.9.1"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sven Riedel"]
  s.date = %q{2010-02-11}
  s.description = %q{A simple library for spooler pools.}
  s.summary = %q{A simple library for spooler pools.}
  s.email = %q{sr@gimp.org}

  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}

  s.extra_rdoc_files = %W{ LICENSE.txt README.rdoc }
  s.files = %W{ LICENSE.txt
                README.rdoc
                History.rdoc
                TODOs
                lib/spool_pool.rb
                lib/spool_pool/pool.rb
                lib/spool_pool/spool.rb
                lib/spool_pool/file.rb
                spec/spec_helper.rb
                spec/spool_pool/pool_spec.rb
                spec/spool_pool/spool_spec.rb
                spec/spool_pool/file_spec.rb
                test_spool
                scripts/perf_test.rb
              }

end
