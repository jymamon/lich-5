require 'fiddle'
require 'fiddle/import'
module Win32
  module Kernel32
    extend Fiddle::Importer
    dlload 'kernel32'
    extern 'int GetCurrentProcess()'
    extern 'int GetExitCodeProcess(int, int*)'
    extern 'int GetModuleFileName(int, void*, int)'
    extern 'int GetVersionEx(void*)'
    extern 'int GetLastError()'
    extern 'int CreateProcess(void*, void*, void*, void*, int, int, void*, void*, void*, void*)'
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
      return :return => r, :pProcessIds => pProcessIds.unpack(''.rjust((args[:cb] / SIZEOF_LONG),
                                                                       'L'))[0...(pBytesReturned / SIZEOF_LONG)], :pBytesReturned => pBytesReturned
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
      return :return => r, :pProcessIds => pProcessIds.unpack(''.rjust((args[:cb] / SIZEOF_LONG),
                                                                       'L'))[0...(pBytesReturned / SIZEOF_LONG)], :pBytesReturned => pBytesReturned
    end
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
    lpStartupInfo_index = { :lpDesktop => 2, :lpTitle => 3, :dwX => 4, :dwY => 5, :dwXSize => 6, :dwYSize => 7,
                            :dwXCountChars => 8, :dwYCountChars => 9, :dwFillAttribute => 10, :dwFlags => 11, :wShowWindow => 12, :hStdInput => 15, :hStdOutput => 16, :hStdError => 17 }

    for sym in [:lpDesktop, :lpTitle]
      if args[sym]
        args[sym] = "#{args[sym]}\0" unless args[sym][-1, 1] == "\0"
        lpStartupInfo[lpStartupInfo_index[sym]] = Fiddle::Pointer.to_ptr(args[sym]).to_i
      end
    end

    for sym in [:dwX, :dwY, :dwXSize, :dwYSize, :dwXCountChars, :dwYCountChars, :dwFillAttribute, :dwFlags,
                :wShowWindow, :hStdInput, :hStdOutput, :hStdError]
      if args[sym]
        lpStartupInfo[lpStartupInfo_index[sym]] = args[sym]
      end
    end

    lpStartupInfo = lpStartupInfo.pack('LLLLLLLLLLLLSSLLLL')
    lpProcessInformation = [0, 0, 0, 0,].pack('LLLL')
    r = Kernel32.CreateProcess(args[:lpApplicationName], lpCommandLine, args[:lpProcessAttributes],
                               args[:lpThreadAttributes], bInheritHandles, args[:dwCreationFlags].to_i, args[:lpEnvironment], args[:lpCurrentDirectory], lpStartupInfo, lpProcessInformation)
    lpProcessInformation = lpProcessInformation.unpack('LLLL')
    return :return => (r > 0 ? true : false), :hProcess => lpProcessInformation[0], :hThread => lpProcessInformation[1], :dwProcessId => lpProcessInformation[2], :dwThreadId => lpProcessInformation[3]
  end

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
end
