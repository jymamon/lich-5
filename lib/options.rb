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
      :save,
      :start_scripts,
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
        args.force_gui = true

        args.entryfile = "#{DATA_DIR}/entry.dat"
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
            opts.banner = "Usage: lich.rbw [options]"

            opts.on("-?", "-h", "--help", "Prints this help") {
                deprecated_options = [
                    "--install",
                    "--uninstall",
                    "--link-to-sal",
                    "--unlink-to-sal",
                    "--link-to-sge",
                    "--unlink-to-sge"]

                puts opts
                  .to_s
                  .split("\n")
                  .delete_if {
                    |line| deprecated_options
                      .find{|option|
                        line =~ /#{option}/}}
                  .join("\n")

                puts ''
                puts 'The majority of Lich\'s built-in functionality was designed and implemented with Simutronics MUDs in mind'
                puts '(primarily Gemstone IV): as such, many options/features provided by Lich may not be applicable when it is'
                puts 'used with a non-Simutronics MUD.  In nearly every aspect of the program, users who are not playing a'
                puts 'Simutronics game should be aware that if the description of a feature/option does not sound applicable'
                puts 'and/or compatible with the current game, it should be assumed that the feature/option is not.  This'
                puts 'particularly applies to in-script methods (commands) that depend heavily on the data received from the'
                puts 'game conforming to specific patterns (for instance, it\'s extremely unlikely Lich will know how much '
                puts '"health" your character has left in a non-Simutronics game, and so the "health" script command will most'
                puts 'likely return a value of 0).'
                puts ''
                # TODO: [Jymamon] This references a --bare option that I don't think is valid anymore.
                puts 'The level of increase in efficiency when Lich is run in "bare-bones mode" (i.e. started with the --bare'
                puts 'argument) depends on the data stream received from a given game, but on average results in a moderate'
                puts 'improvement and it\'s recommended that Lich be run this way for any game that does not send "status'
                puts 'information" in a format consistent with Simutronics\' GSL or XML encoding schemas.'
                puts ''
                puts ''
                puts 'Examples:'
                puts '  lich -w -d /usr/bin/lich/          (run Lich in Wizard mode using the dir \'/usr/bin/lich/\' as the program\'s home)'
                puts '  lich -g gs3.simutronics.net:4000   (run Lich using the IP address \'gs3.simutronics.net\' and the port number \'4000\')'
                puts '  lich --dragonrealms --test --genie (run Lich connected to DragonRealms Test server for the Genie frontend)'
                puts '  lich --script-dir /mydir/scripts   (run Lich with its script directory set to \'/mydir/scripts\')'
                puts '  lich --bare -g skotos.net:5555     (run in bare-bones mode with the IP address and port of the game set to \'skotos.net:5555\')'
                puts ''

                exit
            }
            
            opts.on("-v", "--version", "Comment needed here") {
                puts "The Lich, version #{LICH_VERSION}"
                puts ' (an implementation of the Ruby interpreter by Yukihiro Matsumoto designed to be a \'script engine\' for text-based MUDs)'
                puts ''
                puts '- The Lich program and all material collectively referred to as "The Lich project" is copyright (C) 2005-2006 Murray Miron.'
                puts '- The Gemstone IV and DragonRealms games are copyright (C) Simutronics Corporation.'
                puts '- The Wizard front-end and the StormFront front-end are also copyrighted by the Simutronics Corporation.'
                puts '- Ruby is (C) Yukihiro \'Matz\' Matsumoto.'
                puts ''
                puts 'Thanks to all those who\'ve reported bugs and helped me track down problems on both Windows and Linux.'
                exit
            }

            opts.on("--link-to-sal", "Comment needed here") {
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
            
            opts.on("--unlink-to-sal", "Comment needed here") {            
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
            
            opts.on("--install", "Comment needed here") { # deprecated
                if Lich.link_to_sge and Lich.link_to_sal
                  $stdout.puts 'Install was successful.'
                  Lich.log 'Install was successful.'
                else
                  $stdout.puts 'Install failed.'
                  Lich.log 'Install failed.'
                end
                exit
            }
            
            opts.on("--uninstall", "Comment needed here") { # deprecated
                if Lich.unlink_from_sge and Lich.unlink_from_sal
                  $stdout.puts 'Uninstall was successful.'
                  Lich.log 'Uninstall was successful.'
                else
                  $stdout.puts 'Uninstall failed.'
                  Lich.log 'Uninstall failed.'
                end
                exit
            }

            opts.on("--link-to-sge", "Comment needed here") {
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
            
            opts.on("--unlink-to-sge", "Comment needed here") {|value|
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

            opts.on("--entrydat ENTRYFILE", "Comment needed here") {|entryfile|
                args.entryfile = entryfile            
            }
            
            opts.on("--[no-]gui", "Comment needed here") {|force_gui|
                args.force_gui = force_gui            
            }

            opts.on("--login CHARACTER", "Comment needed here") {|character|
                args.login_character = character.capitalize
            }

            opts.on("--[no-]reconnect", "Comment needed here") { |reconnect|
                args.reconnect = reconnect
            }
            
            opts.on("--reconnect_delay DELAY", "Comment needed here") {|delay|
                delay =~ /([0-9]+)(\+[0-9]+)?/
                args.reconnect_delay.delay = $1.to_i
                args.reconnect_delay.step = $2.to_i
            }

            opts.on("--start-scripts SCRIPT_LIST", "Comment needed here") {|scripts|
                args.start_scripts += scripts.split(/,/)
            }
            
            opts.on("--avalon", "Comment needed here") {
                args.avalon = true
            }

            opts.on("--frostbite", "Comment needed here") {
                args.frostbite = true
            }

            opts.on("--genie", "Comment needed here") {
                args.genie = true
            }

            opts.on("-s", "--stormfront", "Comment needed here") {
                args.stormfront = true
            }

            opts.on("-w", "--wizard", "Comment needed here") {
                args.wizard = true
            }

            #TODO: [Jymamon] Simplify these down to a more condensed option
            opts.on("--dragonrealms", "Comment needed here") {
                args.dragonrealms = true
            }
            
            opts.on("--gemstone", "Comment needed here") {
                args.gemstone = true
            }

            opts.on("--fallen", "Comment needed here") {
                args.fallen = true
            }

            opts.on("--platinum", "Comment needed here") {
                args.platinum = true
            }
            
            opts.on("--shattered", "Comment needed here") {
                args.shattered = true
            }

            opts.on("--test", "Comment needed here") {
                args.test = true
            }
            
            opts.on("--home HOMEDIR", "Comment needed here") {|directory|
                # ERROR: dynamic constant assignment
                #LICH_DIR = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--temp TEMPDIR", "Comment needed here") {|directory|
                # ERROR: dynamic constant assignment - make an opt and
                # have the main script assign since that doesn't seem
                # to be an error?!!?
                #TEMP_DIR = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--scripts SCRIPTDIR", "Comment needed here") {|directory|
                # ERROR: dynamic constant assignment - make an opt and
                # have the main script assign since that doesn't seem
                # to be an error?!!?
                #SCRIPT_DIR = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--maps MAPDIR", "Comment needed here") {|directory|
                # ERROR: dynamic constant assignment - make an opt and
                # have the main script assign since that doesn't seem
                # to be an error?!!?
                #MAP_DIR = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--logs LOGDIR", "Comment needed here") {|directory|
                # ERROR: dynamic constant assignment - make an opt and
                # have the main script assign since that doesn't seem
                # to be an error?!!?
                #LOG_DIR = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--backup BACKUPDIR", "Comment needed here") {|directory|
                # ERROR: dynamic constant assignment - make an opt and
                # have the main script assign since that doesn't seem
                # to be an error?!!?
                #BACKUP_DIR = directory.sub(/[\\\/]$/, '')
            }

            opts.on("--data DATADIR", "Comment needed here") {|directory|
                # ERROR: dynamic constant assignment - make an opt and
                # have the main script assign since that doesn't seem
                # to be an error?!!?
                #DATA_DIR = directory.sub(/[\\\/]$/, '')
            }
            
            opts.on("--host SERVER:PORT", "Comment needed here") {|serverport|
                if serverport =~ /(.+):(.+)/
                    args.host = @@host_server.new()
                    args.host.server = $1
                    args.host.port = $2.to_i
                else
                    puts "--host requires server and port in the format server:port"
                    exit
                end
            }

            opts.on("--hosts-file HOSTSFILE", "Comment needed here") {|hostsfile|
                args.hostsfile = hostsfile
            }

            opts.on("--hosts-dir HOSTSDIRECTORY", "Comment needed here") {|hostfiledirectory|
                if File.exists?(hosts_dir)            
                    args.hostsdirectory = hostfiledirectory.tr('\\', '/')
                    args.hostsdirectory += '/' unless args.hostsdirectory[-1..-1] == '/'
                else
                    $stdout.puts "warning: given hosts directory does not exist: #{hosts_dir}"
                    hosts_dir = nil
                end
            }

            opts.on("--account ACCOUNT", "Comment needed here") {|account|
                args.account = account
            }

            opts.on("--character CHARACTER", "Comment needed here") {|character|
                args.character = character
            }

            opts.on("--game SERVERPORT", "Comment needed here") {|game|
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

            opts.on("--password PASSWORD", "Comment needed here") {|password|
                args.password = password
            }

            opts.on("--frontend FRONTEND", "Comment needed here") {|frontend|
                args.frontend = frontend
            }

            opts.on("--frontend-command COMMAND", "Comment needed here") {|command|
                args.frontend_command = command
            }
            
            opts.on("--[no-]save", "Comment needed here") {|value|
                args.save = value
            }
    
            opts.on("--wine", "Comment needed here") {
                #TODO: [Jymamon] Other modules shouldn't be looking at ARGV - they should
                #       only use passed options.
                # already used when defining the Wine module
            }

            opts.on("--wine-prefix PREFIX", "Comment needed here") {|prefix|
                #TODO: [Jymamon] Other modules shouldn't be looking at ARGV - they should
                #       only use passed options.
                # already used when defining the Wine module
            }
            
            opts.on("--detachable-client PORT", "Comment needed here") {|port|
                if port =~ /^\d+$/
                  args.detachable_client_port = port
                else
                  $stdout.puts "warning: Port passed to --detachable-client must be numeric. Was #{port}."
                  exit
                end
            }
        }

        opt_parser.parse!(options)

        options.delete_if{ |arg| arg =~ /launcher\.exe/i } # added by Simutronics Game Entry
        
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
