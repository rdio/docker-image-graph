#! /usr/local/bin/ruby
require 'open3'
require 'docker'

sizelists = Hash.new()
childlists = Hash.new() { |h,k| h[k]=[] }
parents = {}

dot_file = []
dot_file << 'digraph docker {'

Docker::Image.all(all: true).each do |image|

  id = image.id[0..11]
  tags = image.info['RepoTags'].reject { |t| t == '<none>:<none>' }.join('\n')
  parent_id = image.info['ParentId'][0..11]
  size = image.info["VirtualSize"]
  sizelists[id.to_sym] = size
  parents[id] = parent_id

  if parent_id.empty?
    dot_file << "base -> \"#{id}\" [style=invis]"
  else
    dot_file << "\"#{parent_id}\" -> \"#{id}\""
  end

  childlists[parent_id].push id

  if !tags.empty?
    dot_file << "\"#{id}\" [label=\"#{id}\\n#{tags}\\n%{#{id}}MiB\n(Virtual: #{size / 1024.0}MiB)\",shape=box,fillcolor=\"paleturquoise\",style=\"filled,rounded\"];"
  else
    dot_file << "\"#{id}\" [label=\"#{id}\\n%{#{id}}MiB\"];"
  end

end

dot_file << 'base [style=invisible]'
dot_file << '}'

parents.keys.each { |k| childlists[k] } #iterate to make sure we have empty children

until childlists.empty?
  childlists.delete_if do |k, v|
    if v.empty?
      sizelists[k.to_sym] = ( sizelists[k.to_sym] - sizelists[parents[k].to_sym] ) / 1024.0 rescue 0
      childlists.each do |rk,rv|
        rv.delete(k)
      end
    end
    v.empty?
  end
end

dot_file = dot_file.join("\n") % sizelists

Open3.popen3('/usr/bin/dot -Tsvg') do |stdin, stdout, stderr|
  stdin.puts(dot_file)
  stdin.close
  STDOUT.write stdout.read
  STDERR.write stderr.read
end
