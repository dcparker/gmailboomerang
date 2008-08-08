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

require 'days_and_times'
today = Date.today.strftime("%Y%m%d")

# Scan all boxes, inspect each message for action.
notice_and_move = lambda do |message|
  # Notice messages (records date-time noticed, when in a new box)
  message.notice!
  # Move from Tomorrow to Inbox if it is hitback day or after
  message.move!('Inbox') if message.mailbox == Mail['Tomorrow'] && today > message.noticed.strftime("%Y%m%d")
  # Move from Next Week to Tomorrow if it is one day or less away from its hitback day
  message.move!('Tomorrow') if message.mailbox == Mail['Next Week'] && today > (message.noticed + 6).strftime("%Y%m%d")
  # Move from Next Month to Next Week if it is a week or less away from its hitback day
  message.move!('Next Week') if message.mailbox == Mail['Next Month'] && today > (message.noticed + 23).strftime("%Y%m%d")
end

Mail['Inbox'].messages.each {|m| notice_and_move.call(m) }
Mail['Tomorrow'].messages.each {|m| notice_and_move.call(m) }
Mail['Next Week'].messages.each {|m| notice_and_move.call(m) }
Mail['Next Month'].messages.each {|m| notice_and_move.call(m) }
