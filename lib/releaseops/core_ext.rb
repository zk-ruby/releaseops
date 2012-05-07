class ::String
  # Provides a margin controlled string.
  #
  #   x = %Q{
  #         | This
  #         |   is
  #         |     margin controlled!
  #         }.margin
  #
  # * borrowed from facets-1.8.54/lib/facets/core/string/margin.rb
  # * This may still need a bit of tweaking.
  def margin(n=0)
    d = /\A.*\n\s*(.)/.match( self )[1]
    d = /\A\s*(.)/.match( self)[1] unless d
    return '' unless d
    if n == 0
      gsub(/\n\s*\Z/,'').gsub(/^\s*[#{d}]/, '')
    else
      gsub(/\n\s*\Z/,'').gsub(/^\s*[#{d}]/, ' ' * n)
    end
  end
end

module ::FileUtils
  # like `` but barfs if there's an error
  def bt(cmd)
    `#{cmd}`.tap do
      unless $?.exited? and $?.success?
        raise "command #{cmd.inspect} failed with status #{$?.inspect}"
      end
    end
  end
  module_function :bt

  def bt_lines(cmd, sep=$/)
    bt(cmd).split(sep)
  end
  module_function :bt_lines

  def realpath(p)
    Pathname.new(p).realpath.to_s
  end
  module_function :realpath
end

