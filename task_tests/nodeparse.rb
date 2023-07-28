require 'json'

raw_data = File.read('nodes.json')
data = JSON.parse(raw_data)

nodes = []

data.each do |item|
    nodes.append(item['certname'])
end

if nodes.length == 0
    puts "No nodes found to pin"
    exit 1
end

puts nodes