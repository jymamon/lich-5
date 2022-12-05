# Lich5 carveout for init_db

#
# Report an error if Lich 4.4 data is found
#
if File.exists?("#{DATA_DIR}/lich.sav")
  Lich.log "error: Archaic Lich 4.4 configuration found: Please remove #{DATA_DIR}/lich.sav"
  Lich.msgbox "error: Archaic Lich 4.4 configuration found: Please remove #{DATA_DIR}/lich.sav"
  exit
end

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new(REQUIRED_RUBY)
  if (RUBY_PLATFORM =~ /mingw|win/) and (RUBY_PLATFORM !~ /darwin/i)
    require 'fiddle'
    Fiddle::Function.new(DL.dlopen('user32.dll')['MessageBox'], [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT).call(0, 'Upgrade Ruby to version 2.6', "Lich v#{LICH_VERSION}", 16)
  else
    puts "Upgrade Ruby to version 2.6"
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
if arg = ARGV.find { |a| a =~ /^--wine=.+$/i }
  $wine_bin = arg.sub(/^--wine=/, '')
else
  begin
    $wine_bin = `which wine`.strip
  rescue
    $wine_bin = nil
  end
end
if arg = ARGV.find { |a| a =~ /^--wine-prefix=.+$/i }
  $wine_prefix = arg.sub(/^--wine-prefix=/, '')
elsif ENV['WINEPREFIX']
  $wine_prefix = ENV['WINEPREFIX']
elsif ENV['HOME']
  $wine_prefix = ENV['HOME'] + '/.wine'
else
  $wine_prefix = nil
end
if $wine_bin and File.exists?($wine_bin) and File.file?($wine_bin) and $wine_prefix and File.exists?($wine_prefix) and File.directory?($wine_prefix)
  require 'lib/platform/wine'
end
#$wine_bin = nil
#$wine_prefix = nil
#end

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

  paths.each do |path|
    next unless key_exists?(path)

    Registry.open(Registry::HKEY_LOCAL_MACHINE, path).each_value do |_subkey, _type, data|
      dirloc = data
      if path =~ /WIZ32/
        $wiz_fe_loc = dirloc
      elsif path =~ /STORM32/
        $sf_fe_loc = dirloc
      else
        Lich.log("Hammer time, couldn't find me a SIMU FE on a Windows box")
      end
    end
  end
elsif defined?(Wine)
  paths = ['HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Simutronics\\STORM32\\Directory',
           'HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Simutronics\\WIZ32\\Directory']
## Needs improvement - iteration and such.  Quick slam test.
  $sf_fe_loc = Wine.registry_gets('HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Simutronics\\STORM32\\Directory') || ''
  $wiz_fe_loc_temp = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Simutronics\\WIZ32\\Directory')
  $sf_fe_loc_temp = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Simutronics\\STORM32\\Directory')

  if $wiz_fe_loc_temp
    $wiz_fe_loc = $wiz_fe_loc_temp.gsub('\\', '/').gsub('C:', Wine::PREFIX + '/drive_c')
  end
  if $sf_fe_loc_temp
    $sf_fe_loc = $sf_fe_loc_temp.gsub('\\', '/').gsub('C:', Wine::PREFIX + '/drive_c')
  end

  if !File.exist?($sf_fe_loc)
    $sf_fe_loc =~ /SIMU/ ? $sf_fe_loc = $sf_fe_loc.gsub("SIMU", "Simu") : $sf_fe_loc = $sf_fe_loc.gsub("Simu", "SIMU")
    Lich.log("Cannot find STORM equivalent FE to launch.") if !File.exist?($sf_fe_loc)
  end
end

## The following should be deprecated with the direct-frontend-launch-method
## TODO: remove as part of chore/Remove unnecessary Win32 calls
## Temporarily reinstatated for DR

if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
  require 'lib/platform/win32'  
else
  if arg = ARGV.find { |a| a =~ /^--wine=.+$/i }
    $wine_bin = arg.sub(/^--wine=/, '')
  else
    begin
      $wine_bin = `which wine`.strip
    rescue
      $wine_bin = nil
    end
  end
  if arg = ARGV.find { |a| a =~ /^--wine-prefix=.+$/i }
    $wine_prefix = arg.sub(/^--wine-prefix=/, '')
  elsif ENV['WINEPREFIX']
    $wine_prefix = ENV['WINEPREFIX']
  elsif ENV['HOME']
    $wine_prefix = ENV['HOME'] + '/.wine'
  else
    $wine_prefix = nil
  end
  if $wine_bin and File.exists?($wine_bin) and File.file?($wine_bin) and $wine_prefix and File.exists?($wine_prefix) and File.directory?($wine_prefix)
    require 'lib/platform/wine'  
  end
  $wine_bin = nil
  $wine_prefix = nil
end

if ARGV[0] == 'shellexecute'
  args = Marshal.load(ARGV[1].unpack('m')[0])
  Win32.ShellExecute(:lpOperation => args[:op], :lpFile => args[:file], :lpDirectory => args[:dir], :lpParameters => args[:params])
  exit
end

## End of TODO

begin
  require 'sqlite3'
rescue LoadError
  if defined?(Win32)
    r = Win32.MessageBox(:lpText => "Lich needs sqlite3 to save settings and data, but it is not installed.\n\nWould you like to install sqlite3 now?", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_YESNO | Win32::MB_ICONQUESTION))
    if r == Win32::IDIYES
      r = Win32.GetModuleFileName
      if r[:return] > 0
        ruby_bin_dir = File.dirname(r[:lpFilename])
        if File.exists?("#{ruby_bin_dir}\\gem.bat")
          verb = (Win32.isXP? ? 'open' : 'runas')
          # fixme: using --source http://rubygems.org to avoid https because it has been failing to validate the certificate on Windows
          r = Win32.ShellExecuteEx(:fMask => Win32::SEE_MASK_NOCLOSEPROCESS, :lpVerb => verb, :lpFile => "#{ruby_bin_dir}\\#{gem_file}", :lpParameters => 'install sqlite3 --source http://rubygems.org --no-ri --no-rdoc --version 1.3.13')
          if r[:return] > 0
            pid = r[:hProcess]
            sleep 1 while Win32.GetExitCodeProcess(:hProcess => pid)[:lpExitCode] == Win32::STILL_ACTIVE
            r = Win32.MessageBox(:lpText => "Install finished.  Lich will restart now.", :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)
          else
            # ShellExecuteEx failed: this seems to happen with an access denied error even while elevated on some random systems
            r = Win32.ShellExecute(:lpOperation => verb, :lpFile => "#{ruby_bin_dir}\\#{gem_file}", :lpParameters => 'install sqlite3 --source http://rubygems.org --no-ri --no-rdoc --version 1.3.13')
            if r <= 32
              Win32.MessageBox(:lpText => "error: failed to start the sqlite3 installer\n\nfailed command: Win32.ShellExecute(:lpOperation => #{verb.inspect}, :lpFile => \"#{ruby_bin_dir}\\#{gem_file}\", :lpParameters => \"install sqlite3 --source http://rubygems.org --no-ri --no-rdoc --version 1.3.13'\")\n\nerror code: #{Win32.GetLastError}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
              exit
            end
            r = Win32.MessageBox(:lpText => "When the installer is finished, click OK to restart Lich.", :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)
          end
          if r == Win32::IDIOK
            if File.exists?("#{ruby_bin_dir}\\rubyw.exe")
              Win32.ShellExecute(:lpOperation => 'open', :lpFile => "#{ruby_bin_dir}\\rubyw.exe", :lpParameters => "\"#{File.expand_path($PROGRAM_NAME)}\"")
            else
              Win32.MessageBox(:lpText => "error: failed to find rubyw.exe; can't restart Lich for you", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
            end
          else
            # user doesn't want to restart Lich
          end
        else
          Win32.MessageBox(:lpText => "error: Could not find gem.cmd or gem.bat in directory #{ruby_bin_dir}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
        end
      else
        Win32.MessageBox(:lpText => "error: GetModuleFileName failed", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
      end
    else
      # user doesn't want to install sqlite3 gem
    end
  else
    # fixme: no sqlite3 on Linux/Mac
    puts "The sqlite3 gem is not installed (or failed to load), you may need to: sudo gem install sqlite3"
  end
  exit
end

if ((RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)) or ENV['DISPLAY']
  begin
    require 'gtk3'
    HAVE_GTK = true
  rescue LoadError
    if (ENV['RUN_BY_CRON'].nil? or ENV['RUN_BY_CRON'] == 'false') and ARGV.empty? or ARGV.any? { |arg| arg =~ /^--gui$/ } or not $stdout.isatty
      if defined?(Win32)
        r = Win32.MessageBox(:lpText => "Lich uses gtk3 to create windows, but it is not installed.  You can use Lich from the command line (ruby lich.rbw --help) or you can install gtk2 for a point and click interface.\n\nWould you like to install gtk2 now?", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_YESNO | Win32::MB_ICONQUESTION))
        if r == Win32::IDIYES
          r = Win32.GetModuleFileName
          if r[:return] > 0
            ruby_bin_dir = File.dirname(r[:lpFilename])
            if File.exists?("#{ruby_bin_dir}\\gem.cmd")
              gem_file = 'gem.cmd'
            elsif File.exists?("#{ruby_bin_dir}\\gem.bat")
              gem_file = 'gem.bat'
            else
              gem_file = nil
            end
            if gem_file
              verb = (Win32.isXP? ? 'open' : 'runas')
              r = Win32.ShellExecuteEx(:fMask => Win32::SEE_MASK_NOCLOSEPROCESS, :lpVerb => verb, :lpFile => "#{ruby_bin_dir}\\gem.bat", :lpParameters => 'install cairo:1.14.3 gtk2:2.2.5 --source http://rubygems.org --no-ri --no-rdoc')
              if r[:return] > 0
                pid = r[:hProcess]
                sleep 1 while Win32.GetExitCodeProcess(:hProcess => pid)[:lpExitCode] == Win32::STILL_ACTIVE
                r = Win32.MessageBox(:lpText => "Install finished.  Lich will restart now.", :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)
              else
                # ShellExecuteEx failed: this seems to happen with an access denied error even while elevated on some random systems
                r = Win32.ShellExecute(:lpOperation => verb, :lpFile => "#{ruby_bin_dir}\\gem.bat", :lpParameters => 'install cairo:1.14.3 gtk2:2.2.5 --source http://rubygems.org --no-ri --no-rdoc')
                if r <= 32
                  Win32.MessageBox(:lpText => "error: failed to start the gtk3 installer\n\nfailed command: Win32.ShellExecute(:lpOperation => #{verb.inspect}, :lpFile => \"#{ruby_bin_dir}\\gem.bat\", :lpParameters => \"install cairo:1.14.3 gtk2:2.2.5 --source http://rubygems.org --no-ri --no-rdoc\")\n\nerror code: #{Win32.GetLastError}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
                  exit
                end
                r = Win32.MessageBox(:lpText => "When the installer is finished, click OK to restart Lich.", :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)
              end
              if r == Win32::IDIOK
                if File.exists?("#{ruby_bin_dir}\\rubyw.exe")
                  Win32.ShellExecute(:lpOperation => 'open', :lpFile => "#{ruby_bin_dir}\\rubyw.exe", :lpParameters => "\"#{File.expand_path($PROGRAM_NAME)}\"")
                else
                  Win32.MessageBox(:lpText => "error: failed to find rubyw.exe; can't restart Lich for you", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
                end
              else
                # user doesn't want to restart Lich
              end
            else
              Win32.MessageBox(:lpText => "error: Could not find gem.bat in directory #{ruby_bin_dir}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
            end
          else
            Win32.MessageBox(:lpText => "error: GetModuleFileName failed", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
          end
        else
          # user doesn't want to install gtk3 gem
        end
      else
        # fixme: no gtk3 on Linux/Mac
        puts "The gtk3 gem is not installed (or failed to load), you may need to: sudo gem install gtk3"
      end
      exit
    else
      # gtk is optional if command line arguments are given or started in a terminal
      HAVE_GTK = false
      @early_gtk_error = "warning: failed to load GTK\n\t#{$!}\n\t#{$!.backtrace.join("\n\t")}"
    end
  end
else
  HAVE_GTK = false
  @early_gtk_error = "info: DISPLAY environment variable is not set; not trying gtk"
end

unless File.exists?(LICH_DIR)
  begin
    Dir.mkdir(LICH_DIR)
  rescue
    message = "An error occured while attempting to create directory #{LICH_DIR}\n\n"
    if not File.exists?(LICH_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop)
      message.concat "This was likely because the parent directory (#{LICH_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop}) doesn't exist."
    elsif defined?(Win32) and (Win32.GetVersionEx[:dwMajorVersion] >= 6) and (dir !~ /^[A-z]\:\\(Users|Documents and Settings)/)
      message.concat "This was likely because Lich doesn't have permission to create files and folders here.  It is recommended to put Lich in your Documents folder."
    else
      message.concat $!
    end
    Lich.msgbox(:message => message, :icon => :error)
    exit
  end
end

Dir.chdir(LICH_DIR)

unless File.exists?(TEMP_DIR)
  begin
    Dir.mkdir(TEMP_DIR)
  rescue
    message = "An error occured while attempting to create directory #{TEMP_DIR}\n\n"
    if not File.exists?(TEMP_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop)
      message.concat "This was likely because the parent directory (#{TEMP_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop}) doesn't exist."
    elsif defined?(Win32) and (Win32.GetVersionEx[:dwMajorVersion] >= 6) and (dir !~ /^[A-z]\:\\(Users|Documents and Settings)/)
      message.concat "This was likely because Lich doesn't have permission to create files and folders here.  It is recommended to put Lich in your Documents folder."
    else
      message.concat $!
    end
    Lich.msgbox(:message => message, :icon => :error)
    exit
  end
end

begin
  debug_filename = "#{TEMP_DIR}/debug-#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.log"
  $stderr = File.open(debug_filename, 'w')
rescue
  message = "An error occured while attempting to create file #{debug_filename}\n\n"
  if defined?(Win32) and (TEMP_DIR !~ /^[A-z]\:\\(Users|Documents and Settings)/) and not Win32.isXP?
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
Lich.log @early_gtk_error if @early_gtk_error
@early_gtk_error = nil


[DATA_DIR, SCRIPT_DIR, "#{SCRIPT_DIR}/custom", MAP_DIR, LOG_DIR, BACKUP_DIR].each { |required_directory|
  unless File.exists?(required_directory)
    begin
      Dir.mkdir(required_directory)
    rescue
      Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
      Lich.msgbox(:message => "An error occured while attempting to create directory #{required_directory}\n\n#{$!}", :icon => :error)
      exit
    end
  end
}
Lich.init_db

#
# only keep the last 20 debug files
#
if Dir.entries(TEMP_DIR).length > 20 # avoid NIL response
  Dir.entries(TEMP_DIR).find_all { |fn| fn =~ /^debug-\d+-\d+-\d+-\d+-\d+-\d+\.log$/ }.sort.reverse[20..-1].each { |oldfile|
    begin
      File.delete("#{TEMP_DIR}/#{oldfile}")
    rescue
      Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    end
  }
end

if (RUBY_VERSION =~ /^2\.[012]\./)
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
