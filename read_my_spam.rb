#!ruby

# GmailBoomerang - manages your gmail labels Tomorrow, Next Week, and Next Month

require 'rubygems'
$:.unshift(File.dirname(__FILE__))

require 'yaml'
@config = YAML.load_file("#{File.expand_path(File.dirname(__FILE__))}/config.yaml")

require 'dm-core'
DataMapper.setup(:default, "sqlite3://#{File.expand_path(File.dirname(__FILE__))}/cache.sqlite3")

require 'gmail/gmail'
Mail = Gmail.new(@config[:username], @config[:password])

# Mark all spam messages as read -- without actually reading them. Just to keep the spam count number from annoying me.
Mail['[Gmail]/Spam'].messages(:unread).each do |spam|
  spam.mark(:Seen)
end
