#!/usr/bin/env ruby
#encoding: UTF-8
require 'cinch'
require 'cinch_ext.rb'
require 'monkeypatch'

class AcroBot
  include Cinch::Plugin
  include CinchExt
  attr_accessor :stage, :submissions, :letters, :scores, :votes, :gametype, :thread

  SUGGESTIONS = [
    'Excuses for being late',
    'BOFH Excuse calendar',
    'Things to do on holiday',
    'Things you find in nature',
    'Worst things to say after sex',
    'Food experiments',
  ]

  GAMETYPES = {
    '3lw' => '3 letter',
    '4lw' => '4 letter',
    '5lw' => '5 letter',
    '6lw' => '6 letter',
    'wordlist' => 'random dictionary', 
    'easy' => 'easy letters (no q, x, or z)',
    'hard' => '4-6 letters from the alphabet',
  }

  SCORE_NEEDED = 10

  def initialize(*args)
    super
    @stage = false
    fill_wordlists
    @thread = nil
  end

  match "acrohelp", method: :help_response
  def help_response(m)
    reply_with_template(m, :help)
  end

  #Start a new game with the same gametype as last time
  match /acro$/, method: :start_same_game
  def start_same_game(m)
    start_game(m,@gametype)
  end

  match /start ?(.*)/, method: :start_game
  match /acro (.*)/, method: :start_game
  def start_game(m,acro_type)
    if running?
      reply_with_template(m, :game_already_running)
      return false
    end

    set_gametype(acro_type)
    reset_scores

    reply_with_template(m, :game_intro)
    sleep 3
    start_round(m)
  end

  def start_round(m)
    @stage = 'entry'
    @letters = generate_letters
    @submissions = {}
    @votes = {}
    reply_with_template(m, :game_round_starts)
    start_thread do
      sleep 30
      m.reply text_templates(:game_time_remaining, "30 seconds")
      
      sleep 20
      m.reply text_templates(:game_time_remaining, "10 seconds")
      
      sleep 10
      end_entry_round(m)
    end
  end

  match "score", method: :show_scores
  def show_scores(m)
    if @scores.keys.size == 0
      reply_with_template(m, :scores_unavailable)
      return false
    end
    reply_with_template(m, :scores, @scores.keys.map{|nick|"#{nick}: #{@scores[nick]}"})
  end

  match /submit (.*)/, method: :submit_acro
  def submit_acro(m, acro)
    if !allow_entries?
      if !running?
        m.reply(text_templates(:game_not_running))
      else    
        m.reply(text_templates(:game_no_acros_allowed_anymore))
      end
      return false
    end

    return false unless valid_acro?(acro,m)
    register_acro(m,acro)
  end

  match /vote (.*)/, method: :vote_acro
  def vote_acro(m, acro_nr)
    if !allow_votes?
      if !running?
        m.reply(text_templates(:game_not_running))
      else    
        m.reply(text_templates(:game_no_votes_allowed_yet))
      end
      return false
    end

    acro_nr = acro_nr.to_i
    return false unless valid_vote?(m,acro_nr)
    register_vote(m, acro_nr)
  end

  match /\A(\d+)\Z/, use_prefix: false, method: :context_handle_vote
  def context_handle_vote(m, acro_nr)
    return if m.channel?
    vote_acro(m, acro_nr)
  end

  match /\A(\S+ (\S+ ?)+)\Z/, use_prefix: false, method: :context_handle_acro
  def context_handle_acro(m, acro, junk)
    return if acro.downcase[0..6] == '!submit'
    return if m.channel?
    submit_acro(m, acro)
  end

  def end_entry_round(m)    
    if number_of_submissions == 0
      m.reply(text_templates(:game_no_acros_received))
      end_game(m)
      return false
    end
    if number_of_submissions == 1
      reply_with_template(m,:game_insufficient_acros_received)
      start_round(m)
      return false
    end

    @stage='voting'
    m.reply text_templates(:game_time_to_vote)
    reply_with_template(m, :game_show_acros_for_vote)
    start_thread do
      m.reply text_templates(:game_time_remaining, "20 seconds")
      sleep 10

      m.reply text_templates(:game_time_remaining, "10 seconds")
      sleep 10
      end_voting_round(m)
    end
  end

  def end_voting_round(m)
    if @votes.size == 0
      m.reply(text_templates(:game_no_votes_received))
      end_game(m)
      return false
    end

    reply_with_template(m, :game_votes_report)
    
    #TODO: Rewrite scoring routine
    #Get this round's winners
    winners = @submissions.group_by{|k,v|v[:votes]}.max
    winning_nicks = winners.last.map{|user|user.first}
    m.reply "With #{winners.first} votes, #{winning_nicks.join(" and ")} won this round."

    #make sure that first all points are given
    voted_for = []
    winning_nicks.each do |user|
      voted_for << submissions[user][:voters]
      #Only voters can score
      unless votes.has_key?(user)
        m.reply "#{user} didn't vote, so isn't getting any points"
        next
      end
      @scores[user] += 1
    end
    voted_for.flatten!

    #Add points to first voter
    #TODO: do this based on timestamps (fairer/more certain)
    first_voter = votes.keys.select{|nick|voted_for.include?(nick)}.first
    m.reply text_templates(:game_first_voter_earns_point, {:nick => first_voter})
    @scores[first_voter] += 1
    
    if have_winner?
      end_game
      return
    end
    start_round(m)
  end

  match "stop", method: :end_game
  def end_game(m)
    if !running?
      reply_with_template(m, :game_already_stopped)
      return false
    end
    @stage=nil
    m.reply "Thank you for playing Acro."
    if @scores.size > 0
      winners = @scores.group_by{|k,v|v}.max
      m.reply "#{winners.last.map{|k,v|k}.join(" and ")} won the game with #{winners.first} points"
    end
    stop_thread
  end

  listen_to :join
  def listen(m)
    unless m.user.nick == bot.nick
      msg = "Welcome to #{m.channel.name}. "
      msg += "You can start a new game of Acro by typing #{format_msg('!acro')} in the main channel. " unless running?
      msg += "For more information, type " + format_help_botmsg("!acrohelp")
      m.user.notice msg
    end
  end

  private
  def allow_entries?
    stage == 'entry'
  end

  def allow_votes?
    stage == 'voting'
  end

  def running?
    @stage
  end

  def have_winner?
    #Check for a winner
    @scores.each do |user,score|
      if score >= SCORE_NEEDED
        return true
      end
    end
    false
  end

  def valid_acro?(acro,m)
    #TODO: Allow only private acros
    #m.reply("Submit your acros in private") if m.channel?
    acro.split(" ").each_with_index do |word, index|
      if word.chars.to_a.first.downcase != letters[index].downcase
        args = {:nick => m.user.nick, :nr => (index+1), :word => word, :first_letter => letters[index]}
        m.reply text_templates(:game_wrong_first_letter,args)
        return false
      end
      if word.chars.to_a.size < 2 && !%w[a i].include?(word.chars.to_a.first.downcase)
        args = {:nick => m.user.nick, :nr => (index+1), :word => word}
        m.reply text_templates(:game_word_too_short,args)
        return false
      end
      #TODO: Check if user is on channel?
    end
    true
  end

  def valid_vote?(m, acro_nr)
    #TODO: Allow only private votes
    #m.reply("Submit your votes in private") if m.channel?
    if acro_nr > number_of_submissions
      m.reply text_templates(:game_acro_does_not_exist, {:nick => m.user.nick})
      return false
    end
    if @votes.has_key?(m.user.nick) #TODO: Allow changing votes? If we do, make sure the order gets updated too
      m.reply text_templates(:game_already_voted)
      return false
    end
    unless submissions.has_key?(m.user.nick)
      m.reply text_templates(:game_cant_vote_without_acro)
      return false
    end
    if m.user.nick == nick_for_acro_number(acro_nr)
      m.reply text_templates(:game_cant_selfvote)
      return false
    end
    true
  end

  def register_acro(m,acro)
    if @submissions.has_key?(m.user.nick) #has the user already submitted an acro this round?
      m.reply text_templates(:game_acro_registered, {:acro => acro, :nick => m.user.nick})
      bot.channels.first.msg text_templates(:game_acro_changed)
    else
      m.reply text_templates(:game_acro_registered, {:acro => acro, :nick => m.user.nick})
      bot.channels.first.msg text_templates(:game_acro_received, submissions.size+1)
    end
    @submissions[m.user.nick] = {:acro => acro, :votes => 0, :voters => []}
  end

  def register_vote(m,acro_nr)
    acro_nick = nick_for_acro_number(acro_nr)
    acro = @submissions[acro_nick]
    acro[:votes] += 1
    acro[:voters] << m.user.nick
    @votes[m.user.nick] = {:nick => acro_nick, :acro_nr => acro_nr}
    m.reply text_templates(:game_vote_accepted)
    bot.channels.first.msg text_templates(:game_vote_received)
  end

  def dict(find=:all,size=nil)
    if size
      @wordlist_by_size ||= @wordlist.group_by{|word|word.size}
      dict = @wordlist_by_size[size]
    else
      dict = @wordlist
    end
    case find
    when :all
      return dict
    when :word
      return dict.random
    when :letters
      return dict.random.chars.to_a
    else
      return dict
    end
  end

  def fill_wordlists
    wordlists_dir = File.join(File.dirname(__FILE__),'..',"wordlists")
    wordlist_files = Dir.glob(File.join(wordlists_dir,"*.txt"))
    @wordlist = wordlist_files.map{|f|File.readlines(f).map{|words|words.strip.split}}.flatten.uniq
  end

  def format_help_botmsg(msg,type=:bold)
    cc = CONTROL_CODES[type]
    "#{cc}/msg #{bot.nick}#{CONTROL_CODES[:normal]}#{cc} #{msg}#{cc}"
  end

  def format_msg(msg,type=:bold)
    cc = CONTROL_CODES[type]
    "#{cc}#{msg}#{cc}"
  end

  def gametype_description
    GAMETYPES[@gametype]
  end

  def generate_letters
    case @gametype
    when 'hard'
      letters = (6 - rand(2)).times.map{%w[a b c d e f g h i j k l m n o p q r s t u v w x y z].random}
    when 'easy'
      letters = (5 - rand(2)).times.map{%w[a b c d e f g h i j k l m n o p r s t u v w y].random}
    when '3lw'
      letters = dict(:letters,3)
    when '4lw'
      letters = dict(:letters,4)
    when '5lw'
      letters = dict(:letters,5)
    when '6lw'
      letters = dict(:letters,6)
    when 'wordlist'
      letters = dict(:letters)
    end
    return letters.map{|letter|letter.upcase}
  end

  def acro_for_nick(nick)
    submissions[nick][:acro]
  end

  def nick_for_acro_number(acro_nr)
    submissions.keys[acro_nr-1].to_s
  end

  def number_of_submissions
    submissions.keys.size
  end

  def reply_with_template(m,template_name,*args)
    text_templates(template_name,args).split("\n").each{|msg| m.reply msg.strip}
  end

  def reset_scores
    @scores = Hash.new{|h,k|h[k] = 0}
  end

  def set_gametype(acro_type)
    @gametype = acro_type if GAMETYPES.keys.include?(acro_type)
    @gametype ||= GAMETYPES.keys.random
  end

  def start_thread(&block)
    @thread = Thread.new{block.call}
  end

  def stop_thread
    @thread.kill if @thread.class == Thread
  end

  def text_templates(key,args=nil)
    case key
    when :game_already_stopped
      "This game of Acro has already been stopped!"
    when :game_already_running
      "A lovely game of Acro is already in progress!"
    when :game_not_running
      "No game active. Start one with !acro"
    when :game_no_votes_allowed_yet
      "No votes allowed yet."
    when :game_no_acros_alllowed_anymore
      "You can't submit acros anymore."
    when :game_acro_registered
      "Submission updated! #{args[:acro]} has been registered to #{args[:nick]}"
    when :game_acro_received
      "#{args} Acro#{args == 1 ? '' : 's'} received!"
    when :game_acro_changed
      "A user changed their acro."
    when :game_acro_does_not_exist
      "#{args[:nick]}: there is no such acro. There are only #{number_of_submissions} acros to vote for."
    when :game_already_voted
      "You have already voted"
    when :game_cant_vote_without_acro
      "You haven't submitted an acro, so you can't vote"
    when :game_cant_selfvote
      "You can't vote for yourself"
    when :game_vote_accepted
      "Vote accepted!"
    when :game_vote_received
      "#{votes.size} vote#{votes.size == 1 ? '' : 's'} received!"
    when :game_no_votes_received
      "We got no votes.. I guess no-one wants to play anymore."
    when :game_no_acros_received
      "Time's up and no-one submitted a valid acro :'( I guess no-one wants to play anymore..."
    when :game_insufficient_acros_received
      <<-EOS
        We received insufficient acros, so we are skipping this round.
        #{submissions.keys.map{|nick|'%s submitted %s' % [nick,format_msg(acro_for_nick(nick))]}.join("\n")}
      EOS
    when :game_time_to_vote
      "Time's up! We've had #{submissions.size} submissions. Please vote with #{format_help_botmsg("number")}. So if you want to vote for the first submission, type: #{format_help_botmsg("1")} -- if the bot doesn't recognise it, try prefixing it with #{format_msg('!vote')}"
    when :game_show_acros_for_vote
      submissions.keys.each_with_index.map do |submitter, idx|
        "#{idx+1}: #{acro_for_nick(submitter)}"
      end.join("\n")
    when :game_votes_report
      "We got a total of #{@votes.size} votes!\n" + \
      submissions.map do |nick, submission|
        "#{nick}'s acro '#{submission[:acro]}' got #{submission[:votes]} vote#{submission[:votes] == 1 ? '' : 's'}: #{submission[:voters].join(", ")}"
      end.join("\n")
    when :game_first_voter_earns_point
      "#{args[:nick]} was the first to vote for a winning submission and earns a point as well."
    when :help
      <<-EOS
        In the game of Acro you have to come up with words for each letter of the given acronym. It does not need to be an existing acronym, so you can be creative!
        To start Acro, you can type \002!acro random\002 to start with a random gametype. Or, to start a 3 letter Acro game, type \002!acro 3lw\002 or to use the last used gametype, just type \002!acro\002
        Allowed gametypes are: #{GAMETYPES.keys.map{|k|"\u0002#{k}\u0002 (#{GAMETYPES[k]})"}.join(", ")}
        To submit an acro, type: #{format_help_botmsg("Your Acro Goes Here")}, for instance #{format_help_botmsg("Beat on our Toydrums")} (should the bot not recognise it, you can prefix it with #{format_msg('!submit')}).
        To vote for an acro, type: #{format_help_botmsg("acronumber")}, for instance to vote for the 2nd acro, type: #{format_help_botmsg("2")} (should the bot not recognise your vote, try prefixing it with #{format_msg("!vote")})
      EOS
    when :game_intro
      <<-EOS
        Welcome to a fabulous new game of \002#{gametype_description}\002 Acro!
        I'll give you some letters, and you have to come up with an acronym for those letters. It doesn't have to exist, so be creative! For more info, type #{format_help_botmsg("!acrohelp")}
      EOS
    when :game_round_starts
      <<-EOS
        Submit your acro with: #{format_help_botmsg('Your Acro Goes Here',:underline)} (should the bot not recognise it, you can prefix it with #{format_msg('!submit')}).
        Suggestion for this round: #{format_msg(SUGGESTIONS.random)}
        You have \002±60 seconds\002 to make an acro with these letters: \002#{@letters.join(" ")}\002
      EOS
    when :game_time_remaining
      "Only \002#{args}\002 remaining!"
    when :game_wrong_first_letter
      "#{args[:nick]}: word ##{args[:nr]} (#{args[:word]}) is rejected since it doesn't start with #{args[:first_letter]}"
    when :game_word_too_short
      "#{args[:nick]}: word ##{args[:nr]} (#{args[:word]}) is rejected because it's not at least 2 characters long"
    when :scores_unavailable
      "No scores available yet"
    when :scores
      "Scores #{running? ? 'of this game' : 'of last game'} are:\n#{args.join("\n")}"
    end
  end
end