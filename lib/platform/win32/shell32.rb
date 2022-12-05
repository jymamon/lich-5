require 'fiddle'
require 'fiddle/import'
module Win32
  module Shell32
    extend Fiddle::Importer
    dlload 'shell32'
    extern 'int ShellExecuteEx(void*)'
    extern 'int ShellExecute(int, char*, char*, char*, char*, int)'
  end

  def Win32.ShellExecuteEx(args)
    struct = [(SIZEOF_LONG * 15), 0, 0, 0, 0, 0, 0, SW_SHOW, 0, 0, 0, 0, 0, 0, 0]
    struct_index = {
      :cbSize => 0,
      :fMask => 1,
      :hwnd => 2,
      :lpVerb => 3,
      :lpFile => 4,
      :lpParameters => 5,
      :lpDirectory => 6,
      :nShow => 7,
      :hInstApp => 8,
      :lpIDList => 9,
      :lpClass => 10,
      :hkeyClass => 11,
      :dwHotKey => 12,
      :hIcon => 13,
      :hMonitor => 13,
      :hProcess => 14
    }

    args[:fMask] ||= Win32::SEE_MASK_NOCLOSEPROCESS
    args[:lpDirectory] ||= LICH_DIR.tr("/", "\\")
    args[:lpVerb] ||= 'runas'

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
    result = Shell32.ShellExecuteEx(struct)
    struct = struct.unpack('LLLLLLLLLLLLLLL')
    return :return => result, :hProcess => struct[struct_index[:hProcess]], :hInstApp => struct[struct_index[:hInstApp]]
  end

  def Win32.ShellExecute(args)
    args[:lpDirectory] ||= LICH_DIR.tr("/", "\\")
    args[:lpOperation] ||= 0
    args[:lpParameters] ||= 0
    args[:lpVerb] ||= 'runas'
    args[:nShowCmd] ||= 1

    return Shell32.ShellExecute(
      args[:hwnd].to_i,
      args[:lpOperation],
      args[:lpFile],
      args[:lpParameters],
      args[:lpDirectory],
      args[:nShowCmd])
  end
end
