class Mailbox < DataMapper::Type
  primitive String
  size 25

  LOADED = {}
  class << self
    def new(gmail, name)
      obj = self[name]
      return obj if obj

      obj = allocate
      obj.send(:initialize, gmail, name)
      return obj
    end
    def [](name)
      Mailbox::LOADED[name]
    end
    def load(name, mailbox_property)
      # puts "Loading #{name.inspect} into #{mailbox_property.inspect}"
      Mailbox[name]
    end
    def dump(mailbox, mailbox_property)
      # puts "Dumping #{mailbox.inspect} from #{mailbox_property.inspect}: #{mailbox.name if mailbox}"
      mailbox ? mailbox.name : nil
    end
  end

  attr_reader :gmail, :name

  # Utility
  def initialize(gmail, name)
    @gmail = gmail
    @name = name.is_a?(Symbol) ? name.to_s.upcase : name
    Mailbox::LOADED[@name] = self
  end
  def inspect
    "<Mailbox:#{object_id} name=#{@name} selected=#{@gmail.selected?(self)}>"
  end
  def to_s
    name
  end

  # IMAP Navigation
  def select
    unless @gmail.selected?(self)
      @gmail.imap.select(@name)
      @gmail.selected!(self)
    end
    self
  end
  def select!
    begin
      select
    rescue Net::IMAP::NoResponseError => e
      if e.inspect =~ /Unknown Mailbox:/
        @gmail.imap.create(@name)
        select
      else
        raise
      end
    end
  end
  def examine
    unless @gmail.selected?(self)
      @gmail.imap.examine(@name)
      @gmail.selected!(self)
    end
    self
  end
  def push(&block)
    @gmail.imap.select(@name) unless @gmail.selected?(self)
    @gmail.push(self, &block)
  end
  def pop
    @gmail.pop
  end

  # Operations on the mailbox
  def [](message_id)
    push do
      @gmail.imap.uid_search(['HEADER', 'Message-ID', message_id]).collect { |uid| Message[:mailbox => self, :uid => uid, :message_id => message_id] }
    end[0]
  end
  def messages(key=:all)
    aliases = {
      :all => ['ALL'],
      :unread => ['UNSEEN'],
      :read => ['SEEN']
    }
    puts "Gathering #{key} messages for mailbox '#{name}'..."
    push do
      @gmail.imap.uid_search(aliases[key]).collect { |uid| Message[:mailbox => self, :uid => uid] }
    end
  end
end
