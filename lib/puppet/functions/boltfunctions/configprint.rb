# frozen_string_literal: true

require 'open3'
require 'bolt/error'

# Return the output of print config
Puppet::Functions.create_function(:'boltfunctions::configprint') do
  # @param config The config that requires printing.
  # @param environment The environment to use.
  # @param section The section to use.
  # @return The config value.
  # @example Print the server name
  #   boltfunctions::configprint('server')
  dispatch :configprint do
    required_param 'String[1]', :config
    optional_param 'String', :environment
    optional_param 'String', :section
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

  def configprint(config, environment = nil, section = nil)
    # Send Analytics Report
    Puppet.lookup(:bolt_executor) {}&.report_function_call(self.class.name)

    # Remove any characters from the parameters other than uppercase and lowercase letters
    config_string = config.dup
    config_string.gsub!(/[^A-Za-z]/, '')

    environment_string =
      if !environment.nil?
        c_environment = environment.dup
        c_environment.gsub!(/[^A-Za-z]/, '')
        "--environment #{c_environment}"
      else
        ''
      end

    section_string =
      if !section.nil?
        c_section = section.dup
        c_section.gsub!(/[^A-Za-z]/, '')
        "--section #{c_section}"        
      else
        ''
      end

    command_string = "puppet config print #{config_string} #{environment_string} #{section_string}".rstrip

    result = command(command_string)

    if result[:exit_code] != 0
      raise Bolt::Error.new("Could not print config: #{result[:stderr]}")
    end

    result[:stdout].strip
  end
end
