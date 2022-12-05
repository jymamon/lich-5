  require 'fiddle'
  require 'fiddle/import'
  module Win32
    SIZEOF_CHAR = Fiddle::SIZEOF_CHAR
    SIZEOF_LONG = Fiddle::SIZEOF_LONG
    SEE_MASK_NOCLOSEPROCESS = 0x00000040
    MB_OK = 0x00000000
    MB_OKCANCEL = 0x00000001
    MB_YESNO = 0x00000004
    MB_ICONERROR = 0x00000010
    MB_ICONQUESTION = 0x00000020
    MB_ICONWARNING = 0x00000030
    IDIOK = 1
    IDICANCEL = 2
    IDIYES = 6
    IDINO = 7
    KEY_ALL_ACCESS = 0xF003F
    KEY_CREATE_SUB_KEY = 0x0004
    KEY_ENUMERATE_SUB_KEYS = 0x0008
    KEY_EXECUTE = 0x20019
    KEY_NOTIFY = 0x0010
    KEY_QUERY_VALUE = 0x0001
    KEY_READ = 0x20019
    KEY_SET_VALUE = 0x0002
    KEY_WOW64_32KEY = 0x0200
    KEY_WOW64_64KEY = 0x0100
    KEY_WRITE = 0x20006
    TokenElevation = 20
    TOKEN_QUERY = 8
    STILL_ACTIVE = 259
    SW_SHOWNORMAL = 1
    SW_SHOW = 5
    PROCESS_QUERY_INFORMATION = 1024
    PROCESS_VM_READ = 16
    HKEY_LOCAL_MACHINE = -2147483646
    REG_NONE = 0
    REG_SZ = 1
    REG_EXPAND_SZ = 2
    REG_BINARY = 3
    REG_DWORD = 4
    REG_DWORD_LITTLE_ENDIAN = 4
    REG_DWORD_BIG_ENDIAN = 5
    REG_LINK = 6
    REG_MULTI_SZ = 7
    REG_QWORD = 11
    REG_QWORD_LITTLE_ENDIAN = 11

    module Kernel32
      extend Fiddle::Importer
      dlload 'kernel32'
      extern 'int GetCurrentProcess()'
      extern 'int GetExitCodeProcess(int, int*)'
      extern 'int GetModuleFileName(int, void*, int)'
      extern 'int GetVersionEx(void*)'
      #         extern 'int OpenProcess(int, int, int)' # fixme
      extern 'int GetLastError()'
      extern 'int CreateProcess(void*, void*, void*, void*, int, int, void*, void*, void*, void*)'
    end
    def Win32.GetLastError
      return Kernel32.GetLastError()
    end

    def Win32.CreateProcess(args)
      if args[:lpCommandLine]
        lpCommandLine = args[:lpCommandLine].dup
      else
        lpCommandLine = nil
      end
      if args[:bInheritHandles] == false
        bInheritHandles = 0
      elsif args[:bInheritHandles] == true
        bInheritHandles = 1
      else
        bInheritHandles = args[:bInheritHandles].to_i
      end
      if args[:lpEnvironment].class == Array
        # fixme
      end
      lpStartupInfo = [68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      lpStartupInfo_index = { :lpDesktop => 2, :lpTitle => 3, :dwX => 4, :dwY => 5, :dwXSize => 6, :dwYSize => 7, :dwXCountChars => 8, :dwYCountChars => 9, :dwFillAttribute => 10, :dwFlags => 11, :wShowWindow => 12, :hStdInput => 15, :hStdOutput => 16, :hStdError => 17 }
      for sym in [:lpDesktop, :lpTitle]
        if args[sym]
          args[sym] = "#{args[sym]}\0" unless args[sym][-1, 1] == "\0"
          lpStartupInfo[lpStartupInfo_index[sym]] = Fiddle::Pointer.to_ptr(args[sym]).to_i
        end
      end
      for sym in [:dwX, :dwY, :dwXSize, :dwYSize, :dwXCountChars, :dwYCountChars, :dwFillAttribute, :dwFlags, :wShowWindow, :hStdInput, :hStdOutput, :hStdError]
        if args[sym]
          lpStartupInfo[lpStartupInfo_index[sym]] = args[sym]
        end
      end
      lpStartupInfo = lpStartupInfo.pack('LLLLLLLLLLLLSSLLLL')
      lpProcessInformation = [0, 0, 0, 0,].pack('LLLL')
      r = Kernel32.CreateProcess(args[:lpApplicationName], lpCommandLine, args[:lpProcessAttributes], args[:lpThreadAttributes], bInheritHandles, args[:dwCreationFlags].to_i, args[:lpEnvironment], args[:lpCurrentDirectory], lpStartupInfo, lpProcessInformation)
      lpProcessInformation = lpProcessInformation.unpack('LLLL')
      return :return => (r > 0 ? true : false), :hProcess => lpProcessInformation[0], :hThread => lpProcessInformation[1], :dwProcessId => lpProcessInformation[2], :dwThreadId => lpProcessInformation[3]
    end

    #      Win32.CreateProcess(:lpApplicationName => 'Launcher.exe', :lpCommandLine => 'lich2323.sal', :lpCurrentDirectory => 'C:\\PROGRA~1\\SIMU')
    #      def Win32.OpenProcess(args={})
    #         return Kernel32.OpenProcess(args[:dwDesiredAccess].to_i, args[:bInheritHandle].to_i, args[:dwProcessId].to_i)
    #      end
    def Win32.GetCurrentProcess
      return Kernel32.GetCurrentProcess
    end

    def Win32.GetExitCodeProcess(args)
      lpExitCode = [0].pack('L')
      r = Kernel32.GetExitCodeProcess(args[:hProcess].to_i, lpExitCode)
      return :return => r, :lpExitCode => lpExitCode.unpack('L')[0]
    end

    def Win32.GetModuleFileName(args = {})
      args[:nSize] ||= 256
      buffer = "\0" * args[:nSize].to_i
      r = Kernel32.GetModuleFileName(args[:hModule].to_i, buffer, args[:nSize].to_i)
      return :return => r, :lpFilename => buffer.gsub("\0", '')
    end

    def Win32.GetVersionEx
      a = [156, 0, 0, 0, 0, ("\0" * 128), 0, 0, 0, 0, 0].pack('LLLLLa128SSSCC')
      r = Kernel32.GetVersionEx(a)
      a = a.unpack('LLLLLa128SSSCC')
      return :return => r, :dwOSVersionInfoSize => a[0], :dwMajorVersion => a[1], :dwMinorVersion => a[2], :dwBuildNumber => a[3], :dwPlatformId => a[4], :szCSDVersion => a[5].strip, :wServicePackMajor => a[6], :wServicePackMinor => a[7], :wSuiteMask => a[8], :wProductType => a[9]
    end

    module User32
      extend Fiddle::Importer
      dlload 'user32'
      extern 'int MessageBox(int, char*, char*, int)'
    end
    def Win32.MessageBox(args)
      args[:lpCaption] ||= "Lich v#{LICH_VERSION}"
      return User32.MessageBox(args[:hWnd].to_i, args[:lpText], args[:lpCaption], args[:uType].to_i)
    end

    module Advapi32
      extend Fiddle::Importer
      dlload 'advapi32'
      extern 'int GetTokenInformation(int, int, void*, int, void*)'
      extern 'int OpenProcessToken(int, int, void*)'
      extern 'int RegOpenKeyEx(int, char*, int, int, void*)'
      extern 'int RegQueryValueEx(int, char*, void*, void*, void*, void*)'
      extern 'int RegSetValueEx(int, char*, int, int, char*, int)'
      extern 'int RegDeleteValue(int, char*)'
      extern 'int RegCloseKey(int)'
    end
    def Win32.GetTokenInformation(args)
      if args[:TokenInformationClass] == TokenElevation
        token_information_length = SIZEOF_LONG
        token_information = [0].pack('L')
      else
        return nil
      end
      return_length = [0].pack('L')
      r = Advapi32.GetTokenInformation(args[:TokenHandle].to_i, args[:TokenInformationClass], token_information, token_information_length, return_length)
      if args[:TokenInformationClass] == TokenElevation
        return :return => r, :TokenIsElevated => token_information.unpack('L')[0]
      end
    end

    def Win32.OpenProcessToken(args)
      token_handle = [0].pack('L')
      r = Advapi32.OpenProcessToken(args[:ProcessHandle].to_i, args[:DesiredAccess].to_i, token_handle)
      return :return => r, :TokenHandle => token_handle.unpack('L')[0]
    end

    def Win32.RegOpenKeyEx(args)
      phkResult = [0].pack('L')
      r = Advapi32.RegOpenKeyEx(args[:hKey].to_i, args[:lpSubKey].to_s, 0, args[:samDesired].to_i, phkResult)
      return :return => r, :phkResult => phkResult.unpack('L')[0]
    end

    def Win32.RegQueryValueEx(args)
      args[:lpValueName] ||= 0
      lpcbData = [0].pack('L')
      r = Advapi32.RegQueryValueEx(args[:hKey].to_i, args[:lpValueName], 0, 0, 0, lpcbData)
      if r == 0
        lpcbData = lpcbData.unpack('L')[0]
        lpData = String.new.rjust(lpcbData, "\x00")
        lpcbData = [lpcbData].pack('L')
        lpType = [0].pack('L')
        r = Advapi32.RegQueryValueEx(args[:hKey].to_i, args[:lpValueName], 0, lpType, lpData, lpcbData)
        lpType = lpType.unpack('L')[0]
        lpcbData = lpcbData.unpack('L')[0]
        if [REG_EXPAND_SZ, REG_SZ, REG_LINK].include?(lpType)
          lpData.gsub!("\x00", '')
        elsif lpType == REG_MULTI_SZ
          lpData = lpData.gsub("\x00\x00", '').split("\x00")
        elsif lpType == REG_DWORD
          lpData = lpData.unpack('L')[0]
        elsif lpType == REG_QWORD
          lpData = lpData.unpack('Q')[0]
        elsif lpType == REG_BINARY
          # fixme
        elsif lpType == REG_DWORD_BIG_ENDIAN
          # fixme
        else
          # fixme
        end
        return :return => r, :lpType => lpType, :lpcbData => lpcbData, :lpData => lpData
      else
        return :return => r
      end
    end

    def Win32.RegSetValueEx(args)
      if [REG_EXPAND_SZ, REG_SZ, REG_LINK].include?(args[:dwType]) and (args[:lpData].class == String)
        lpData = args[:lpData].dup
        lpData.concat("\x00")
        cbData = lpData.length
      elsif (args[:dwType] == REG_MULTI_SZ) and (args[:lpData].class == Array)
        lpData = args[:lpData].join("\x00").concat("\x00\x00")
        cbData = lpData.length
      elsif (args[:dwType] == REG_DWORD) and (args[:lpData].class == Fixnum)
        lpData = [args[:lpData]].pack('L')
        cbData = 4
      elsif (args[:dwType] == REG_QWORD) and (args[:lpData].class == Fixnum or args[:lpData].class == Bignum)
        lpData = [args[:lpData]].pack('Q')
        cbData = 8
      elsif args[:dwType] == REG_BINARY
        # fixme
        return false
      elsif args[:dwType] == REG_DWORD_BIG_ENDIAN
        # fixme
        return false
      else
        # fixme
        return false
      end
      args[:lpValueName] ||= 0
      return Advapi32.RegSetValueEx(args[:hKey].to_i, args[:lpValueName], 0, args[:dwType], lpData, cbData)
    end

    def Win32.RegDeleteValue(args)
      args[:lpValueName] ||= 0
      return Advapi32.RegDeleteValue(args[:hKey].to_i, args[:lpValueName])
    end

    def Win32.RegCloseKey(args)
      return Advapi32.RegCloseKey(args[:hKey])
    end

    module Shell32
      extend Fiddle::Importer
      dlload 'shell32'
      extern 'int ShellExecuteEx(void*)'
      extern 'int ShellExecute(int, char*, char*, char*, char*, int)'
    end
    def Win32.ShellExecuteEx(args)
      #         struct = [ (SIZEOF_LONG * 15), 0, 0, 0, 0, 0, 0, SW_SHOWNORMAL, 0, 0, 0, 0, 0, 0, 0 ]
      struct = [(SIZEOF_LONG * 15), 0, 0, 0, 0, 0, 0, SW_SHOW, 0, 0, 0, 0, 0, 0, 0]
      struct_index = { :cbSize => 0, :fMask => 1, :hwnd => 2, :lpVerb => 3, :lpFile => 4, :lpParameters => 5, :lpDirectory => 6, :nShow => 7, :hInstApp => 8, :lpIDList => 9, :lpClass => 10, :hkeyClass => 11, :dwHotKey => 12, :hIcon => 13, :hMonitor => 13, :hProcess => 14 }
      for sym in [:lpVerb, :lpFile, :lpParameters, :lpDirectory, :lpIDList, :lpClass]
        if args[sym]
          args[sym] = "#{args[sym]}\0" unless args[sym][-1, 1] == "\0"
          struct[struct_index[sym]] = Fiddle::Pointer.to_ptr(args[sym]).to_i
        end
      end
      for sym in [:fMask, :hwnd, :nShow, :hkeyClass, :dwHotKey, :hIcon, :hMonitor, :hProcess]
        if args[sym]
          struct[struct_index[sym]] = args[sym]
        end
      end
      struct = struct.pack('LLLLLLLLLLLLLLL')
      r = Shell32.ShellExecuteEx(struct)
      struct = struct.unpack('LLLLLLLLLLLLLLL')
      return :return => r, :hProcess => struct[struct_index[:hProcess]], :hInstApp => struct[struct_index[:hInstApp]]
    end

    def Win32.ShellExecute(args)
      args[:lpOperation] ||= 0
      args[:lpParameters] ||= 0
      args[:lpDirectory] ||= 0
      args[:nShowCmd] ||= 1
      return Shell32.ShellExecute(args[:hwnd].to_i, args[:lpOperation], args[:lpFile], args[:lpParameters], args[:lpDirectory], args[:nShowCmd])
    end

    begin
      module Kernel32
        extern 'int EnumProcesses(void*, int, void*)'
      end
      def Win32.EnumProcesses(args = {})
        args[:cb] ||= 400
        pProcessIds = Array.new((args[:cb] / SIZEOF_LONG), 0).pack(''.rjust((args[:cb] / SIZEOF_LONG), 'L'))
        pBytesReturned = [0].pack('L')
        r = Kernel32.EnumProcesses(pProcessIds, args[:cb], pBytesReturned)
        pBytesReturned = pBytesReturned.unpack('L')[0]
        return :return => r, :pProcessIds => pProcessIds.unpack(''.rjust((args[:cb] / SIZEOF_LONG), 'L'))[0...(pBytesReturned / SIZEOF_LONG)], :pBytesReturned => pBytesReturned
      end
    rescue
      module Psapi
        extend Fiddle::Importer
        dlload 'psapi'
        extern 'int EnumProcesses(void*, int, void*)'
      end
      def Win32.EnumProcesses(args = {})
        args[:cb] ||= 400
        pProcessIds = Array.new((args[:cb] / SIZEOF_LONG), 0).pack(''.rjust((args[:cb] / SIZEOF_LONG), 'L'))
        pBytesReturned = [0].pack('L')
        r = Psapi.EnumProcesses(pProcessIds, args[:cb], pBytesReturned)
        pBytesReturned = pBytesReturned.unpack('L')[0]
        return :return => r, :pProcessIds => pProcessIds.unpack(''.rjust((args[:cb] / SIZEOF_LONG), 'L'))[0...(pBytesReturned / SIZEOF_LONG)], :pBytesReturned => pBytesReturned
      end
    end

    def Win32.isXP?
      return (Win32.GetVersionEx[:dwMajorVersion] < 6)
    end

    #      def Win32.isWin8?
    #         r = Win32.GetVersionEx
    #         return ((r[:dwMajorVersion] == 6) and (r[:dwMinorVersion] >= 2))
    #      end
    def Win32.admin?
      if Win32.isXP?
        return true
      else
        r = Win32.OpenProcessToken(:ProcessHandle => Win32.GetCurrentProcess, :DesiredAccess => TOKEN_QUERY)
        token_handle = r[:TokenHandle]
        r = Win32.GetTokenInformation(:TokenInformationClass => TokenElevation, :TokenHandle => token_handle)
        return (r[:TokenIsElevated] != 0)
      end
    end

    def Win32.AdminShellExecute(args)
      # open ruby/lich as admin and tell it to open something else
      if not caller.any? { |c| c =~ /eval|run/ }
        r = Win32.GetModuleFileName
        if r[:return] > 0
          if File.exists?(r[:lpFilename])
            Win32.ShellExecuteEx(:lpVerb => 'runas', :lpFile => r[:lpFilename], :lpParameters => "#{File.expand_path($PROGRAM_NAME)} shellexecute #{[Marshal.dump(args)].pack('m').gsub("\n", '')}")
          end
        end
      end
    end
  end
