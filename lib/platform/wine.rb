module Wine
  BIN = $wine_bin
  PREFIX = $wine_prefix
  def self.registry_gets(key)
    hkey, subkey, thingie = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key).captures # fixme: stupid highlights ]/
    if File.exist?(PREFIX + '/system.reg')
      if hkey == 'HKEY_LOCAL_MACHINE'
        subkey = "[#{subkey.gsub('\\', '\\\\\\')}]"
        if thingie.nil? or thingie.empty?
          thingie = '@'
        else
          thingie = "\"#{thingie}\""
        end
        lookin = result = false
        File.open(PREFIX + '/system.reg') { |f| f.readlines }.each { |line|
          if line[0...subkey.length] == subkey
            lookin = true
          elsif line =~ /^\[/
            lookin = false
          elsif lookin and line =~ /^#{thingie}="(.*)"$/i
            result = $1.split('\\"').join('"').split('\\\\').join('\\').sub(/\\0$/, '')
            break
          end
        }
        return result
      else
        return false
      end
    else
      return false
    end
  end

  def self.registry_puts(key, value)
    hkey, subkey, thingie = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key).captures # fixme ]/
    if File.exist?(PREFIX)
      if thingie.nil? or thingie.empty?
        thingie = '@'
      else
        thingie = "\"#{thingie}\""
      end
      # gsub sucks for this..
      value = value.split('\\').join('\\\\')
      value = value.split('"').join('\"')
      begin
        regedit_data = "REGEDIT4\n\n[#{hkey}\\#{subkey}]\n#{thingie}=\"#{value}\"\n\n"
        filename = "#{TEMP_DIR}/wine-#{Time.now.to_i}.reg"
        File.open(filename, 'w') { |f| f.write(regedit_data) }
        system("#{BIN} regedit #{filename}")
        sleep 0.2
        File.delete(filename)
      rescue
        return false
      end
      return true
    end
  end
end

$wine_bin = nil
$wine_prefix = nil
