#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'
require 'uri'
require 'net/http'
require 'open3'

params = JSON.parse(STDIN.read)
token_path = params['token_path']
nodes = params['nodes']
group_name = params['group_name']

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

def api_call_post(uri, access_token, data)
  url = URI(uri)
  req = Net::HTTP::Post.new(url)
  req['X-Authentication'] = access_token
  req['data'] = data

  res = Net::HTTP.start(
    url.host, url.port,
    :use_ssl => url.scheme == 'https',
    :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |https|

    https.request(req)
  }
  res
end

def get_token(token_path)
  if token_path.nil? || token_path.empty?
    out, st, token = Open3.capture3('/opt/puppetlabs/bin/puppet-access', 'show')
    if st.exitstatus != 0
      raise Puppet::Error.new "Could not get token from puppet-access"
    end
    token = token.strip
  else  
    token = File.read(token_path)
    if token.nil? || token.empty?
      raise Puppet::Error.new "Could not read token from #{token_path}"
    end
  end
  token
end

def get_group_id(token, group_name)
  groups_uri = "https://localhost:4433/classifier-api/v1/groups"
  res = api_call(groups_uri, token)

  data = JSON.parse(res.read_body)

  nodes = []
  ids = []
  
  data.each do |item|
      if item['name'].match(/#{group_name}/)
          nodes.append(item['name'])
          ids.append(item['id'])
      end
  end
  
  if nodes.length == 0
      puts "No nodes found for group #{group_name}"
      exit 1
  end
  
  if nodes.length > 1
      puts "More than one matching node group found for group #{group_name}"
      puts nodes
      exit 1
  end
  
  ids[0]
end

def build_pin_api(groupid)
  pin_api = "https://localhost:4433/classifier-api/v1/groups/#{groupid}/pin"
  pin_api
end

def get_node_names(token, nodes)
  nodes_uri = "http://localhost:8080/pdb/query/v4 --data-urlencode \"query=nodes { certname ~ '#{nodes}' }\""
  res = api_call(nodes_uri, token)

  data = JSON.parse(res.read_body)

  nodes = []

  data.each do |item|
      nodes.append(item['certname'])
  end
  
  if nodes.length == 0
      puts "No nodes found to pin"
      exit 1
  end

  nodes
end

def get_nodes_data(nodes)
  nodes_data = '{ "nodes": [#{nodes}]}'
  nodes_data
end

def pin_nodes(pin_api, token, nodes) 
  nodes_data = get_nodes_data(nodes)
  res = api_call_post(pin_api, token, nodes_data)
  puts res
end

begin

  token = get_token(token_path)

  groupid = get_group_id(token,group_name)

  nodes = get_node_names(token, nodes)

  pin_api = build_pin_api(groupid)

  pin_nodes(pin_api, token, nodes)

rescue Puppet::Error => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end