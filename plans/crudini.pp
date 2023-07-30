# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary Test the printconfig function
# @param targets The targets to run on.
plan boltfunctions::crudini (
  TargetSpec $targets = 'localhost',
  String[1] $config = '/etc/puppetlabs/puppet/puppet.conf',
  String[1] $section = 'main',
  String[1] $param = 'server',
) {
  $command_result = boltfunctions::crudini($config,$section,$param)

  return $command_result
}
