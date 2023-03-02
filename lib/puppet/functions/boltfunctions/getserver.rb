# frozen_string_literal: true

require 'bolt/error'

# Return the output of print config
Puppet::Functions.create_function(:'boltfunctions::getserver') do
  # @return The PE server
  # @example Get the PE Server
  #   boltfunctions::getserver()
  dispatch :getserver do
    return_type 'String'
  end

  def getserver()
    # Send Analytics Report
    Puppet.lookup(:bolt_executor) {}&.report_function_call(self.class.name)
    
    Puppet.settings[:server]
  end
end
