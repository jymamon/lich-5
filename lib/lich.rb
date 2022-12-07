module Lich
  @@hosts_file           = nil
  @@lich_db              = nil
  @@last_warn_deprecated = 0
  @@lich_db_file         = nil

  # settings
  @@display_lichid       = nil # boolean
  @@display_uid          = nil # boolean
  @@track_autosort_state = nil # boolean
  @@track_dark_mode      = nil # boolean
  @@track_layout_state   = nil # boolean

  def self.method_missing(arg1, arg2 = '')
    if (Time.now.to_i - @@last_warn_deprecated) > 300
      respond "--- warning: Lich.* variables will stop working in a future version of Lich.  Use Vars.* (offending script: #{Script.current.name || 'unknown'})"
      @@last_warn_deprecated = Time.now.to_i
    end
    Vars.method_missing(arg1, arg2)
  end

  def self.seek(fe)
    if fe =~ /wizard/
      return $wiz_fe_loc
    elsif fe =~ /stormfront/
      return $sf_fe_loc
    end

    pp 'Landed in get_simu_launcher method'
  end

  def self.db
    @@lich_db ||= SQLite3::Database.new(@@lich_db_file)
    # if $SAFE == 0
    #  @@lich_db ||= SQLite3::Database.new(@@lich_db_file)
    # else
    #  nil
    # end
  end

  def self.init_db(database_file)
    # TODO: Parameter validation
    @@lich_db_file = database_file
    begin
      Lich.db.execute('CREATE TABLE IF NOT EXISTS script_setting (script TEXT NOT NULL, name TEXT NOT NULL, value BLOB, PRIMARY KEY(script, name));')
      Lich.db.execute('CREATE TABLE IF NOT EXISTS script_auto_settings (script TEXT NOT NULL, scope TEXT, hash BLOB, PRIMARY KEY(script, scope));')
      Lich.db.execute('CREATE TABLE IF NOT EXISTS lich_settings (name TEXT NOT NULL, value TEXT, PRIMARY KEY(name));')
      Lich.db.execute('CREATE TABLE IF NOT EXISTS uservars (scope TEXT NOT NULL, hash BLOB, PRIMARY KEY(scope));')
      Lich.db.execute('CREATE TABLE IF NOT EXISTS trusted_scripts (name TEXT NOT NULL);') if RUBY_VERSION =~ /^2\.[012]\./
      Lich.db.execute('CREATE TABLE IF NOT EXISTS simu_game_entry (character TEXT NOT NULL, game_code TEXT NOT NULL, data BLOB, PRIMARY KEY(character, game_code));')
      Lich.db.execute('CREATE TABLE IF NOT EXISTS enable_inventory_boxes (player_id INTEGER NOT NULL, PRIMARY KEY(player_id));')
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
  end

  def self.class_variable_get(*a); nil; end

  def self.class_eval(*a);         nil; end

  def self.module_eval(*a);        nil; end

  def self.log(msg)
    $stderr.puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}: #{msg}"
  end

  def self.msgbox(args)
    if defined?(Win32)
      if args[:buttons] == :ok_cancel
        buttons = Win32::MB_OKCANCEL
      elsif args[:buttons] == :yes_no
        buttons = Win32::MB_YESNO
      else
        buttons = Win32::MB_OK
      end
      if args[:icon] == :error
        icon = Win32::MB_ICONERROR
      elsif args[:icon] == :question
        icon = Win32::MB_ICONQUESTION
      elsif args[:icon] == :warning
        icon = Win32::MB_ICONWARNING
      else
        icon = 0
      end
      args[:title] ||= "Lich v#{LICH_VERSION}"
      r = Win32.MessageBox(:lpText => args[:message], :lpCaption => args[:title], :uType => (buttons | icon))
      if r == Win32::IDIOK
        return :ok
      elsif r == Win32::IDICANCEL
        return :cancel
      elsif r == Win32::IDIYES
        return :yes
      elsif r == Win32::IDINO
        return :no
      else
        return nil
      end
    elsif defined?(Gtk)
      if args[:buttons] == :ok_cancel
        buttons = Gtk::MessageDialog::BUTTONS_OK_CANCEL
      elsif args[:buttons] == :yes_no
        buttons = Gtk::MessageDialog::BUTTONS_YES_NO
      else
        buttons = Gtk::MessageDialog::BUTTONS_OK
      end
      if args[:icon] == :error
        type = Gtk::MessageDialog::ERROR
      elsif args[:icon] == :question
        type = Gtk::MessageDialog::QUESTION
      elsif args[:icon] == :warning
        type = Gtk::MessageDialog::WARNING
      else
        type = Gtk::MessageDialog::INFO
      end
      dialog = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL, type, buttons, args[:message])
      args[:title] ||= "Lich v#{LICH_VERSION}"
      dialog.title = args[:title]
      response = nil
      dialog.run { |r|
        response = r
        dialog.destroy
      }
      if response == Gtk::Dialog::RESPONSE_OK
        return :ok
      elsif response == Gtk::Dialog::RESPONSE_CANCEL
        return :cancel
      elsif response == Gtk::Dialog::RESPONSE_YES
        return :yes
      elsif response == Gtk::Dialog::RESPONSE_NO
        return :no
      else
        return nil
      end
    elsif $stdout.isatty
      $stdout.puts(args[:message])
      return nil
    end
  end

  def self.get_simu_launcher
    if defined?(Win32)
      begin
        launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
        launcher_cmd = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealCommand')[:lpData]
        launcher_cmd = Win32.RegQueryValueEx(:hKey => launcher_key)[:lpData] if launcher_cmd.nil? or launcher_cmd.empty?
        return launcher_cmd
      ensure
        Win32.RegCloseKey(:hKey => launcher_key) rescue nil
      end
    elsif defined?(Wine)
      launcher_cmd = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand')
      launcher_cmd = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\') unless launcher_cmd and !launcher_cmd.empty?
      return launcher_cmd
    else
      return nil
    end
  end

  def self.link_to_sge
    if defined?(Win32)
      if Win32.admin?
        begin
          launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Simutronics\\Launcher', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
          r = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealDirectory')
          if (r[:return] == 0) and !r[:lpData].empty?
            # already linked
            return true
          end

          r = Win32.GetModuleFileName
          unless r[:return] > 0
            # fixme
            return false
          end

          new_launcher_dir = "\"#{r[:lpFilename]}\" \"#{File.expand_path($PROGRAM_NAME)}\" "
          r = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'Directory')
          launcher_dir = r[:lpData]
          r = Win32.RegSetValueEx(:hKey => launcher_key, :lpValueName => 'RealDirectory', :dwType => Win32::REG_SZ, :lpData => launcher_dir)
          return false unless r == 0

          r = Win32.RegSetValueEx(:hKey => launcher_key, :lpValueName => 'Directory', :dwType => Win32::REG_SZ, :lpData => new_launcher_dir)
          return (r == 0)
        ensure
          Win32.RegCloseKey(:hKey => launcher_key) rescue nil
        end
      else
        begin
          r = Win32.GetModuleFileName
          file = (r[:return] > 0 ? r[:lpFilename] : 'rubyw.exe')
          params = "#{$PROGRAM_NAME.split(/\/|\\/).last} --link-to-sge"
          r = Win32.ShellExecuteEx(:lpFile => file, :lpParameters => params)
          if r[:return] > 0
            process_id = r[:hProcess]
            sleep 0.2 while Win32.GetExitCodeProcess(:hProcess => process_id)[:lpExitCode] == Win32::STILL_ACTIVE
            sleep 3
          else
            Win32.ShellExecute(:lpFile => file, :lpParameters => params)
            sleep 6
          end
        rescue
          Lich.msgbox(:message => $!)
        end
      end
    elsif defined?(Wine)
      launch_dir = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory')
      return false unless launch_dir

      lich_launch_dir = "#{File.expand_path($PROGRAM_NAME)} --wine=#{Wine::BIN} --wine-prefix=#{Wine::PREFIX}  "
      result = true
      if launch_dir
        if launch_dir =~ /lich/i
          $stdout.puts '--- warning: Lich appears to already be installed to the registry'
          Lich.log 'warning: Lich appears to already be installed to the registry'
          Lich.log 'info: launch_dir: ' + launch_dir
        else
          result &&= Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory', launch_dir)
          result &&= Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory', lich_launch_dir)
        end
      end
      return result
    else
      return false
    end
  end

  def self.unlink_from_sge
    if defined?(Win32)
      if Win32.admin?
        begin
          launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Simutronics\\Launcher', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
          real_directory = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealDirectory')[:lpData]
          if real_directory.nil? or real_directory.empty?
            # not linked
            return true
          end

          r = Win32.RegSetValueEx(:hKey => launcher_key, :lpValueName => 'Directory', :dwType => Win32::REG_SZ, :lpData => real_directory)
          return false unless r == 0

          r = Win32.RegDeleteValue(:hKey => launcher_key, :lpValueName => 'RealDirectory')
          return (r == 0)
        ensure
          Win32.RegCloseKey(:hKey => launcher_key) rescue nil
        end
      else
        begin
          r = Win32.GetModuleFileName
          file = (r[:return] > 0 ? r[:lpFilename] : 'rubyw.exe')
          params = "#{$PROGRAM_NAME.split(/\/|\\/).last} --unlink-from-sge"
          r = Win32.ShellExecuteEx(:lpFile => file, :lpParameters => params)
          if r[:return] > 0
            process_id = r[:hProcess]
            sleep 0.2 while Win32.GetExitCodeProcess(:hProcess => process_id)[:lpExitCode] == Win32::STILL_ACTIVE
            sleep 3
          else
            Win32.ShellExecute(:lpFile => file, :lpParameters => params)
            sleep 6
          end
        rescue
          Lich.msgbox(:message => $!)
        end
      end
    elsif defined?(Wine)
      real_launch_dir = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory')
      result = true
      if real_launch_dir and !real_launch_dir.empty?
        result &&= Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory', real_launch_dir)
        result &&= Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory', '')
      end
      return result
    else
      return false
    end
  end

  def self.link_to_sal
    if defined?(Win32)
      if Win32.admin?
        begin
          # FIXME: 64 bit browsers?
          launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
          r = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealCommand')
          if (r[:return] == 0) and !r[:lpData].empty?
            # already linked
            return true
          end

          r = Win32.GetModuleFileName
          unless r[:return] > 0
            # fixme
            return false
          end

          new_launcher_cmd = "\"#{r[:lpFilename]}\" \"#{File.expand_path($PROGRAM_NAME)}\" %1"
          r = Win32.RegQueryValueEx(:hKey => launcher_key)
          launcher_cmd = r[:lpData]
          r = Win32.RegSetValueEx(:hKey => launcher_key, :lpValueName => 'RealCommand', :dwType => Win32::REG_SZ, :lpData => launcher_cmd)
          return false unless r == 0

          r = Win32.RegSetValueEx(:hKey => launcher_key, :dwType => Win32::REG_SZ, :lpData => new_launcher_cmd)
          return (r == 0)
        ensure
          Win32.RegCloseKey(:hKey => launcher_key) rescue nil
        end
      else
        begin
          r = Win32.GetModuleFileName
          file = (r[:return] > 0 ? r[:lpFilename] : 'rubyw.exe')
          params = "#{$PROGRAM_NAME.split(/\/|\\/).last} --link-to-sal"
          r = Win32.ShellExecuteEx(:lpFile => file, :lpParameters => params)
          if r[:return] > 0
            process_id = r[:hProcess]
            sleep 0.2 while Win32.GetExitCodeProcess(:hProcess => process_id)[:lpExitCode] == Win32::STILL_ACTIVE
            sleep 3
          else
            Win32.ShellExecute(:lpFile => file, :lpParameters => params)
            sleep 6
          end
        rescue
          Lich.msgbox(:message => $!)
        end
      end
    elsif defined?(Wine)
      launch_cmd = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\')
      return false unless launch_cmd

      new_launch_cmd = "#{File.expand_path($PROGRAM_NAME)} --wine=#{Wine::BIN} --wine-prefix=#{Wine::PREFIX} %1"
      result = true
      if launch_cmd
        if launch_cmd =~ /lich/i
          $stdout.puts '--- warning: Lich appears to already be installed to the registry'
          Lich.log 'warning: Lich appears to already be installed to the registry'
          Lich.log 'info: launch_cmd: ' + launch_cmd
        else
          result &&= Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand', launch_cmd)
          result &&= Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\', new_launch_cmd)
        end
      end
      return result
    else
      return false
    end
  end

  def self.unlink_from_sal
    if defined?(Win32)
      if Win32.admin?
        begin
          launcher_key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command', :samDesired => (Win32::KEY_ALL_ACCESS | Win32::KEY_WOW64_32KEY))[:phkResult]
          real_directory = Win32.RegQueryValueEx(:hKey => launcher_key, :lpValueName => 'RealCommand')[:lpData]
          if real_directory.nil? or real_directory.empty?
            # not linked
            return true
          end

          r = Win32.RegSetValueEx(:hKey => launcher_key, :dwType => Win32::REG_SZ, :lpData => real_directory)
          return false unless r == 0

          r = Win32.RegDeleteValue(:hKey => launcher_key, :lpValueName => 'RealCommand')
          return (r == 0)
        ensure
          Win32.RegCloseKey(:hKey => launcher_key) rescue nil
        end
      else
        begin
          r = Win32.GetModuleFileName
          file = (r[:return] > 0 ? r[:lpFilename] : 'rubyw.exe')
          params = "#{$PROGRAM_NAME.split(/\/|\\/).last} --unlink-from-sal"
          r = Win32.ShellExecuteEx(:lpFile => file, :lpParameters => params)
          if r[:return] > 0
            process_id = r[:hProcess]
            sleep 0.2 while Win32.GetExitCodeProcess(:hProcess => process_id)[:lpExitCode] == Win32::STILL_ACTIVE
            sleep 3
          else
            Win32.ShellExecute(:lpFile => file, :lpParameters => params)
            sleep 6
          end
        rescue
          Lich.msgbox(:message => $!)
        end
      end
    elsif defined?(Wine)
      real_launch_cmd = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand')
      result = true
      if real_launch_cmd and !real_launch_cmd.empty?
        result &&= Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\', real_launch_cmd)
        result &&= Wine.registry_puts('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand', '')
      end
      return result
    else
      return false
    end
  end

  def self.hosts_file
    Lich.find_hosts_file if @@hosts_file.nil?
    return @@hosts_file
  end

  def self.find_hosts_file
    if defined?(Win32)
      begin
        key = Win32.RegOpenKeyEx(:hKey => Win32::HKEY_LOCAL_MACHINE, :lpSubKey => 'System\\CurrentControlSet\\Services\\Tcpip\\Parameters', :samDesired => Win32::KEY_READ)[:phkResult]
        hosts_path = Win32.RegQueryValueEx(:hKey => key, :lpValueName => 'DataBasePath')[:lpData]
      ensure
        Win32.RegCloseKey(:hKey => key) rescue nil
      end

      if hosts_path
        windir = (ENV['windir'] || ENV['SYSTEMROOT'] || 'c:\windows')
        hosts_path.gsub('%SystemRoot%', windir)
        hosts_file = "#{hosts_path}\\hosts"
        return (@@hosts_file = hosts_file) if File.exist?(hosts_file)
      end

      if (windir = (ENV['windir'] || ENV['SYSTEMROOT'])) and File.exist?("#{windir}\\system32\\drivers\\etc\\hosts")
        return (@@hosts_file = "#{windir}\\system32\\drivers\\etc\\hosts")
      end

      for drive in ['C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
        for windir in ['winnt', 'windows']
          return (@@hosts_file = "#{drive}:\\#{windir}\\system32\\drivers\\etc\\hosts") if File.exist?("#{drive}:\\#{windir}\\system32\\drivers\\etc\\hosts")
        end
      end

    elsif File.exist?('/etc/hosts') # Linux/Mac
      return (@@hosts_file = '/etc/hosts')
    elsif File.exist?('/private/etc/hosts')
      return (@@hosts_file = '/private/etc/hosts')
    end
    return (@@hosts_file = false)
  end

  def self.modify_hosts(game_host)
    if Lich.hosts_file and File.exist?(Lich.hosts_file)
      at_exit { Lich.restore_hosts }
      Lich.restore_hosts
      return false if File.exist?("#{Lich.hosts_file}.bak")

      begin
        # copy hosts to hosts.bak
        File.open("#{Lich.hosts_file}.bak", 'w') { |hb| File.open(Lich.hosts_file) { |h| hb.write(h.read) } }
      rescue
        File.unlink("#{Lich.hosts_file}.bak") if File.exist?("#{Lich.hosts_file}.bak")
        return false
      end
      File.open(Lich.hosts_file, 'a') { |f| f.write "\r\n127.0.0.1\t\t#{game_host}" }
      return true
    else
      return false
    end
  end

  def self.restore_hosts
    if Lich.hosts_file and File.exist?(Lich.hosts_file)
      begin
        # FIXME: use rename instead?  test rename on windows
        if File.exist?("#{Lich.hosts_file}.bak")
          File.open("#{Lich.hosts_file}.bak") { |infile|
            File.open(Lich.hosts_file, 'w') { |outfile|
              outfile.write(infile.read)
            }
          }
          File.unlink "#{Lich.hosts_file}.bak"
        end
      rescue
        $stdout.puts "--- error: restore_hosts: #{$!}"
        Lich.log "error: restore_hosts: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        exit(1)
      end
    end
  end

  def self.inventory_boxes(player_id)
    begin
      v = Lich.db.get_first_value('SELECT player_id FROM enable_inventory_boxes WHERE player_id=?;', player_id.to_i)
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    if v
      true
    else
      false
    end
  end

  def self.set_inventory_boxes(player_id, enabled)
    if enabled
      begin
        Lich.db.execute('INSERT OR REPLACE INTO enable_inventory_boxes values(?);', player_id.to_i)
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
    else
      begin
        Lich.db.execute('DELETE FROM enable_inventory_boxes where player_id=?;', player_id.to_i)
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
    end
    nil
  end

  def self.win32_launch_method
    begin
      val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='win32_launch_method';")
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    val
  end

  def self.win32_launch_method=(val)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('win32_launch_method',?);", val.to_s.encode('UTF-8'))
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    nil
  end

  def self.fix_game_host_port(gamehost, gameport)
    if (gamehost == 'gs-plat.simutronics.net') and (gameport.to_i == 10121)
      gamehost = 'storm.gs4.game.play.net'
      gameport = 10124
    elsif (gamehost == 'gs3.simutronics.net') and (gameport.to_i == 4900)
      gamehost = 'storm.gs4.game.play.net'
      gameport = 10024
    elsif (gamehost == 'gs4.simutronics.net') and (gameport.to_i == 10321)
      game_host = 'storm.gs4.game.play.net'
      game_port = 10324
    elsif (gamehost == 'prime.dr.game.play.net') and (gameport.to_i == 4901)
      gamehost = 'dr.simutronics.net'
      gameport = 11024
    end
    [gamehost, gameport]
  end

  def self.break_game_host_port(gamehost, gameport)
    if (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10324)
      gamehost = 'gs4.simutronics.net'
      gameport = 10321
    elsif (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10124)
      gamehost = 'gs-plat.simutronics.net'
      gameport = 10121
    elsif (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10024)
      gamehost = 'gs3.simutronics.net'
      gameport = 4900
    elsif (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10324)
      game_host = 'gs4.simutronics.net'
      game_port = 10321
    elsif (gamehost == 'dr.simutronics.net') and (gameport.to_i == 11024)
      gamehost = 'prime.dr.game.play.net'
      gameport = 4901
    end
    [gamehost, gameport]
  end

  # new feature GUI / internal settings states

  def self.debug_messaging
    if @@debug_messaging.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='debug_messaging';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      @@debug_messaging = (val.to_s =~ /on|true|yes/ ? true : false)
      Lich.debug_messaging = @@debug_messaging
    end
    return @@debug_messaging
  end

  def self.debug_messaging=(val)
    @@debug_messaging = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('debug_messaging',?);", @@debug_messaging.to_s.encode('UTF-8'))
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  def self.display_lichid
    if @@display_lichid.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='display_lichid';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      val = (XMLData.game =~ /^GS/ ? true : false) if val.nil? and XMLData.game != ''; # default false if DR, otherwise default true
      @@display_lichid = (val.to_s =~ /on|true|yes/ ? true : false) unless val.nil?
    end
    return @@display_lichid
  end

  def self.display_lichid=(val)
    @@display_lichid = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('display_lichid',?);", @@display_lichid.to_s.encode('UTF-8'))
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  def self.display_uid
    if @@display_uid.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='display_uid';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      val = (XMLData.game =~ /^GS/ ? true : false) if val.nil? and XMLData.game != ''; # default false if DR, otherwise default true
      @@display_uid = (val.to_s =~ /on|true|yes/ ? true : false) unless val.nil?
    end
    return @@display_uid
  end

  def self.display_uid=(val)
    @@display_uid = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('display_uid',?);", @@display_uid.to_s.encode('UTF-8'))
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  def self.track_autosort_state
    if @@track_autosort_state.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='track_autosort_state';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      @@track_autosort_state = (val.to_s =~ /on|true|yes/ ? true : false)
    end
    return @@track_autosort_state
  end

  def self.track_autosort_state=(val)
    @@track_autosort_state = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('track_autosort_state',?);", @@track_autosort_state.to_s.encode('UTF-8'))
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  def self.track_dark_mode
    if @@track_dark_mode.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='track_dark_mode';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      @@track_dark_mode = (val.to_s =~ /on|true|yes/ ? true : false)
    end
    return @@track_dark_mode
  end

  def self.track_dark_mode=(val)
    @@track_dark_mode = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('track_dark_mode',?);", @@track_dark_mode.to_s.encode('UTF-8'))
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end

  def self.track_layout_state
    if @@track_layout_state.nil?
      begin
        val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='track_layout_state';")
      rescue SQLite3::BusyException
        sleep 0.1
        retry
      end
      @@track_layout_state = (val.to_s =~ /on|true|yes/ ? true : false)
    end
    return @@track_layout_state
  end

  def self.track_layout_state=(val)
    @@track_layout_state = (val.to_s =~ /on|true|yes/ ? true : false)
    begin
      Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('track_layout_state',?);", @@track_layout_state.to_s.encode('UTF-8'))
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
    return nil
  end
end
