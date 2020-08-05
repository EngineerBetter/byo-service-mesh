#!/usr/bin/env ruby

require 'yaml'

manifest = YAML.load(File.read("manifest.yml"))

apps = manifest['applications'].map do |app|
  app['name']
end
apps.each do |app|
  system "cf add-network-policy #{app} #{app} --port 8000-9000 --protocol tcp"
end
apps.permutation(2) do |perm|
  system "cf add-network-policy #{perm[0]} #{perm[1]} --port 8000-9000 --protocol tcp"
  system "cf add-network-policy #{perm[0]} #{perm[1]} --port 8301-8302 --protocol udp"
end
