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
    begin
      stdout, stderr, p = Open3.capture3(command, *arguments)
      {
        stdout: stdout,
        stderr: stderr,
        exit_code: p.exitstatus
      }
    rescue => e
      raise Bolt::Error.new("Could not execute command: #{e}", "bolt/invalid-plan")
    end
  end

  def validateparameter(parameter, option = nil)
    if !parameter.nil?
      prefix =
        if !option.nil?
          "--#{option} " 
        else
          ''
        end

      parameter_string = parameter.dup
      parameter_string.gsub!(/[^A-Za-z]/, '')

      # return concatenated string
      prefix + parameter_string
    else
      # return empty string
      ''
    end
  end

  def configprint(config, environment = nil, section = nil)
    # Send Analytics Report
    Puppet.lookup(:bolt_executor) {}&.report_function_call(self.class.name)
    
    begin
      # Remove any characters from the parameters other than uppercase and lowercase letters
      config_string = validateparameter(config)
      environment_string = validateparameter(environment, 'environment')
      section_string = validateparameter(section, 'section')

      command_string = "sudo puppet config print #{config_string} #{environment_string} #{section_string}".rstrip

      result = command(command_string)

      if result[:exit_code] != 0
        raise Bolt::Error.new("Could not print config: #{result[:stderr]}", "bolt/invalid-plan")
      end

      # return the stdout from the command
      response = 
        if result[:stdout].kind_of?(Array)
          # if the stdout is an array, join it with a comma
          result[:stdout].join(',')
        else
          result[:stdout]
        end
      # remove any trailing whitespace
      response.strip
    rescue StandardError => e
      raise Bolt::Error.new("Could not execute command: #{e.message} #{command_string}", "bolt/invalid-plan")
    end
  end
end
