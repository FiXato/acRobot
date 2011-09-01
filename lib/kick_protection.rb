#!/usr/bin/env ruby
#encoding: UTF-8
require 'cinch'

class KickProtection
  include Cinch::Plugin

  listen_to :kick
  def listen(m)
    unless m.user.nick == bot.nick
      bot.join(m.channel.name)
      sleep 2
      m.reply "Why'd you do that #{m.user.nick} :'("
    end
  end
end