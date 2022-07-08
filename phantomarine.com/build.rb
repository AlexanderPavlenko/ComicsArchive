#!/usr/bin/env ruby

require 'shellwords'
require 'set'
require 'uri'

TITLE = "phantomarine.com"
SITE = "https://www.phantomarine.com"
index, FIRST = 1, URI("#{SITE}/comic/01-the-horizon-line")
#index, FIRST = 279, URI("#{SITE}/comic/597-the-two")
LAST = URI("#{SITE}/comic/598-unmentionable")
url = FIRST

VISITED = Set.new
#TMP = "/Volumes/RAM/page"
TMP = "page"

def image(index, url)
  xpath = %(//img[@id="cc-comic"][1]/@src)
  src =`hq -f #{TMP} '#{xpath}'`.strip[5..-2]
  dest ="#{TITLE}/#{index.to_s.rjust(4, '0')}_#{url.path.split(?/).last}#{File.extname(src)}"
  [ src, dest ]
end

def next_url(index)
  xpath = %(//a[@rel="next"][1]/@href)
  URI(`hq -f #{TMP} '#{xpath}'`.strip[6..-2])
end

def curl(src, dest)
  url = src.to_s.gsub(' ', '%20')
  success = system %(curl -Ls #{Shellwords.escape(url)} -o #{Shellwords.escape(dest)})
  fail unless success
end

system %(rm -f #{TITLE}.cbz; mkdir -p #{TITLE})

loop do
  puts url
  curl(url, TMP)
  src, dest = image(index, url)
  if File.exists?(dest)
    puts "#{dest}: already exists"
  else
    puts "#{dest}: #{src}"
    curl(src, dest)
  end
  VISITED << url.path
  break if url.path == LAST.path
  url = next_url(index)
  break if VISITED.include?(url.path)
  index += 1
end

system %(zip -r #{TITLE}.cbz #{TITLE})
