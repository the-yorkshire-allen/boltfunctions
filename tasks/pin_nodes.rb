#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'
require 'uri'
require 'net/http'
require 'open3'

params = JSON.parse(STDIN.read)
token_path = params['token_path']
nodes_search = params['nodes']
group_name = params['group_name']
ssl_verify = params['ssl_verify']

class HttpConnection
  def get(url, headers = nil, params = nil, verify = true)
    url = URI.parse(url.to_s)
    url.query = URI.encode_www_form(params) if params
    request = Net::HTTP::Get.new(url.to_s)

    request = add_headers(request, headers) if headers

    http_request(request, verify)
  end

  def post(url, headers = nil, params = nil, verify = true)
    request = Net::HTTP::Post.new(url)
    request.body = URI.encode_www_form(params) if params

    request = add_headers(request, headers) if headers
    request.content_type = 'application/json'

    puts request.body
    puts request.to_hash

    http_request(request, verify)
  end

  private def add_headers(request, headers)
    headers.each do | key, value |
        request[key] = value
    end

    request
  end

  private def http_request(request, verify)
    if verify
        verify_mode = OpenSSL::SSL::VERIFY_PEER
    else
        verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    uri = URI.parse(request.path)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", verify_mode: "#{verify_mode}".to_i) { |http|
      http.set_debug_output($stdout)    
      http.request(request)
    }
  end
end

def get_token(token_path)
  if token_path.nil? || token_path.empty?
    token, err, s = Open3.capture3('/opt/puppetlabs/bin/puppet-access', 'show')
    if s.exitstatus != 0
      puts "Could not get token from puppet-access"
    end
    token = token.strip
  else
    token = File.read(token_path)
    if token.nil? || token.empty?
      puts "Could not read token from #{token_path}"
    end
  end
  token
end

def get_group_id(response, group_name)

  data = JSON.parse(response.read_body)

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

def get_node_names(response)

  data = JSON.parse(response.read_body)

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

def validate_repsonse(response)
  case response
    when Net::HTTPSuccess
      #puts JSON.parse response.body
      puts "Success"
      puts response.message
    when Net::HTTPUnauthorized
      puts "#{response.message}: username and password set and correct?"
    when Net::HTTPServerError
      puts "#{response.message}: try again later?"
    else
      puts response.message
  end
end

token = get_token(nil)

http_conn = HttpConnection.new

params = {query: 'nodes[certname] { certname ~ "' + nodes_search + '" }'}
headers = {"X-Authentication" => "#{token}", "Content-Type" => "application/json"}
query_uri = "http://localhost:8080/pdb/query/v4"
response = http_conn.get(query_uri, headers, params, ssl_verify)
validate_repsonse(response)
nodes = get_node_names(response)

puts nodes

groups_uri = "https://localhost:4433/classifier-api/v1/groups"
response = http_conn.get(groups_uri, headers, nil, ssl_verify)
validate_repsonse(response)
groupid = get_group_id(response, group_name)

puts groupid

pin_uri = "https://localhost:4433/classifier-api/v1/groups/#{groupid}/pin"
puts pin_uri
params = {"nodes" => nodes.join(",")}

puts params

response = http_conn.post(pin_uri, headers, params, ssl_verify)
validate_repsonse(response)




