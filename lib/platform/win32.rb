# For this module, allow Win32 naming conventions to match the APIs being used underneath.
# rubocop:disable Naming/MethodName
require 'fiddle'
require 'fiddle/import'
require 'lib/platform/win32/advapi32'
require 'lib/platform/win32/kernel32'
require 'lib/platform/win32/shell32'
require 'lib/platform/win32/user32'

module Win32
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
  # rubocop:disable Naming/ConstantName Allow to match Win32 naming
  TokenElevation = 20
  # rubocop:enable Naming/ConstantName
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

  def self.isXP?
    return (Win32.GetVersionEx[:dwMajorVersion] < 6)
  end

  def self.admin?
    if Win32.isXP?
      return true
    else
      r = Win32.OpenProcessToken(:ProcessHandle => Win32.GetCurrentProcess, :DesiredAccess => TOKEN_QUERY)
      token_handle = r[:TokenHandle]
      r = Win32.GetTokenInformation(:TokenInformationClass => TokenElevation, :TokenHandle => token_handle)
      return (r[:TokenIsElevated] != 0)
    end
  end
end
# rubocop:enable Naming/MethodName
