# acRobot
******************************************************************************

acRobot is an open source Cinch bot which brings the acronym game to IRC.
The bot will give the letters of a (fictional) acronym, and the players need
to come up with a definition for it, after which they can vote for the best 
submission.

There are already plenty of acro IRC bots and scripts around, though I felt
like writing my own in Ruby, using the Cinch library, since I feel it's easier
to add features to code I've written myself, in my favourite language.

## Configuration instructions
******************************************************************************

acRobot is written to generate its own config file when it can't find an
existing one.

* Install Cinch:
  `gem install cinch` (or check https://github.com/cinchrb/cinch#)
* Clone the git repo:
  `git clone git://github.com/FiXato/acRobot.git && cd acRobot`
* Run the bot:
  `./bin/acRobot.rb`
* Open the newly created config file:
  `open ~/.acro_bot_config.yaml`
* Change the network(s), server details, nickname, channel name(s), and make sure you set :enabled to true 
  for the networks you want to join
* Run the bot again:
  `./bin/acRobot.rb`

Note that you can also pass an alternative config filename:
  `./bin/acRobot.rb ~/.acro_alternative_config.yaml`

## Features
******************************************************************************

### Current:

* Configurable network profiles
* Multi-server (1 script to start multiple bots)
* Multiple game modes (3-6 letter words based on wordlists (mixed or specified), 4-6 random a-z 
  letters or 3-5 random 'easy' letters)
* Game mode can be specified at start of the game, or a random game mode can 
  be chosen
* Keyword-based acronym submission (`!submit <acro here>`) (channel and query)
* Keyword-based acronym voting (`!vote <acronumber>`) (channel and query)
* Context-based acronym submission and voting via PRIVMSG to the bot
* Acronym theme suggestions
* Score list
* Voting allowed only to acronym submitters
* Points only being awarded to those who've voted
* On-join notification

### Future:

* Cross-server games (allowing players to participate in the same game across multiple servers)
* Multi-lingual support
* Command restrictions based on hostmask
* Command restrictions based on channel access level
* High scores
* High scores per game mode
* Configurable required game score
* Duplicate acronym prevention
* Queueing/merging of responses
* Flood control
* Dynamic submission period duration based on acronym length
* Dynamic voting period duration based on amount of submissions
* Changing your vote
* Optionally disable public acro submission
* Optionally disable public acro voting
* More game modes

## ToDo
******************************************************************************

See the TODO.markdown file.

## Notes on Patches/Pull Requests
******************************************************************************

1. Fork the project.
2. Make your feature addition or bug fix.
3. Add tests for it (even though I don't have tests myself at the moment). 
  This is important so I don't break it in a future version unintentionally.
4. Commit, but do not mess with gemspec, version, history, or README.
  Want to have your own version? Bump version in a separate commit!
  That way I can ignore that commit when I pull.
5. Send me a pull request. Bonus points for topic branches.
6. You'll be added to the credits.

## Acknowledgements
******************************************************************************

Thanks go out to:

* m0d of www.nightbacon.com, for running the TMAcro bot several years on Esper.net
* The Chat4All (www.chat4all.org) and Esper (www.esper.net) IRC Networks, 
  for offering a place where I can run and test my acRo bot.
* The Cinch developers, for creating an easy to use IRC library.
* Flashcode, for developing the awesome WeeChat IRC client: www.weechat.org

## Copyright
******************************************************************************

Copyright (c) 2011 Filip H.F. "FiXato" Slagter.

See LICENSE for details.