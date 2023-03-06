# frozen_string_literal: true

require 'open3'
require 'bolt/error'

# Return the output of print config
Puppet::Functions.create_function(:'boltfunctions::crudini') do
  # @param config The config file to process.
  # @param section The section of the config file.
  # @param param The parameter of the section.
  # @return The config value.
  # @example Print the server name
  #   boltfunctions::crudini('/etc/puppetlabs/puppet/puppet.conf', 'main', 'server')
  dispatch :crudini do
    required_param 'String[1]', :config
    required_param 'String[1]', :section
    required_param 'String[1]', :param
    return_type 'String'
  end

  def command(command, arguments = [])
    stdout, stderr, p = Open3.capture3(command, *arguments)
    {
      stdout: stdout,
      stderr: stderr,
      exit_code: p.exitstatus
    }
  end

  def validateparameter(parameter)
    if !parameter.nil?
      parameter_string = parameter.dup
      parameter_string.gsub!(/[^A-Za-z_\/\.]/, '')

      # return cleaned parameter
      parameter_string
    else
      # return empty string
      ''
    end
  end

  def crudini(config, section, param)
    # Send Analytics Report
    Puppet.lookup(:bolt_executor) {}&.report_function_call(self.class.name)

    # Remove any characters from the parameters other than uppercase and lowercase letters
    config_string = validateparameter(config)
    section_string = validateparameter(section)
    param_string = validateparameter(param)
    
    command_string = "crudini --get #{config_string} #{section_string} #{param_string}".rstrip
    begin
      result = command(command_string)

      if result[:exit_code] != 0
        raise Bolt::Error.new("Could not extract parameter: #{result[:stderr]}", "bolt/invalid-plan")
      end

      # remove any trailing whitespace
      result[:stdout].strip.delete_prefix('"').delete_suffix('"')

    rescue StandardError => e
      raise Bolt::Error.new("Could not execute commmand: #{e.message} #{command_string}", "bolt/invalid-plan")
    end
  end
end
