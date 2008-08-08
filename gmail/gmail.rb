require 'net/imap'

class Gmail
  attr_reader :imap

  def initialize(username, password)
    @imap = Net::IMAP.new('imap.gmail.com',993,true)
    @imap.login(username, password); at_exit { @imap.logout }
  end

  def mailbox(name)
    Mailbox.new(self, name)
  end
  alias :[] :mailbox
  def notice!(message)
    message.notice!
  end

  def selected_stack
    @selected_stack ||= []
  end
  def selected
    selected_stack.empty? ? nil : selected_stack[-1]
  end
  def selected!(mailbox)
    selected_stack.pop
    selected_stack.push(mailbox)
  end
  def selected?(mailbox)
    selected == mailbox
  end

  def push(mailbox, &block)
    selected_stack << mailbox
    if block_given?
      value = block.arity == 1 ? block.call(mailbox) : block.call
      pop
      return value
    else
      mailbox
    end
  end
  def pop
    selected_stack.pop
    selected.select if selected
  end
end

require 'gmail/mailbox'
require 'gmail/message'
