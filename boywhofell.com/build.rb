#!/usr/bin/env ruby

require 'shellwords'
require 'set'
require 'uri'

VISITED = Set.new
TMP = "page" # or "/Volumes/RAM/page"
TITLE = "boywhofell.com"
SITE = "https://www.boywhofell.com"
FIRST = URI("#{SITE}/comic/ch00p00") # 1
#FIRST = URI("#{SITE}/comic/ch6111") # 1470
LAST = URI("#{SITE}/comic/ch6112")
index = 1
url = FIRST

def image(index, url)
  xpath = "/html/body/div[2]/div[2]/div[2]/#{ url == LAST ? nil : 'a/'}img/@src"
  src =`hq -f #{TMP} '#{xpath}'`.strip[5..-2]
  dest ="#{TITLE}/#{index.to_s.rjust(4, '0')}_#{url.path.split(?/).last}#{File.extname(src)}"
  [ src, dest ]
end

def next_url(index)
  xpath = "/html/body/div[2]/div[2]/div[3]/nav/a[#{ index == 1 ? 2 : 4}]/@href"
  URI(`hq -f #{TMP} '#{xpath}'`.strip[6..-2])
end

def curl(src, dest)
  url = src.to_s.gsub(' ', '%20')
  success = system %(curl -s #{Shellwords.escape(url)} -o #{Shellwords.escape(dest)})
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
  VISITED << url
  break if url == LAST
  url = next_url(index)
  break if VISITED.include?(url)
  index += 1
end

system %(zip -r #{TITLE}.cbz #{TITLE})
