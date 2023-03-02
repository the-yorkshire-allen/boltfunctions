# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary Test the printconfig function
# @param targets The targets to run on.
plan boltfunctions::getsetting (
  TargetSpec $targets = 'localhost',
  String[1] $setting = 'server',
) {
  $command_result = boltfunctions::getsetting($setting)

  return $command_result
}
