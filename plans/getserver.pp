# This is the structure of a simple plan. To learn more about writing
# Puppet plans, see the documentation: http://pup.pt/bolt-puppet-plans

# The summary sets the description of the plan that will appear
# in 'bolt plan show' output. Bolt uses puppet-strings to parse the
# summary and parameters from the plan.
# @summary Test the getserver and getsetting functions
# @param targets The targets to run on.
plan boltfunctions::getserver (
  TargetSpec $targets = 'localhost',
) {
  $server1 = boltfunctions::getserver()
  $server2 = boltfunctions::getsetting('server')

  return "${server1} ${server2}"
}
