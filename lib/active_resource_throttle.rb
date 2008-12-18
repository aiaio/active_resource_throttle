$:.unshift File.join(File.dirname(__FILE__), "active_resource_throttle")
require "hash_ext"
module ActiveResourceThrottle
  VERSION = "1.0.0"
  
  # Add class inheritable attributes.
  # See John Nunemaker's article at
  # http://railstips.org/2008/6/13/a-class-instance-variable-update
  module ClassInheritableAttributes
    def cattr_inheritable(*args)
      @cattr_inheritable_attrs ||= [:cattr_inheritable_attrs]
      @cattr_inheritable_attrs += args
      args.each do |arg|
        class_eval %(
          class << self; attr_accessor :#{arg} end
        )
      end
      @cattr_inheritable_attrs
    end

    def inherited(subclass)
      @cattr_inheritable_attrs.each do |inheritable_attribute|
        instance_var = "@#{inheritable_attribute}" 
        subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
      end
    end
  end
  
  module ClassMethods
    include ClassInheritableAttributes
    
    # Getter method for sleep interval.
    #   Person.sleep_interval  # => 15
    def sleep_interval
      @sleep_interval
    end
    
    # Getter method for throttle interval.
    #   Person.throttle_interval  # => 60
    def throttle_interval
      @throttle_interval
    end
    
    # Getter method for throttle request limit.
    #   Person.throttle_request_limit  # => 10  
    def throttle_request_limit
      @throttle_request_limit
    end
    
    # Getter method for request history.
    #   Person.request_history  # => [Tue Dec 16 17:35:01 UTC 2008, Tue Dec 16 17:35:03 UTC 2008]
    def request_history
      @request_history
    end
    
    # Sets throttling options for the given class and
    # all subclasses.
    #   class Person < ActiveResource::Base
    #     throttle(:interval => 60, :requests => 15, :sleep_interval => 10)
    #   end
    # Note that the _sleep_interval_ argument is optional.  It will default
    # to 5 seconds if not specified.
    def throttle(options={})
      options.assert_valid_keys(:interval, :requests, :sleep_interval)
      options.assert_required_keys(:interval, :requests)
      @throttle_interval      = options[:interval]
      @throttle_request_limit = options[:requests]
      @sleep_interval         = options[:sleep_interval] || 5
      @request_history        = []
    end
        
    # Interrupts connection requests only if 
    # throttle is engaged.
    def connection_with_throttle(refresh = false)
      throttle_connection_request if throttle_engaged? && base_class?
      connection_without_throttle(refresh)
    end
    
    protected
      
      # This method does most of the work.
      # If the request history excedes the limit,
      # it sleeps for the specified interval and retries.
      def throttle_connection_request
        trim_request_history
        while request_history.size >= throttle_request_limit do
          sleep sleep_interval
          trim_request_history
        end
        request_history << Time.now
      end
      
      # The request history is an array that stores
      # a timestamp for each request. This trim method
      # removes any elements occurring before
      # Time.now - @throttle_interval.  Thus, the number
      # of elements signifies the number of requests in the allowed interval.
      def trim_request_history
        request_history.delete_if do |request_time|
          request_time < (Time.now - throttle_interval)
        end
      end
      
      # Throttle only if an interval and limit have been specified.
      def throttle_engaged?
        defined?(@throttle_interval) && defined?(@throttle_request_limit) &&
        throttle_interval.to_i > 0 && throttle_request_limit.to_i > 0
      end
      
      # Is this the class from which a connection will originate?
      # See ActiveResource::Base.connection method for details. 
      def base_class?
        defined?(@connection) || superclass == Object
      end
      
      
  end
    
  # Callback invoked when ActiveResourceThrottle
  # is included in a class.  Note that the class
  # must implement a *connection* class method for this
  # to work (e.g, is an instance of ActiveResource::Base).
  def self.included(klass)
    if klass.respond_to?(:connection)
      klass.instance_eval do      
        extend ClassMethods
        cattr_inheritable :sleep_interval, 
                          :throttle_interval, 
                          :throttle_request_limit,
                          :request_history
        class << klass
          alias_method :connection_without_throttle, :connection
          alias_method :connection, :connection_with_throttle  
        end
      end
    else
      raise StandardError, "Cannot include throttle if class doesn't include a #connection class method."
    end 
  end
  
end