# frozen_string_literal: true

require 'bolt/error'

# Return the output of print config
Puppet::Functions.create_function(:'boltfunctions::getsetting') do
  # @param setting The setting to return.
  # @return The setting value.
  # @example Get the server name
  #   boltfunctions::getsetting('server')
  dispatch :getsetting do
    required_param 'String[1]', :setting
    return_type 'String'
  end

  def getsetting(setting)
    # Send Analytics Report
    Puppet.lookup(:bolt_executor) {}&.report_function_call(self.class.name)
    
    result = Puppet.settings["#{setting}".to_sym]

    # return the stdout from the command
    response = 
      if result.kind_of?(Array)
        result.join
      else
        result
      end
    response
  end
end
