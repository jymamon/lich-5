require 'fiddle'
require 'fiddle/import'
module Win32
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

  def self.GetTokenInformation(args)
    if args[:TokenInformationClass] == TokenElevation
      token_information_length = SIZEOF_LONG
      token_information = [0].pack('L')
    else
      return nil
    end
    return_length = [0].pack('L')
    r = Advapi32.GetTokenInformation(args[:TokenHandle].to_i, args[:TokenInformationClass], token_information,
                                     token_information_length, return_length)
    return :return => r, :TokenIsElevated => token_information.unpack1('L') if args[:TokenInformationClass] == TokenElevation
  end

  def self.OpenProcessToken(args)
    token_handle = [0].pack('L')
    r = Advapi32.OpenProcessToken(args[:ProcessHandle].to_i, args[:DesiredAccess].to_i, token_handle)
    return :return => r, :TokenHandle => token_handle.unpack1('L')
  end

  def self.RegOpenKeyEx(args)
    phkResult = [0].pack('L')
    r = Advapi32.RegOpenKeyEx(args[:hKey].to_i, args[:lpSubKey].to_s, 0, args[:samDesired].to_i, phkResult)
    return :return => r, :phkResult => phkResult.unpack1('L')
  end

  def self.RegQueryValueEx(args)
    args[:lpValueName] ||= 0
    lpcbData = [0].pack('L')
    r = Advapi32.RegQueryValueEx(args[:hKey].to_i, args[:lpValueName], 0, 0, 0, lpcbData)
    if r == 0
      lpcbData = lpcbData.unpack1('L')
      lpData = String.new.rjust(lpcbData, "\x00")
      lpcbData = [lpcbData].pack('L')
      lpType = [0].pack('L')
      r = Advapi32.RegQueryValueEx(args[:hKey].to_i, args[:lpValueName], 0, lpType, lpData, lpcbData)
      lpType = lpType.unpack1('L')
      lpcbData = lpcbData.unpack1('L')
      if [REG_EXPAND_SZ, REG_SZ, REG_LINK].include?(lpType)
        lpData.gsub!("\x00", '')
      elsif lpType == REG_MULTI_SZ
        lpData = lpData.gsub("\x00\x00", '').split("\x00")
      elsif lpType == REG_DWORD
        lpData = lpData.unpack1('L')
      elsif lpType == REG_QWORD
        lpData = lpData.unpack1('Q')
      elsif lpType == REG_BINARY
        # FIXME: This needs handled or reported as an error
      elsif lpType == REG_DWORD_BIG_ENDIAN
        # FIXME: This needs handled or reported as an error
      else
        # FIXME: This needs handled or reported as an error
      end
      return :return => r, :lpType => lpType, :lpcbData => lpcbData, :lpData => lpData
    else
      return :return => r
    end
  end

  def self.RegSetValueEx(args)
    if [REG_EXPAND_SZ, REG_SZ, REG_LINK].include?(args[:dwType]) and args[:lpData].instance_of?(String)
      lpData = args[:lpData].dup
      lpData.concat("\x00")
      cbData = lpData.length
    elsif (args[:dwType] == REG_MULTI_SZ) and args[:lpData].instance_of?(Array)
      lpData = args[:lpData].join("\x00").concat("\x00\x00")
      cbData = lpData.length
    elsif (args[:dwType] == REG_DWORD) and args[:lpData].instance_of?(Fixnum)
      lpData = [args[:lpData]].pack('L')
      cbData = 4
    elsif (args[:dwType] == REG_QWORD) and (args[:lpData].instance_of?(Fixnum) or args[:lpData].instance_of?(Bignum))
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

  def self.RegDeleteValue(args)
    args[:lpValueName] ||= 0
    return Advapi32.RegDeleteValue(args[:hKey].to_i, args[:lpValueName])
  end

  def self.RegCloseKey(args)
    return Advapi32.RegCloseKey(args[:hKey])
  end
end
