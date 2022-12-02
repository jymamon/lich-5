#TODO: [Jymamon] This needs t ton of cleanup. Also, consider making it a singleton.
class Parser
    require 'optparse'

    @@options_struct = Struct.new(
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
      :storrmfront,
      :wizard,
      #TODO: [Jymamon] Simplify these to set :game?
      :gemstone,
      :dragonrealms,
      :platinum,
      :shattered,
      :test,
      :fallen,
      # These are all related
      :game,
      :account,
      :password,
      :character)

    #TODO: [Jymamon] What's the proper way to inline this in ruby?
    @@reconnect_struct = Struct.new(:delay, :step)

    @@host_server = Struct.new(:server, :port)

    def self.defaults
        args = @@options_struct.new();
        args.lichdir = File.dirname(File.expand_path($PROGRAM_NAME))

        args.backupdir = "#{args.lichdir}/backup".freeze
        args.datadir = "#{args.lichdir}/data".freeze
        args.libdir = "#{args.lichdir}/lib".freeze # Not configurable, but here for consistency
        args.logdir = "#{args.lichdir}/lib".freeze
        args.mapdir = "#{args.lichdir}/maps".freeze
        args.scriptdir = "#{args.lichdir}/scripts".freeze
        args.tempdir = "#{args.lichdir}/temp".freeze

        args.entryfile = "#{args.datadir}/entry.dat"

        args.reconnect_delay = @@reconnect_struct.new()
        args.reconnect_delay.delay = 60
        args.reconnect_delay.step = 0

        return args;
    end

    def initialize
        @@options = Struct.new()
    end

    def self.parse(options)
        args = defaults();
        args.start_scripts = Array.new

        opt_parser = OptionParser.new { |opts|
            opts.banner = "Usage: lich.rbw [options]."

            # -----------------------------------------------------------------
            # Script use and information commands
            # -----------------------------------------------------------------
            opts.on("-?", "-h", "--help", "Prints this help") {
                # There are a million and one options supported for legacy compatability.
                # Omit those and particularly specialized commands from usage to reduce
                # the wall-of-text and help typical users find the commands they're like
                # to need.
                # In the future, it might be useful to futher split out help to have a
                # verbose version which includes these and, maybe, breaks up the help text
                # into categories of related commands for understandability.
                do_not_document_options = [
                    "--backup",
                    "--data",
                    "--detachable-client",
                    "--entrydat",
                    "--frontend",
                    "--frontend-command",
                    "--home",
                    "--hosts-file",
                    "--hosts-dir",
                    "--install",
                    "--link-to-sal",
                    "--link-to-sge",
                    "--maps",
                    "--scripts",
                    "--uninstall",
                    "--unlink-to-sal",
                    "--unlink-to-sge",
                    "--wine",
                    "--wine-prefix"]

                puts opts
                  .to_s
                  .split("\n")
                  .delete_if {
                    |line| do_not_document_options
                      .find{|option|
                        line =~ /#{option}/}}
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
    "health" your character has left in a non-Simutronics game, and so the "health" script command will most
    likely return a value of 0).

    The level of increase in efficiency when Lich is run in "bare-bones mode" (i.e. started with the --bare
    argument) depends on the data stream received from a given game, but on average results in a moderate
    improvement and it\'s recommended that Lich be run this way for any game that does not send "status"
    information" in a format consistent with Simutronics' GSL or XML encoding schemas.

    Examples:
      lich -w -d /usr/bin/lich/          (run Lich in Wizard mode using the dir \'/usr/bin/lich/\' as the program\'s home)
      lich -g gs3.simutronics.net:4000   (run Lich using the IP address \'gs3.simutronics.net\' and the port number \'4000\')
      lich --dragonrealms --test --genie (run Lich connected to DragonRealms Test server for the Genie frontend)
      lich --script-dir /mydir/scripts   (run Lich with its script directory set to \'/mydir/scripts\')
      lich --bare -g skotos.net:5555     (run in bare-bones mode with the IP address and port of the game set to \'skotos.net:5555\')
ADDITIONALUSAGETEXT
                exit
            }

            opts.on("-v", "--version", "Display version and credits information.") {
                puts "The Lich, version #{LICH_VERSION}"

                puts <<-CREDITS
    (an implementation of the Ruby interpreter by Yukihiro Matsumoto designed to be a 'script engine' for text-based MUDs)

    - The Lich program and all material collectively referred to as "The Lich project" is copyright (C) 2005-2006 Murray Miron.
    - The Gemstone IV and DragonRealms games are copyright (C) Simutronics Corporation.
    - The Wizard front-end and the StormFront front-end are also copyrighted by the Simutronics Corporation.
    - Ruby is (C) Yukihiro \'Matz\' Matsumoto.

    Thanks to all those who\'ve reported bugs and helped me track down problems on both Windows and Linux.
CREDITS
                exit
            }

            # -----------------------------------------------------------------
            # Game Login commands
            # -----------------------------------------------------------------
            opts.on("--entrydat ENTRYFILE", "Override the default saved logins file with the file specified.") {|entryfile|
                args.entryfile = entryfile
            }

            # Using entry.dat
            opts.on("--login CHARACTER", "Login the named CHARACTER using information from the saved logins file.") {|character|
                args.login_character = character.capitalize
            }

            # -----------------------------------------------------------------
            # Manual game Login commands
            # -----------------------------------------------------------------
            opts.on("--account ACCOUNT", "Login using the named ACCOUNT. Requires --password to also be used.") {|account|
                args.account = account
            }

            opts.on("--character CHARACTER", "Login the named CHARACTER.") {|character|
                args.character = character
            }

            opts.on("--password PASSWORD", "Login using the specified PASSSWORD. Requires --account to also be used.") {|password|
                args.password = password
            }

            # -----------------------------------------------------------------
            # Game selection commands
            # -----------------------------------------------------------------
            #TODO: [Jymamon] Simplify these down to a more condensed option
            opts.on("--dragonrealms", "Login to DragonRealms. Defaults to the Prime instance. Only needed if the same CHARACTER exists for mutliple games.") {
                args.dragonrealms = true
            }

            opts.on("--game SERVER:PORT", "Perform game login against the specified server and port.") {|game|
                #TODO: [Jymamon] Validate valid values
                if serverport =~ /(.+):(.+)/
                    args.game = game
                    args.game = @@host_server.new()
                    args.game.server = $1
                    args.game.port = $2.to_i
                else
                    puts "--game requires server and port in the format server:port"
                    exit
                end
            }

            opts.on("--gemstone", "Login to GemStone IV. Defaults to the Prime instance. Only needed if the same CHARACTER exists for mutliple games.") {
                args.gemstone = true
            }

            opts.on("--fallen", "Login to the Fallen instance of DragonRealms. Only needed if the same CHARACTER exists for mutliple instances.") {
                args.fallen = true
            }

            opts.on("--platinum", "Login to the Platinum instance of the game. Defaults to GemStone IV. Only needed if the same CHARACTER exists for instances.") {
                args.platinum = true
            }

            opts.on("--shattered", "Login to the Shattered instance of GemStone IV. Only needed if the same CHARACTER exists for instances.") {
                args.shattered = true
            }

            opts.on("--test", "Login to the Test instance of the game. Defaults to GemStone IV. Only needed if the same CHARACTER exists for instances.") {
                args.test = true
            }

            # -----------------------------------------------------------------
            # Client selection commands
            # -----------------------------------------------------------------
            opts.on("--avalon", "Start the game using the Avalon client.") {
                args.avalon = true
            }

            opts.on("--detachable-client PORT", "Comment needed here") {|port|
                if port =~ /^\d+$/
                  args.detachable_client_port = port
                else
                  $stdout.puts "warning: Port passed to --detachable-client must be numeric. Was #{port}."
                  exit
                end
            }

            opts.on("--frontend FRONTEND", "Login to the game using the specified front end. Only needed if saved login entries exist for the multiple front ends.") {|frontend|
                args.frontend = frontend
            }

            opts.on("--frontend-command COMMAND", "Use the specified COMMAND to start a custom front end client.") {|command|
                args.frontend_command = command
            }

            opts.on("--frostbite", "Start the game using the FrostBite client.") {
                args.frostbite = true
            }

            opts.on("--genie", "Start the game using the Geni client.") {
                args.genie = true
            }

            opts.on("-s", "--stormfront", "--wrayth", "Start the game using the Wrayth client.") {
                args.stormfront = true
            }

            opts.on("-w", "--wizard", "Start the game using the Wizard client.") {
                args.wizard = true
            }

            # -----------------------------------------------------------------
            # Directory override commands
            # -----------------------------------------------------------------
            opts.on("--backup BACKUPDIR", "Override the default backup directory.") {|directory|
                options.backupdir = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--data DATADIR", "Override the default data directory.") {|directory|
                options.datadir = directory.sub(/[\\\/]$/, '')
            }

            # This probably shouldn't be allowed at all. Lich is already loaded as is,
            # at least, this lib. What does it mean to change the home directory now?
            opts.on("--home HOMEDIR", "Override the default base lich directory.") {|directory|
                options.lichdir = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--logs LOGDIR", "Override the default logs directory.") {|directory|
                options.logdir = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--maps MAPDIR", "Override the default maps directory.") {|directory|
                options.mapdir = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--scripts SCRIPTDIR", "Override the default scripts directory.") {|directory|
                options.scriptdir = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--temp TEMPDIR", "Override the default temp directory.") {|directory|
                options.tempdir = directory.sub(/[\\\/]$/, '')
            }

            # -----------------------------------------------------------------
            # Install commands / linking commands
            # -----------------------------------------------------------------
            opts.on("--install", "Link lich to be the default program for game entry for all front ends.") { # deprecated
                if Lich.link_to_sge and Lich.link_to_sal
                  $stdout.puts 'Install was successful.'
                  Lich.log 'Install was successful.'
                else
                  $stdout.puts 'Install failed.'
                  Lich.log 'Install failed.'
                end
                exit
            }

            opts.on("--uninstall", "Remove lich from being the default program for game entry for all front ends.") { # deprecated
                if Lich.unlink_from_sge and Lich.unlink_from_sal
                  $stdout.puts 'Uninstall was successful.'
                  Lich.log 'Uninstall was successful.'
                else
                  $stdout.puts 'Uninstall failed.'
                  Lich.log 'Uninstall failed.'
                end
                exit
            }

            opts.on("--link-to-sal", "Make lich the default program for game entry using Wizard.") {
                result = Lich.link_to_sal
                if $stdout.isatty
                  if result
                    $stdout.puts "Successfully linked to SAL files."
                  else
                    $stdout.puts "Failed to link to SAL files."
                  end
                end
                exit
            }

            opts.on("--unlink-to-sal", "Remove lich from being the default program for game entry using Wizard.") {
                result = Lich.unlink_from_sal
                if $stdout.isatty
                  if result
                    $stdout.puts "Successfully unlinked from SAL files."
                  else
                    $stdout.puts "Failed to unlink from SAL files."
                  end
                end
                exit
            }

            opts.on("--link-to-sge", "Make lich the default program for game entry using Stormfront.") {
                result = Lich.link_to_sge
                if $stdout.isatty
                  if result
                    $stdout.puts "Successfully linked to SGE."
                  else
                    $stdout.puts "Failed to link to SGE."
                  end
                end
                exit
            }

            opts.on("--unlink-to-sge", "Remove lich from being the default program for game entry using Stormfront.") {|value|
                result = Lich.unlink_from_sge
                if $stdout.isatty
                  if result
                    $stdout.puts "Successfully unlinked from SGE."
                  else
                    $stdout.puts "Failed to unlink from SGE."
                  end
                end
                exit
            }

            # -----------------------------------------------------------------
            # Automation commands
            # -----------------------------------------------------------------
            opts.on("--[no-]reconnect", "If game disconnection is detected, automatically reconnet.") { |reconnect|
                args.reconnect = reconnect
            }

            opts.on("--reconnect_delay DELAY[:STEP]", "Configures the delay to be used when automatically reconnecting after a disconnect.") {|delay|
                delay =~ /([0-9]+)(\+[0-9]+)?/
                args.reconnect_delay.delay = $1.to_i
                args.reconnect_delay.step = $2.to_i
            }

            opts.on("--start-scripts SCRIPT[,SCRIPT[,...]]", "Start the comma delimited list of scripts upon login.") {|scripts|
                args.start_scripts += scripts.split(/,/)
            }

            # -----------------------------------------------------------------
            # UI commands
            # -----------------------------------------------------------------
            opts.on("--[no-]gui", "Force the (dis)use of the login GUI.") {|force_gui|
                args.force_gui = force_gui
            }

            opts.on("--wine FILE", "Use the specified file for starting WINE.") {|file|
                #TODO: [Jymamon] Verify it exists
                args.wine = file
                #TODO: [Jymamon] Other modules shouldn't be looking at ARGV - they should
                #       only use passed options.
                # already used when defining the Wine module
            }

            opts.on("--wine-prefix DIRECTORY", "Use the provided DIRECTORY as the PREFIX when configuring WINE.") {|prefix|
                #TODO: [Jymamon] Verify it exists
                args.wineprefix = prefix
            }

            opts.on("--host SERVER:PORT", "Deprecated(?).") {|serverport|
                if serverport =~ /(.+):(.+)/
                    args.host = @@host_server.new()
                    args.host.server = $1
                    args.host.port = $2.to_i
                else
                    puts "--host requires server and port in the format server:port"
                    exit
                end
            }

            opts.on("--hosts-file HOSTSFILE", "Override the default hosts file.") {|hostsfile|
                args.hostsfile = hostsfile
            }

            opts.on("--hosts-dir HOSTSDIRECTORY", "Override the default directory to be used for the hosts file.") {|hostfiledirectory|
                if File.exists?(hosts_dir)
                    args.hostsdirectory = hostfiledirectory.tr('\\', '/')
                    args.hostsdirectory += '/' unless args.hostsdirectory[-1..-1] == '/'
                else
                    $stdout.puts "warning: given hosts directory does not exist: #{hosts_dir}"
                    hosts_dir = nil
                end
            }

            opts.on("--[no-]save", "Save the specified login information for future use.") {|value|
                args.save = value
            }
        }

        opt_parser.parse!(options)

        options.delete_if{ |arg| arg =~ /^launcher\.exe$/i } # added by Simutronics Game Entry

        # Handle the 'shellexecture' non-flag entry. Not documented in --help.
        switch_index = options.index("shellexecute")        
        if ( !switch_index.nil? )
            # TODO: [Jymamon] Indexing outside the array?
            args.shellexecute = options[switch_index + 1]
            options.delete("shellexecute")
            options.delete(args.shellexecute)
        end

        # Hanle a .sal or .gse file in the arguments. Not documented in --help.
        sal_file_index = options.find_index{ |arg| arg =~ /\.sal$|Gse\.~xt$/i }

        if ( sal_file_index )
          if File.exists?(options[sal_file_index])
            options.sal = options[sal_file_index]
            options.delete(options.sal)
          else
            # This is /very/ sketchy as any other option in the command line will
            # break it. None-the-less, it was what existed in the original code.
            if options[sal_file_index .. -1].join(' ') =~ /([A-Z]:\\.+?\.(?:sal|~xt))/i
              options.sal = $1
              
              if File.exists?(options.sal)
                options = options[0 .. sal_file_index -1]
              end
            end
          end

          unless File.exists?(options.sal)
            # TODO: [Jymamon] Does the refactor change when this will be defined?
            if defined?(Wine)
              options.sal = "#{Wine::PREFIX}/drive_c/#{argv_options[:sal][3..-1].split('\\').join('/')}"
            end
          end
        end
        
        # TODO: [Jymamon] Check for invalid combinations. For example, "-s -w" doesn't make sense.

        # Hack-ish but sufficient for catching unused parameters
        if ( options.any? )
            opt_parser.parse("--help")
        end

        error = false

        if error then exit end
        return args
    end
end
