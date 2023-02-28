# frozen_string_literal: true

require 'open3'
require 'bolt/error'

# Return the output of print config
Puppet::Functions.create_function(:'boltfunctions::configprint') do
  # @param config The config that requires printing.
  # @return The config value.
  # @example Print the server name
  #   boltfunctions::configprint('server')
  dispatch :configprint do
    required_param 'String', :config
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

    # Remove leading '--' if present to prevent options being called as config
    config.delete! '--'

    environment_string =
      if !environment.nil?
        environment.delete! '--'
        '--environment #{environment}'
      else
        ''
      end

    section_string =
      if !section.nil?
        section.delete! '--'
        '--section #{section}'
      else
        ''
      end

    command_string = "puppet config print #{config} #{environment_string} #{section_string}"

    result = command(command_string)

    if result[:exit_code] != 0
      raise Bolt: Error.new("Could not print config: #{result[:stderr]}")
    end

    result[:stdout].chomp
  end
end
