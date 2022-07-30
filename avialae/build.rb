#!/usr/bin/env ruby

require 'shellwords'
require 'set'
require 'uri'

TITLE = "Avialae"
SITE = "https://yaoi.biz"
#index, FIRST = 1, URI("#{SITE}/avialae/chapter-1/page-0")
index, FIRST = 742, URI("#{SITE}/avialae/chapter-6/page-156")
LAST = URI("#{SITE}/avialae/chapter-6/page-170")
url = FIRST

VISITED = Set.new
TMP = "/Volumes/RAM/page"
#TMP = "page"

def image(index, url)
  xpath = %(//img[@class="avialae-page"][1]/@src)
  src = `hq -f #{TMP} '#{xpath}'`.strip[5..-2]
  if src[0] == ?/
    src = SITE + src
  end
  dest ="#{TITLE}/#{index.to_s.rjust(4, '0')}_#{url.path.split(?/).last}#{File.extname(src)}"
  [src, dest]
end

PAGES = {
  1 => 0..77,
  2 => 0..123,
  3 => 0..107,
  4 => 0..123,
  5 => 0..150,
  6 => 0..170,
}.flat_map { |k, v| ([k] * v.size).zip(v) }

# @param index [Integer] current page, starts from 1
def next_url(index)
  fail if index >= PAGES.size
  chapter, page = PAGES[index]
  URI("#{SITE}/avialae/chapter-#{chapter}/page-#{page}")
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
