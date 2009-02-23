module Hash::ValidKeys
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - valid_keys
    raise ArgumentError, "Invalid option(s): #{unknown_keys.join(", ")}" unless unknown_keys.empty?
  end
end

class Hash
  include ValidKeys unless defined?(ActiveSupport)

  def assert_required_keys(*required_keys)
    missing_keys = required_keys.select {|key| !keys.include?(key)}
    raise ArgumentError, "Missing required option(s): #{missing_keys.join(", ")}" unless missing_keys.empty?
  end
end

