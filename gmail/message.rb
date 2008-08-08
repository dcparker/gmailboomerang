class Message
  include DataMapper::Resource
  property :message_id, String, :key => true
  property :mailbox, Mailbox
  property :noticed, Date

  attr_accessor :uid
  
  def mailbox=(mailbox)
    attribute_set(:mailbox, mailbox)
    @mailbox = mailbox
  end
  def uid
    @uid ||= mailbox.gmail.imap.uid_search(['HEADER', 'Message-ID', message_id])[0]
  end

  LOADED = {}
  class << self
    def [](attrs={})
      raise ArgumentError unless attrs.has_key?(:mailbox) && (attrs.has_key?(:uid) || attrs.has_key?(:message_id))
      message = Message.new(:mailbox => attrs[:mailbox], :uid => attrs[:uid], :message_id => attrs[:message_id])
      return Message::LOADED[message.message_id] if Message::LOADED[message.message_id]
      themessage = if existing = first(:message_id => message.message_id)
        existing.attributes = attrs # Sets the new mailbox in there, but doesn't save it!
        existing
      else
        message
      end
      Message::LOADED[themessage.message_id] = themessage
    end
  end

  # Utility
  def inspect
    "<Message:#{object_id} uid=#{@uid}#{' mailbox='+mailbox.name if mailbox}#{' message_id='+@message_id if @message_id}>"
  end

  # IMAP info
  def message_id
    attribute_get(:message_id) || begin
      mailbox.push do
        attribute_set(:message_id, mailbox.gmail.imap.uid_fetch(@uid, ['ENVELOPE'])[0].attr['ENVELOPE'].message_id)
      end
    end
    attribute_get(:message_id)
  end
  def body
    mailbox.push do
      mailbox.gmail.imap.uid_fetch(uid, "RFC822")[0].attr["RFC822"]
    end
  end

  # IMAP Operations
  def label(name)
    @mailbox.push do |m|
      m.gmail.imap.uid_copy(uid, name)
    end
  end
  def mark(flag)
    @mailbox.push do |m|
      m.gmail.imap.uid_store(uid, "+FLAGS", [flag])
    end
  end
  def unmark(flag)
    @mailbox.push do |m|
      m.gmail.imap.uid_store(uid, "-FLAGS", [flag])
    end
  end
  def mark_read
    mark(:Seen)
  end
  def mark_unread
    unmark(:Seen)
  end
  def delete
    mark(:Deleted)
  end
  def move!(name)
    puts "Moving #{message_id} from #{mailbox.name} to #{name}"
    label(name) && delete
  end

  # Save state
  def notice!
    if dirty? && dirty_attributes.has_key?(properties[:mailbox])
      puts "#{message_id} was moved to #{mailbox.name}"
      self.update_attributes(:message_id => message_id, :mailbox => mailbox, :noticed => Date.parse(4.5.hours.ago.to_s))
    end
  end
end

begin
  Message.first
rescue Sqlite3Error
  Message.auto_migrate!
end
