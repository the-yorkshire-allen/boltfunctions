require 'json'

raw_data = File.read('classifier.json')
data = JSON.parse(raw_data)

group_name=ARGV[0]

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

puts ids[0], nodes[0]