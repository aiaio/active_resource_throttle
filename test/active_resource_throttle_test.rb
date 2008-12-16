$:.unshift File.join(File.dirname(__FILE__), "..", "lib", "active_resource_throttle")
require "hash_ext"
require "rubygems"
require "active_resource"
require "active_resource/http_mock"
require "test/unit"
require "shoulda"
require File.join(File.dirname(__FILE__), "..", "lib", "active_resource_throttle")

puts "***"
puts "ActiveResource Throttle test suite will take some time to run."
puts "***"

class ActiveResourceThrottleTest < Test::Unit::TestCase
  
  should "allow inclusion if #connection class method exists" do 
    class WillSucceed; def self.connection; end; end
    assert WillSucceed.instance_eval { include(ActiveResourceThrottle) }
  end
  
  should "not allow inclusion if #conneciton class method is absent" do 
    class WillFail; end
    assert_raises StandardError do
      WillFail.instance_eval { include(ActiveResourceThrottle) }
    end
  end
  
  class Resource < ActiveResource::Base; include ActiveResourceThrottle; end
    
  should "raise an argument error on invalid keys" do 
    assert_raises ArgumentError, "Invalid option(s): random_key" do
      Resource.instance_eval { throttle(:random_key => 'blah') }
    end
  end
  
  should "raise an argument error on missing required keys" do 
    assert_raises ArgumentError, "Missing required option(s): requests" do
      Resource.instance_eval { throttle(:interval => 20) }
    end
  end
  
  class SampleResource < ActiveResource::Base
    include ActiveResourceThrottle
    self.throttle(:requests => 45, :interval => 10, :sleep_interval => 15)
    self.site         = "http://example.com"
    self.element_name = "widget" 
  end
  
  context "When ActiveResourceThrottle is included and #throttle method has been invoked - " do
    should "set class instance variables" do 
  
      assert_equal 45, SampleResource.throttle_request_limit
    end
    
    should "set the interval for the class" do 
      assert_equal 10, SampleResource.throttle_interval
    end
    
    should "set the sleep interval" do 
      assert_equal 15, SampleResource.sleep_interval
    end
      
  end
  
  context "Hitting the api at 45 requests per 15 seconds (with a throttle of 45/10)" do 
    setup do 
      @response_xml = [{:id => 1, :name => "Widgy Widget"}].to_xml(:root => "widgets")
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/widgets.xml", {}, @response_xml
        mock.get "/sprockets.xml", {}, @response_xml
        mock.get "/fridgets.xml", {}, @response_xml
      end
    end
    
    should "require more than 20 seconds to make over 90 requests" do 
      @start_time = Time.now
      1.upto(91) { SampleResource.find :all }
      @end_time = Time.now
      assert @end_time - @start_time > 20
    end
    
    context "with multiple subclasses" do 
      setup do 
        class SubSampleResource1 < SampleResource
          self.element_name = "sprocket"
        end
        class SubSampleResource2 < SampleResource
          self.element_name = "fridget"
        end  
      end
      
      should "have the same settings as superclass" do 
        assert_equal 10, SubSampleResource1.throttle_interval
        assert_equal 45, SubSampleResource1.throttle_request_limit
      end
    
      should "require more than 20 seconds to make over 90 requests" do 
        @start_time = Time.now
        1.upto(31) do
          SampleResource.find :all
          SubSampleResource1.find :all
          SubSampleResource2.find :all
        end
        @end_time = Time.now
        assert @end_time - @start_time > 20
      end
    end                
  end

end