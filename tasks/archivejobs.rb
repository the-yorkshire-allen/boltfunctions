#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'
require 'uri'
require 'net/http'

params = JSON.parse(STDIN.read)
token_path = params['token_path']
archive_directory = params['archive_directory']
plan_jobs_api = params['plan_jobs_api']
jobs_api = params['jobs_api']

def api_call(uri, access_token)
  url = URI(uri)
  req = Net::HTTP::Get.new(url)
  req['X-Authentication'] = access_token

  res = Net::HTTP.start(
    url.host, url.port,
    :use_ssl => url.scheme == 'https',
    :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |https|

    https.request(req)
  }
  res
end

def write_file(filename, filepath, content)
  File.write(filepath+filename, content)
end

begin
  unless File.directory?(archive_directory)
    raise Puppet::Error.new "Archive directory '#{archive_directory}' does not exist"
  end

  token = File.read(token_path)

  res = api_call(plan_jobs_api, token)

  body = JSON.parse(res.read_body)

  body['items'].each do |item|
    itemres = api_call(item['events']['id'], token)
    item['event_data'] = JSON.parse(itemres.read_body)
    write_file("plan-#{item['name']}", archive_directory, item.to_json)
  end

#  puts body.to_json

  res = api_call(jobs_api, token)

  body = JSON.parse(res.read_body)

  body['items'].each do |item|
    itemres = api_call(item['events']['id'], token)
    item['event_data'] = JSON.parse(itemres.read_body)

    itemres = api_call(item['report']['id'], token)
    item['report_data'] = JSON.parse(itemres.read_body)

    itemres = api_call(item['nodes']['id'], token)
    item['nodes_data'] = JSON.parse(itemres.read_body)

    write_file("job-#{item['name']}-#{item['type']}", archive_directory, item.to_json)
  end

  exit 0
rescue Puppet::Error => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end