#!/usr/bin/env ruby
#encoding: UTF-8
lib_path = File.join(File.dirname(__FILE__),'..','lib')
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
require 'acro_bot'
require 'kick_protection'
require 'yaml'

ACRO_CONFIG_PATH = File.expand_path(ARGV.size > 0 ? ARGV[0] : "~/.acro_bot_config.yaml")
if File.exist?(ACRO_CONFIG_PATH)
  CONFIG = YAML.load_file(ACRO_CONFIG_PATH)
else
  SAMPLE_CONFIG = {
    :default_network_config => {
      :nick => 'acRobot',
      :user => 'acRobot',
      :realname => "FiXato's Acro bot written in Ruby using Cinch",
      :verbose => true,
      :ssl => {:use => true},
    },
    :networks => {
      'Freenode' => {
        :enabled => false,
        :server => 'irc.freenode.net',
        :port   => '6697',
        :channels => ['#cinch-bots'],
        :password => '',
      },
      'Chat4All' => {
        :enabled => false,
        :nick => 'acRo-alt',
        :user => 'acRo',
        :realname => "FiXato's Acro bot written in Ruby using the Cinch library",
        :verbose => false,
        :server => 'irc.chat4all.org',
        :port   => '7001',
        :channels => [],
        :password => '',
      },
    },
  }
  puts "#{ACRO_CONFIG_PATH} does not exist. Will create it now with the following sample config:", SAMPLE_CONFIG.to_yaml
  File.open(ACRO_CONFIG_PATH,"w"){|f|f.write YAML.dump(SAMPLE_CONFIG)}
  abort("Config saved. Please open '#{ACRO_CONFIG_PATH}' and configure it before restarting the bot")
end

NETWORKS = CONFIG[:networks]
DEFAULT_NETWORK_CONFIG = CONFIG[:default_network_config]

@bots = []
NETWORKS.each do |network,options|
  next unless options.delete(:enabled)
  @bots << Cinch::Bot.new do
    configure do |config|
      DEFAULT_NETWORK_CONFIG.merge(options).each do |key, value|
        if value.kind_of?(Hash)
          value.each do |subkey,subvalue|
            config.send(key).send("#{subkey}=", subvalue)
          end
          next
        end
        config.send("#{key}=", value)
      end
      config.plugins.plugins = [AcroBot,KickProtection]
    end
  end
end

@bots.each do |bot|
  Thread.new {bot.start;sleep 2}
end

while true do
  sleep 60
end