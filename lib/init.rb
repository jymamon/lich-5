# Lich5 carveout for init_db

# Ugly hack to preserve the behavior of force_gui being false if there are any other options and true if
# there are not.
if ARGV.empty?
  ARGV.push('--gui')
else
  # Must be first so subsequent --gui options will undo this parameter.
  ARGV.unshift('--no-gui')
end

# instance variable syntax necessarry until this can be further refactored for init to only
# expose methods the application invokes instead of running code upon inclusion.
@options = Parser.parse(ARGV)

# Moved from lib/constants.rb. These are all configurable, but setting a custom
# lich dir doesn't necessarily change the others relative to that. It probably should.
# LIB_DIR can't practically be reconfigured - we just loaded the options from there -
# but we define it in the options class to be consistent with everything else.
BACKUP_DIR = @options.backupdir
DATA_DIR = @options.datadir
LIB_DIR = @options.libdir
LICH_DIR = @options.lichdir
LOG_DIR = @options.mapdir
MAP_DIR = @options.mapdir
SCRIPT_DIR = @options.scriptdir
TEMP_DIR = @options.tempdir

# add this so that require statements can take the form 'lib/file'
$LOAD_PATH << "#{LICH_DIR}"

# deprecated
$lich_dir = "#{LICH_DIR}/"
$temp_dir = "#{TEMP_DIR}/"
$script_dir = "#{SCRIPT_DIR}/"
$data_dir = "#{DATA_DIR}/"

#
# Report an error if Lich 4.4 data is found
#
if File.exist?("#{DATA_DIR}/lich.sav")
  Lich.log "error: Archaic Lich 4.4 configuration found: Please remove #{DATA_DIR}/lich.sav"
  Lich.msgbox "error: Archaic Lich 4.4 configuration found: Please remove #{DATA_DIR}/lich.sav"
  exit
