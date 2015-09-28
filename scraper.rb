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

def scrape_page(url)
  page = noko(url)
  page.xpath('//table[.//tr[contains(.,"Groupes Parlemenataires")]]//tr').drop(1).each do |party|
    tds = party.css('td')
    party_name = tds.first.text.strip
    member_count = tds[2].text.gsub(/[[:space:]]/, ' ').strip.to_i
    party_url = URI.join(url, tds.last.css('a/@href').text).to_s
    scrape_party(party_url, party_name, member_count)
  end
end

def scrape_party(party_url, party_name, member_count)
  warn party_url
  member_page = noko(party_url)
  mps = member_page.css('.article-content li')
  mps = member_page.css('.article-content p') if mps.count.zero?
  warn "#{party_url} should have #{member_count} MPs; have #{mps.count}" unless mps.count == member_count
  mps.each do |mp|
    data = { 
      name: mp.text.gsub(/^\d+\.\s*/,'').upcase,
      party: party_name,
      party_id: CGI.parse(URI.parse(party_url).query)['id'].first,
      gender: 'male',
      term: '7.1',
      source: party_url,
    }
    data[:gender] = 'female' if data[:name].gsub!(' (MME)', '')
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

scrape_page 'http://www.assemblee.ne/index.php?option=com_content&view=article&id=165&Itemid=154'
