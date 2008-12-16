# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name     = "active_resource_throttle"
  s.version  = "1.0.0"
  s.summary  = "A throttler for ActiveResource requests."
  s.authors  = ["Kyle Banker", "Alexander Interactive, Inc."]
  s.date     = "2008-12-16"
  s.email    = "knb@alexanderinteractive.com"
  s.homepage = "http://github.com/aiaio/active_resource_throttle"
  
  s.require_paths = ["lib"]
  s.files         = ["README.rdoc", 
                     "Rakefile", 
                     "HISTORY", 
                     "LICENSE", 
                     "lib/active_resource_throttle.rb",
                     "lib/active_resource_throttle/hash_ext.rb"]
  s.test_files    = ["test/active_resource_throttle_test.rb"]
  
  s.has_rdoc      = true
  s.rdoc_options  = ["--main", "README.rdoc"]
  s.extra_rdoc_files = ["LICENSE", "HISTORY", "README.rdoc"]
end
