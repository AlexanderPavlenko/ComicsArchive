#!/usr/bin/env ruby

require 'shellwords'
require 'set'
require 'uri'

TITLE = "sparkscomic.net"
SITE = "https://sparkscomic.net"
#index, FIRST = 1, URI("#{SITE}/?comic=sparks-book-1")
index, FIRST = 261, URI("#{SITE}/?comic=sparks-258")
LAST = URI("#{SITE}/?comic=sparks-260")
url = FIRST

VISITED = Set.new
TMP = "/Volumes/RAM/page"
#TMP = "page"
RACTORS = []

def image(index, url)
  xpath = %(//div[@id="comic"][1]//img/@src)
  
  src = URI(`hq -f #{TMP} '#{xpath}'`.strip[5..-2])
  src.query = nil
  
  #id = url.path.split(?/).last
  id = Hash[URI.decode_www_form(url.query)]['comic']
  ext = File.extname(src.to_s)
  dest = "#{TITLE}/#{index.to_s.rjust(4, '0')}_#{id}#{ext}"
  
  [src, dest]
end

def next_url(index)
  xpath = %(//a[@class="comic-nav-base comic-nav-next"][1]/@href)
  
  URI(`hq -f #{TMP} '#{xpath}'`.strip[6..-2])
end

def url_id(url)
  "#{url.path}?#{url.query}"
end

def curl(src, dest)
  url = src.to_s.gsub(' ', '%20')
  cmd = %(curl -Ls #{Shellwords.escape(url)} -o #{Shellwords.escape(dest)})
  success = system(cmd)
  unless success
    puts "Failed: #{cmd}"
    fail
  end
end

def download_image(src, dest)
  if File.exists?(dest)
    puts "Image #{dest}: already exists"
  else
    RACTORS << Ractor.new(src, dest) do |src, dest|
      puts "Image #{dest}: #{src}"
      curl(src, dest)
    end
  end
end

system %(rm -f #{TITLE}.cbz; mkdir -p #{TITLE})

loop do
  puts "Page: #{url}"
  curl(url, TMP)
  download_image(*image(index, url))
  VISITED << url_id(url)
  break if url_id(url) == url_id(LAST)
  url = next_url(index)
  break if VISITED.include?(url_id(url))
  index += 1
end

puts "Waiting for all downloads to finish..."
RACTORS.each(&:take)

system %(zip -r #{TITLE}.cbz #{TITLE})
