# frozen_string_literal: true

# Centralizes all of the ARGV parsing for supported command line arguments. This needs to
# be used early has some of the options have impact on how other modules load or behave.
class Parser
  require 'optparse'
  
  def self.defaults
    # TODO: This could be broken up into a number of chained parsers in order to reduce
    # complexity of this class. Maybe one for directory options, one for client options,
    # and one for misc options?  For now, centralizing it into a single class, even if
    # overly complex, is an improvement.
    args = Struct.new(
      :detachable_client,
      :entryfile,
      :force_gui,
      :frontend,
      :frontend_command,
      :host,
      :hostsfile,
      :hostsdirectory,
      :login_character,
      :reconnect,
      :reconnect_delay,
      :sal,
      :save,
      :shellexecute,
      :start_scripts,
      # Directory configuration
      :lichdir,
      :backupdir,
      :datadir,
      :libdir,
      :logdir,
      :mapdir,
      :scriptdir,
      :tempdir,
      :wine,
      :wineprefix,
      # Frontends
      :avalon,
      :frostbite,
      :genie,
      :stormfront,
      :without_frontend,
      :wizard,
      # Logon
      :game,
      :account,
      :password,
      :character,
      # Game instance
      :dragonrealms,
      :fallen,      
      :gemstone,
      :platinum,
      :shattered,
      :test,
    ).new
    
    args.lichdir = File.dirname(File.expand_path($PROGRAM_NAME))

    args.backupdir = "#{args.lichdir}/backup"
    args.datadir = "#{args.lichdir}/data"
    args.libdir = "#{args.lichdir}/lib" # Not configurable, but here for consistency
    args.logdir = "#{args.lichdir}/lib"
    args.mapdir = "#{args.lichdir}/maps"
    args.scriptdir = "#{args.lichdir}/scripts"
    args.tempdir = "#{args.lichdir}/temp"

    args.reconnect_delay = Struct.new(:delay, :step).new
    args.reconnect_delay.delay = 60
    args.reconnect_delay.step = 0

    args
  end

  def self.parse(options)
    args = defaults
    args.start_scripts = []

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: lich.rbw [options].'

      # -----------------------------------------------------------------
      # Script use and information commands
      # -----------------------------------------------------------------
      opts.on('-?', '-h', '--help', 'Prints this help') do
        # There are a million and one options supported for legacy compatability.
        # Omit those and particularly specialized commands from usage to reduce
        # the wall-of-text and help typical users find the commands they're like
        # to need.
        # In the future, it might be useful to futher split out help to have a
        # verbose version which includes these and, maybe, breaks up the help text
        # into categories of related commands for understandability.
        do_not_document_options = [
          '--backup',
          '--data',
          '--detachable-client',
          '--entrydat',
          '--frontend',
          '--frontend-command',
          '--home',
          '--hosts-file',
          '--hosts-dir',
          '--install',
          '--link-to-sal',
          '--link-to-sge',
          '--maps',
          '--scripts',
          '--uninstall',
          '--unlink-to-sal',
          '--unlink-to-sge',
          '--wine',
          '--wine-prefix',
          '--without-frontend',
        ]

        puts opts
            .to_s
            .split("\n")
            .delete_if { |line|
                do_not_document_options
                    .find do |option|
                        line =~ /#{option}/
                    end
                }
            .join("\n")

        puts <<-ADDITIONALUSAGETEXT

    Most users will not need these options. Most are for automatoin scenarios and others are for advanced
    testing. Some combinatations may not make sense. In these cases, the last one on the command line will
    generally take precedence but avoiding such combinations is best.

    The majority of Lich's built-in functionality was designed and implemented with Simutronics MUDs in mind
    (primarily Gemstone IV): as such, many options/features provided by Lich may not be applicable when it is
    used with a non-Simutronics MUD.  In nearly every aspect of the program, users who are not playing a
    Simutronics game should be aware that if the description of a feature/option does not sound applicable
    and/or compatible with the current game, it should be assumed that the feature/option is not.  This
    particularly applies to in-script methods (commands) that depend heavily on the data received from the
    game conforming to specific patterns (for instance, it\'s extremely unlikely Lich will know how much
    'health' your character has left in a non-Simutronics game, and so the 'health' script command will most
    likely return a value of 0).

    The level of increase in efficiency when Lich is run in 'bare-bones mode' (i.e. started with the --bare
    argument) depends on the data stream received from a given game, but on average results in a moderate
    improvement and it\'s recommended that Lich be run this way for any game that does not send 'status'
    information' in a format consistent with Simutronics' GSL or XML encoding schemas.

    Examples:
      lich -w -d /usr/bin/lich/          (run Lich in Wizard mode using the dir \'/usr/bin/lich/\' as the program\'s home)
      lich -g gs3.simutronics.net:4000   (run Lich using the IP address \'gs3.simutronics.net\' and the port number \'4000\')
      lich --dragonrealms --test --genie (run Lich connected to DragonRealms Test server for the Genie frontend)
      lich --script-dir /mydir/scripts   (run Lich with its script directory set to \'/mydir/scripts\')
      lich --bare -g skotos.net:5555     (run in bare-bones mode with the IP address and port of the game set to \'skotos.net:5555\')
        ADDITIONALUSAGETEXT
        exit
      end

      opts.on('-v', '--version', 'Display version and credits information.') do
        puts "The Lich, version #{LICH_VERSION}"

        puts <<-CREDITS
    (an implementation of the Ruby interpreter by Yukihiro Matsumoto designed to be a 'script engine' for text-based MUDs)

    - The Lich program and all material collectively referred to as 'The Lich project' is copyright (C) 2005-2006 Murray Miron.
    - The Gemstone IV and DragonRealms games are copyright (C) Simutronics Corporation.
    - The Wizard front-end and the StormFront front-end are also copyrighted by the Simutronics Corporation.
    - Ruby is (C) Yukihiro \'Matz\' Matsumoto.

    Thanks to all those who\'ve reported bugs and helped me track down problems on both Windows and Linux.
        CREDITS
        exit
      end

      # Line length triggers on the user facing text. Sacrificing user understanding for a rule
      # isn't the right trade.  We could break them up into multi-line strings, but that reads
      # even worse than the long lines.
      # rubocop:disable Layout/LineLength
      # -----------------------------------------------------------------
      # Game Login commands
      # -----------------------------------------------------------------
      opts.on('--entrydat ENTRYFILE',
              'Override the default saved logins file with the file specified.') do |entryfile|
        args.entryfile = entryfile
      end

      # Using entry.dat, --character is used for manual login. Those can be consolidated.
      opts.on('--login CHARACTER',
              'Login the named CHARACTER using information from the saved logins file.') do |character|
        args.login_character = character.capitalize
      end

      # -----------------------------------------------------------------
      # Manual game Login commands
      # -----------------------------------------------------------------
      opts.on('--account ACCOUNT',
              'Login using the named ACCOUNT. Requires --password to also be used.') do |account|
        args.account = account
      end

      opts.on('--character CHARACTER', 'Login the named CHARACTER.') do |character|
        args.character = character
      end

      opts.on('--password PASSWORD',
              'Login using the specified PASSSWORD. Requires --account to also be used.') do |password|
        args.password = password
      end

      # -----------------------------------------------------------------
      # Game selection commands
      # -----------------------------------------------------------------
      # TODO: Simplify these down to a more condensed option and handle command lines
      #       that are contradictory (such as both --gemstone and --dragonrealms specified)
      opts.on('--game SERVER:PORT', 'Perform game login against the specified server and port.') do |game|
        # TODO: Validate valid values
        if serverport =~ /(.+):(.+)/
          args.game = game
          args.game = Struct.new(:server, :port).new
          args.game.server = ::Regexp.last_match(1)
          args.game.port = ::Regexp.last_match(2).to_i
        else
          puts '--game requires server and port in the format server:port'
          exit
        end
      end

      opts.on('--dragonrealms',
              'Login to DragonRealms. Defaults to the Prime instance. Only needed if the same CHARACTER exists for mutliple games.') do
        args.dragonrealms = true
      end
      
      opts.on('--fallen',
              'Login to the Fallen instance of DragonRealms. Only needed if the same CHARACTER exists for mutliple games.') do
        args.dragonrealms = true
        args.fallen = true
      end

      opts.on('--gemstone',
              'Login to GemStone IV. Only needed if the same CHARACTER exists for mutliple games.') do
        args.gemstone = true
      end

      opts.on('--platinum',
              'Login to Platinum instance of the game. Default to GemStone IV. Only needed if the same CHARACTER exists for mutliple games.') do
        args.platinum = true
      end

      opts.on('--shattered',
              'Login to Shattered instance of the game. Default to GemStone IV. Only needed if the same CHARACTER exists for mutliple games.') do
        args.shattered = true
      end

      opts.on('--test',
              'Login to Test instance of the game. Default to GemStone IV. Only needed if the same CHARACTER exists for mutliple games.') do
        args.test = true
      end
      
      # -----------------------------------------------------------------
      # Client selection commands
      # -----------------------------------------------------------------
      opts.on('--avalon', 'Start the game using the Avalon client.') do
        args.avalon = true
      end

      opts.on('--detachable-client PORT', 'Comment needed here') do |port|
        if port =~ /^\d+$/
          args.detachable_client_port = port
        else
          $stdout.puts "warning: Port passed to --detachable-client must be numeric. Was #{port}."
          exit
        end
      end

      opts.on('--frontend FRONTEND',
              'Login to the game using the specified front end. Only needed if saved login entries exist for the multiple front ends.') do |frontend|
        args.frontend = frontend
      end

      opts.on('--frontend-command COMMAND',
              'Use the specified COMMAND to start a custom front end client.') do |command|
        args.frontend_command = command
      end

      opts.on('--frostbite', 'Start the game using the FrostBite client.') do
        args.frostbite = true
      end

      opts.on('--genie', 'Start the game using the Geni client.') do
        args.genie = true
      end

      opts.on('-s', '--stormfront', '--wrayth', 'Start the game using the Wrayth client.') do
        args.stormfront = true
      end

      opts.on('--without-frontend', 'Connect without any frontend.') do
        args.without_frontend = true
      end

      opts.on('-w', '--wizard', 'Start the game using the Wizard client.') do
        args.wizard = true
      end

      # -----------------------------------------------------------------
      # Directory override commands
      # -----------------------------------------------------------------
      opts.on('--backup BACKUPDIR', 'Override the default backup directory.') do |directory|
        options.backupdir = directory.sub(%r{[\\/]$}, '')
      end

      opts.on('--data DATADIR', 'Override the default data directory.') do |directory|
        options.datadir = directory.sub(%r{[\\/]$}, '')
      end

      # This probably shouldn't be allowed at all. Lich is already loaded as is,
      # at least, this lib. What does it mean to change the home directory now?
      opts.on('--home HOMEDIR', 'Override the default base lich directory.') do |directory|
        options.lichdir = directory.sub(%r{[\\/]$}, '')
      end

      opts.on('--logs LOGDIR', 'Override the default logs directory.') do |directory|
        options.logdir = directory.sub(%r{[\\/]$}, '')
      end

      opts.on('--maps MAPDIR', 'Override the default maps directory.') do |directory|
        options.mapdir = directory.sub(%r{[\\/]$}, '')
      end

      opts.on('--scripts SCRIPTDIR', 'Override the default scripts directory.') do |directory|
        options.scriptdir = directory.sub(%r{[\\/]$}, '')
      end

      opts.on('--temp TEMPDIR', 'Override the default temp directory.') do |directory|
        options.tempdir = directory.sub(%r{[\\/]$}, '')
      end

      # -----------------------------------------------------------------
      # Install commands / linking commands
      # -----------------------------------------------------------------
      opts.on('--install', 'Link lich to be the default program for game entry for all front ends.') do # deprecated
        if Lich.link_to_sge && Lich.link_to_sal
          $stdout.puts 'Install was successful.'
          Lich.log 'Install was successful.'
        else
          $stdout.puts 'Install failed.'
          Lich.log 'Install failed.'
        end
        exit
      end

      opts.on('--uninstall', 'Remove lich from being the default program for game entry for all front ends.') do # deprecated
        if Lich.unlink_from_sge && Lich.unlink_from_sal
          $stdout.puts 'Uninstall was successful.'
          Lich.log 'Uninstall was successful.'
        else
          $stdout.puts 'Uninstall failed.'
          Lich.log 'Uninstall failed.'
        end
        exit
      end

      opts.on('--link-to-sal', 'Make lich the default program for game entry using Wizard.') do
        result = Lich.link_to_sal
        if $stdout.isatty
          if result
            $stdout.puts 'Successfully linked to SAL files.'
          else
            $stdout.puts 'Failed to link to SAL files.'
          end
        end
        exit
      end

      opts.on('--unlink-to-sal', 'Remove lich from being the default program for game entry using Wizard.') do
        result = Lich.unlink_from_sal
        if $stdout.isatty
          if result
            $stdout.puts 'Successfully unlinked from SAL files.'
          else
            $stdout.puts 'Failed to unlink from SAL files.'
          end
        end
        exit
      end

      opts.on('--link-to-sge', 'Make lich the default program for game entry using Stormfront.') do
        result = Lich.link_to_sge
        if $stdout.isatty
          if result
            $stdout.puts 'Successfully linked to SGE.'
          else
            $stdout.puts 'Failed to link to SGE.'
          end
        end
        exit
      end

      opts.on('--unlink-to-sge',
              'Remove lich from being the default program for game entry using Stormfront.') do |_value|
        result = Lich.unlink_from_sge
        if $stdout.isatty
          if result
            $stdout.puts 'Successfully unlinked from SGE.'
          else
            $stdout.puts 'Failed to unlink from SGE.'
          end
        end
        exit
      end

      # -----------------------------------------------------------------
      # Automation commands
      # -----------------------------------------------------------------
      opts.on('--[no-]reconnect', 'If game disconnection is detected, automatically reconnet.') do |reconnect|
        args.reconnect = reconnect
      end

      opts.on('--reconnect_delay DELAY[:STEP]',
              'Configures the delay to be used when automatically reconnecting after a disconnect.') do |delay|
        delay =~ /([0-9]+)(\+[0-9]+)?/
        args.reconnect_delay.delay = ::Regexp.last_match(1).to_i
        args.reconnect_delay.step = ::Regexp.last_match(2).to_i
      end

      opts.on('--start-scripts SCRIPT[,SCRIPT[,...]]',
              'Start the comma delimited list of scripts upon login.') do |scripts|
        args.start_scripts += scripts.split(/,/)
      end

      # -----------------------------------------------------------------
      # UI commands
      # -----------------------------------------------------------------
      opts.on('--[no-]gui', 'Force the (dis)use of the login GUI.') do |force_gui|
        args.force_gui = force_gui
      end

      opts.on('--wine FILE', 'Use the specified file for starting WINE.') do |file|
        # TODO: Verify it exists
        args.wine = file
        # TODO: Other modules shouldn't be looking at ARGV - they should
        #       only use passed options.
        # already used when defining the Wine module
      end

      opts.on('--wine-prefix DIRECTORY',
              'Use the provided DIRECTORY as the PREFIX when configuring WINE.') do |prefix|
        # TODO: Verify it exists
        args.wineprefix = prefix
      end

      opts.on('--host SERVER:PORT', 'Deprecated(?).') do |serverport|
        if serverport =~ /(.+):(.+)/
          args.host = Struct.new(:server, :port).new
          args.host.server = ::Regexp.last_match(1)
          args.host.port = ::Regexp.last_match(2).to_i
        else
          puts '--host requires server and port in the format server:port'
          exit
        end
      end

      opts.on('--hosts-file HOSTSFILE', 'Override the default hosts file.') do |hostsfile|
        args.hostsfile = hostsfile
      end

      opts.on('--hosts-dir HOSTSDIRECTORY',
              'Override the default directory to be used for the hosts file.') do |hostfiledirectory|
        if File.exist?(hostfiledirectory)
          args.hostsdirectory = hostfiledirectory.tr('\\', '/')
          args.hostsdirectory += '/' unless args.hostsdirectory[-1..] == '/'
        else
          $stdout.puts "warning: given hosts directory does not exist: #{hosts_dir}."
        end
      end

      opts.on('--[no-]save', 'Save the specified login information for future use.') do |value|
        args.save = value
      end
    end
    # rubocop:enable Layout/LineLength

    opt_parser.parse!(options)

    options.delete_if { |arg| arg =~ /^launcher\.exe$/i } # added by Simutronics Game Entry

    # Handle the 'shellexecture' non-flag entry. Not documented in --help.
    switch_index = options.index('shellexecute')
    unless switch_index.nil?
      # TODO: Indexing outside the array?
      args.shellexecute = options[switch_index + 1]
      options.delete('shellexecute')
      options.delete(args.shellexecute)
    end

    # Hanle a .sal or .gse file in the arguments. Not documented in --help.
    sal_file_index = options.find_index { |arg| arg =~ /\.sal$|Gse\.~xt$/i }

    if sal_file_index
      if File.exist?(options[sal_file_index])
        options.sal = options[sal_file_index]
        options.delete(options.sal)
      elsif options[sal_file_index..].join(' ') =~ /([A-Z]:\\.+?\.(?:sal|~xt))/i
        # This is /very/ sketchy as any other option in the command line will
        # break it. None-the-less, it was what existed in the original code.
        args.sal = ::Regexp.last_match(1)

        options = options[0..sal_file_index - 1] if File.exist?(options.sal)
      end

      if !File.exist?(options.sal) && defined?(Wine)
        # TODO: Does the refactor change when this will be defined?
        args.sal = "#{Wine::PREFIX}/drive_c/#{options.sal[3..].split('\\').join('/')}"
      end
    end

    args.entryfile ||= "#{args.datadir}/entry.dat"
    
    unless args.gemstone || args.dragonrealms || args.game
      args.gemstone = true
    end

    # TODO: Check for invalid combinations. For example, '-s -w' doesn't make sense.
    #if gamecode.gemstone
    #  if gamecode.platinum
    #    args.gamecode = "GSX" 
    #  elsif gamecode.shattered
    #    args.gamecode = "GSF"
    #  elsif gamecode.test
    #    args.gamecode = "GST"
    #  else
    #    args.gamecode = "GS3"
    #  end
    #elsif gamecode.shattered
    #  args.gamecode = "GSF"
    #elsif gamecode.dragonrealms
    #  if gamecode.platinum
    #    args.gamecode = "DRX"
    #  elsif gamecode.fallen
    #    args.gamecode = "DRF"
    #  elsif gamecode.test
    #    args.gamecode = "DRT"
    #  else
    #    args.gamecode = "DR"
    #  end
    #elsif gamecode.fallen
    #    args.gamecode = "DRF"
    #else
    #    args.gamecode = ".*"
    #end
    
    # Hack-ish but sufficient for catching unused parameters
    opt_parser.parse('--help') if options.any?

    error = false

    exit if error
    args
  end
end
