# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary Test the printconfig function
# @param targets The targets to run on.
plan boltfunctions::printconfig (
  TargetSpec $targets = 'localhost',
  String $config = 'server',
  String $environment = 'production',
  String $section = 'main',
) {
  #$command_result = boltfunctions::configprint($config,$environment,'main')
  $command_result = boltfunctions::configprint($config)

  return $command_result
}
