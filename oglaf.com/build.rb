#!/usr/bin/env ruby

require 'shellwords'
require 'set'

system %(rm -f oglaf.com.cbz; mkdir -p oglaf.com)

site = "https://www.oglaf.com"
index = 1
page = "/cumsprite/"
#index = 868
#page = "/hardwood/"
visited = Set.new
#tmp = "/Volumes/RAM/page"
tmp = "page"
loop do
  puts page
  system %(curl -s #{Shellwords.escape(site + page)} > #{tmp})
  image = `hq -f #{tmp} '/html/body/div/div[5]/b/img/@src'`.strip[5..-2]
  file = "oglaf.com/#{index.to_s.rjust(4, '0')}_#{page[1..-2].tr('/','_')}#{File.extname(image)}"
  if File.exists?(file)
    puts "already exists: #{file}"
  else
    puts image
    system %(curl -s #{Shellwords.escape(image)} -o #{file})
  end
  visited << page
  next_page = `hq -f #{tmp} '/html/body/div/div[5]/div[2]/a[3]/@href'`.strip[6..-2]
  break if visited.include?(next_page) # on last page next_page is actually previous page
  page = next_page
  index += 1
end

system %(zip -r oglaf.com.cbz oglaf.com)
