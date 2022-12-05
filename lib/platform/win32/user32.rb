require 'fiddle'
require 'fiddle/import'

module User32
  extend Fiddle::Importer
  dlload 'user32'
  extern 'int MessageBox(int, char*, char*, int)'

  def Win32.MessageBox(args)
    User23.MessageBox(args)
    args[:lpCaption] ||= "Lich v#{LICH_VERSION}"
    return User32.MessageBox(args[:hWnd].to_i, args[:lpText], args[:lpCaption], args[:uType].to_i)
  end
end
