#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'
require 'date'

require 'colorize'
require 'pry'
require 'csv'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko(url)
  Nokogiri::HTML(open(url).read) 
end

def datefrom(date)
  Date.parse(date)
end

@BASE = 'http://www.assemblee.ne'
url = @BASE + '/index.php/organes/les-groupes-parlementaires'

page = noko(url)
page.xpath('//table[.//tr[contains(.,"Membres")]]//tr').drop(1).each do |party|
  tds = party.css('td')
  party_name = tds.first.text.strip
  member_count = tds[2].text.gsub(/[[:space:]]/, ' ').strip.to_i
  party_url = @BASE + tds.last.css('a/@href').text

  member_page = noko(party_url)
  mps = member_page.css('.article-content li')
  mps = member_page.css('.article-content p') if mps.count.zero?
  raise "Should have #{member_count} MPs; have #{mps.count}" unless mps.count == member_count
  mps.each do |mp|
    data = { 
      name: mp.text.gsub(/^\d+\.\s*/,'').upcase,
      party: party_name,
      party_name: party_url.split('/').last[/^(\d+)/, 1], 
      gender: 'male',
      term: '7.1',
      source: party_url,
    }
    data[:gender] = 'female' if data[:name].gsub!(' (MME)', '')
    puts data
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end