end

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new(REQUIRED_RUBY)
  if (RUBY_PLATFORM =~ /mingw|win/) and (RUBY_PLATFORM !~ /darwin/i)
    require 'fiddle'
    Fiddle::Function.new(DL.dlopen('user32.dll')['MessageBox'], [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT).call(0, 'Upgrade Ruby to version 2.6', "Lich v#{LICH_VERSION}", 16)
  else
    puts 'Upgrade Ruby to version 2.6'
  end
  exit
end

begin
  # stupid workaround for Windows
  # seems to avoid a 10 second lag when starting lnet, without adding a 10 second lag at startup
  require 'openssl'
  OpenSSL::PKey::RSA.new(512)
rescue LoadError
  nil # not required for basic Lich; however, lnet and repository scripts will fail without openssl
rescue
  nil
end

# check for Linux | WINE (and maybe in future MacOS | WINE) first due to low population
# segment of code unmodified from Lich4 (Tillmen)
if @options.wine
  $wine_bin = @options.wine
else
  begin
    $wine_bin = `which wine`.strip
  rescue
    $wine_bin = nil
  end
end
if @options.wineprefix
  $wine_prefix = @options.wineprefix
elsif ENV['WINEPREFIX']
  $wine_prefix = ENV['WINEPREFIX']
elsif ENV['HOME']
  $wine_prefix = "#{ENV['HOME']}/.wine"
else
  $wine_prefix = nil
end
require 'lib/platform/wine' if $wine_bin and File.exist?($wine_bin) and File.file?($wine_bin) and $wine_prefix and File.exist?($wine_prefix) and File.directory?($wine_prefix)
# $wine_bin = nil
# $wine_prefix = nil
# end

# find the FE locations for Win and for Linux | WINE

if (RUBY_PLATFORM =~ /mingw|win/i) && (RUBY_PLATFORM !~ /darwin/i)
  require 'win32/registry'
  include Win32

  paths = ['SOFTWARE\\WOW6432Node\\Simutronics\\STORM32',
           'SOFTWARE\\WOW6432Node\\Simutronics\\WIZ32']

  def key_exists?(path)
    Registry.open(Registry::HKEY_LOCAL_MACHINE, path, ::Win32::Registry::KEY_READ)
    true
  rescue StandardError
    false
  end

  paths.each { |path|
    next unless key_exists?(path)

    Registry.open(Registry::HKEY_LOCAL_MACHINE, path).each_value { |_subkey, _type, data|
      dirloc = data
      if path =~ /WIZ32/
        $wiz_fe_loc = dirloc
      elsif path =~ /STORM32/
        $sf_fe_loc = dirloc
      else
        Lich.log("Hammer time, couldn't find me a SIMU FE on a Windows box")
      end
    }
  }
elsif defined?(Wine)
  ## Needs improvement - iteration and such.  Quick slam test.
  $sf_fe_loc = Wine.registry_gets('HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Simutronics\\STORM32\\Directory') || ''
  $wiz_fe_loc_temp = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Simutronics\\WIZ32\\Directory')
  $sf_fe_loc_temp = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Simutronics\\STORM32\\Directory')

  $wiz_fe_loc = $wiz_fe_loc_temp.gsub('\\', '/').gsub('C:', "#{Wine::PREFIX}/drive_c") if $wiz_fe_loc_temp
  $sf_fe_loc = $sf_fe_loc_temp.gsub('\\', '/').gsub('C:', "#{Wine::PREFIX}/drive_c") if $sf_fe_loc_temp

  unless File.exist?($sf_fe_loc)
    $sf_fe_loc =~ /SIMU/ ? $sf_fe_loc = $sf_fe_loc.gsub('SIMU', 'Simu') : $sf_fe_loc = $sf_fe_loc.gsub('Simu', 'SIMU')
    Lich.log('Cannot find STORM equivalent FE to launch.') unless File.exist?($sf_fe_loc)
  end
end

## The following should be deprecated with the direct-frontend-launch-method
## TODO: remove as part of chore/Remove unnecessary Win32 calls
## Temporarily reinstatated for DR

if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
  require 'lib/platform/win32'
else
  if @options.wine
    $wine_bin = @options.wine
  else
    begin
      $wine_bin = `which wine`.strip
    rescue
      $wine_bin = nil
    end
  end
  if @options.wineprefix
    $wine_prefix = @options.wineprefix
  elsif ENV['WINEPREFIX']
    $wine_prefix = ENV['WINEPREFIX']
  elsif ENV['HOME']
    $wine_prefix = "#{ENV['HOME']}/.wine"
  else
    $wine_prefix = nil
  end
  require 'lib/platform/wine' if $wine_bin and File.exist?($wine_bin) and File.file?($wine_bin) and $wine_prefix and File.exist?($wine_prefix) and File.directory?($wine_prefix)
  $wine_bin = nil
  $wine_prefix = nil
end

if @options.shellexecute
  args = Marshal.load(@options.shellexecute)
  Win32.ShellExecute(:lpOperation => args[:op], :lpFile => args[:file], :lpDirectory => args[:dir], :lpParameters => args[:params])
  exit
end

## End of TODO

required_modules = [
  # :name -> The module to require/install
  # :version -> The version of the module to require/install
  # :reason ->  Displayed to the used. This should make sense in the sentence "Lich needs {:name} {:reason}, but it is not installed."
  # :condition -> Optional action which returns true/false if the module is required for this invocation
  {
    :name => 'sqlite3',
    :version => '1.3.13',
    :reason => 'to save settings and data',
  },
  {
    :name => 'gtk3',
    :version => '4.0.3',
    :reason => 'to create windows',
    :condition => lambda {
      return(
        ((RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)) or
        ENV['DISPLAY'] or
        ((ENV['RUN_BY_CRON'].nil? or ENV['RUN_BY_CRON'] == 'false') and @options.force_gui) or
        !$stdout.isatty
      )
    },
  },
]

required_modules.each { |required_module|
  begin
    if !required_module.key?(:condition) || required_module[:condition].call
      require required_module[:name]
    else
      required_module[:result] = 'Not required.'
    end
  rescue LoadError
    if defined?(Win32)
      result = Win32.MessageBox(
        :lpText => "Lich needs #{required_module[:name]} #{required_module[:reason]}, but it is not installed.\n\nWould you like to install #{required_module[:name]} now?", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_YESNO | Win32::MB_ICONQUESTION)
      )

      if result == Win32::IDIYES
        if gem_file
          # FIXME: using --source http://rubygems.org to avoid https because it has been failing to validate the certificate on Windows
          result = Win32.ShellExecuteEx(:lpVerb => gem_verb, :lpFile => gem_file, :lpParameters => "install #{required_module[:name]} --version #{required_module[:version]} #{gem_default_parameters}")

          if result[:return] > 0
            pid = result[:hProcess]
            # Use to indicate that the hProcess member receives the process handle. This handle is typically used to allow an application to find out when a process created with ShellExecuteEx terminates
            sleep 1 while Win32.GetExitCodeProcess(:hProcess => pid)[:lpExitCode] == Win32::STILL_ACTIVE
            result = Win32.MessageBox(:lpText => 'Install finished.  Lich will restart now.', :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)

          else
            # ShellExecuteEx failed: this seems to happen with an access denied error even while elevated on some random systems
            # We don't wait for this process to exit so install may still be ongoing when we ask to restart lich? Or does lack
            # of :fMask => Win32::SEE_MASK_NOCLOSEPROCESS address that.
            result = Win32.ShellExecute(:lpOperation => gem_verb, :lpFile => gem_file, :lpParameters => "install #{required_module[:name]} --version #{required_module[:version]} #{gem_default_parameters}")

            if result <= 32
              Win32.MessageBox(:lpText => "error: failed to install #{required_module[:name]}.\n\nfailed command: Win32.ShellExecute(:lpOperation => #{gem_verb.inspect}, :lpFile => '#{gem_file}', :lpParameters => \"install sqlite3 --version 1.3.13 #{gem_default_parameters}'\")\n\nerror code: #{Win32.GetLastError}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
              exit
            end

            result = Win32.MessageBox(:lpText => 'When the installer is finished, click OK to restart Lich.', :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)
          end

          # Result is either the result of ShellExecute on the gem_file command or the result of
          # requesting that the used clicks OK to restart lich.
          if result == Win32::IDIOK
            if File.exist?("#{ruby_bin_dir}\\rubyw.exe")
              Win32.ShellExecute(:lpOperation => 'open', :lpFile => "#{ruby_bin_dir}\\rubyw.exe", :lpParameters => "\"#{File.expand_path($PROGRAM_NAME)}\"")
              exit
            else
              Win32.MessageBox(:lpText => "error: failed to find rubyw.exe; can't restart Lich for you", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
              required_module[:result] = "Failed to find rubyw.exe; can't restart Lich."
            end
          else
            # user doesn't want to restart Lich
            required_module[:result] = 'Installed, but lich not restarted.'
          end

        else
          Win32.MessageBox(:lpText => "error: Could not find gem.cmd or gem.bat in directory #{ruby_bin_dir}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
          required_module[:result] = "Could not find gem.cmd or gem.bat in directory #{ruby_bin_dir}."
        end

      else
        # user doesn't want to install gem
        required_module[:result] = 'User declined installation.'
      end
    else
      # FIXME: no module on Linux/Mac
      puts "The #{required_module[:name]} gem is not installed (or failed to load), you may need to: sudo gem install #{required_module[:name]}"
      required_module[:result] = 'Install skipped. Not a Win32 platform.'
    end
  end
}

HAVE_GTK = Module.const_defined?(:Gtk)

unless File.exist?(LICH_DIR)
  begin
    Dir.mkdir(LICH_DIR)
  rescue
    message = "An error occured while attempting to create directory #{LICH_DIR}\n\n"
    if !File.exist?(LICH_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop)
      message.concat "This was likely because the parent directory (#{LICH_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop}) doesn't exist."
    elsif defined?(Win32) and (Win32.GetVersionEx[:dwMajorVersion] >= 6) and (dir !~ /^[A-z]:\\(Users|Documents and Settings)/)
      message.concat "This was likely because Lich doesn't have permission to create files and folders here.  It is recommended to put Lich in your Documents folder."
    else
      message.concat $!
    end
    Lich.msgbox(:message => message, :icon => :error)
    exit
  end
end

Dir.chdir(LICH_DIR)

unless File.exist?(TEMP_DIR)
  begin
    Dir.mkdir(TEMP_DIR)
  rescue
    message = "An error occured while attempting to create directory #{TEMP_DIR}\n\n"
    if !File.exist?(TEMP_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop)
      message.concat "This was likely because the parent directory (#{TEMP_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop}) doesn't exist."
    elsif defined?(Win32) and (Win32.GetVersionEx[:dwMajorVersion] >= 6) and (dir !~ /^[A-z]:\\(Users|Documents and Settings)/)
      message.concat "This was likely because Lich doesn't have permission to create files and folders here.  It is recommended to put Lich in your Documents folder."
    else
      message.concat $!
    end
    Lich.msgbox(:message => message, :icon => :error)
    exit
  end
end

begin
  debug_filename = "#{TEMP_DIR}/debug-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.log"
  $stderr = File.open(debug_filename, 'w')
rescue
  message = "An error occured while attempting to create file #{debug_filename}\n\n"
  if defined?(Win32) and (TEMP_DIR !~ /^[A-z]:\\(Users|Documents and Settings)/) and !Win32.isXP?
    message.concat "This was likely because Lich doesn't have permission to create files and folders here.  It is recommended to put Lich in your Documents folder."
  else
    message.concat $!
  end
  Lich.msgbox(:message => message, :icon => :error)
  exit
end

$stderr.sync = true
Lich.log "info: Lich #{LICH_VERSION}"
Lich.log "info: Ruby #{RUBY_VERSION}"
Lich.log "info: #{RUBY_PLATFORM}"
required_modules.each { |required_module|
  if required_module.key?(:result)
    Lich.log "info: #{required_module[:name]} install result: #{required_module[:result]}."
  else
    Lich.log "info: #{required_module[:name]} was already availble."
  end
}

[DATA_DIR, SCRIPT_DIR, "#{SCRIPT_DIR}/custom", MAP_DIR, LOG_DIR, BACKUP_DIR].each { |required_directory|
  unless File.exist?(required_directory)
    begin
      Dir.mkdir(required_directory)
    rescue
      Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
      Lich.msgbox(:message => "An error occured while attempting to create directory #{required_directory}\n\n#{$!}", :icon => :error)
      exit
    end
  end
}

Lich.init_db("#{@options.datadir}/lich.db3")

#
# only keep the last 20 debug files
#
if Dir.entries(TEMP_DIR).length > 20 # avoid NIL response
  Dir.entries(TEMP_DIR).find_all { |fn| fn =~ /^debug-\d+-\d+-\d+-\d+-\d+-\d+\.log$/ }.sort.reverse[19..].each { |oldfile|
    begin
      File.delete("#{TEMP_DIR}/#{oldfile}")
    rescue
      Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    end
  }
end

if RUBY_VERSION =~ /^2\.[012]\./
  begin
    did_trusted_defaults = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='did_trusted_defaults';")
  rescue SQLite3::BusyException
    sleep 0.1
    retry
  end
  if did_trusted_defaults.nil?
    Script.trust('repository')
    Script.trust('lnet')
    Script.trust('narost')
    begin
      Lich.db.execute("INSERT INTO lich_settings(name,value) VALUES('did_trusted_defaults', 'yes');")
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
  end
end
