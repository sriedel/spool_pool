require 'spool_file'
class Spool
  attr_reader :pathname

  def initialize( pathname )
    @pathname = pathname

    if @pathname.exist?
      raise Errno::EACCES.new( "Spool directory '#{@pathname}' isn't writeable!" ) unless @pathname.writable?
      raise Errno::EACCES.new( "Spool directory '#{@pathname}' isn't readable!" ) unless @pathname.readable?
    end
  end

  def put( data )
    @pathname.mkpath unless @pathname.exist?
    SpoolFile.write( @pathname, data )
  end
end
