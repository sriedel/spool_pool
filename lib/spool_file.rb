require 'tempfile'

class SpoolFile
  attr_reader :pathname

  def self.create_for_write( basepath )
     new( basepath + "somefilename" )
  end

  def initialize( pathname )
    @pathname = pathname
  end

  def write( data )
    begin
      @pathname.open( "w" ) { |fh| fh.write data }
    rescue 
      @pathname.unlink rescue nil
      raise $!
    end
  end

  def self.write( basepath, data ) 
    tmpfile = nil
    begin
      tmpfile = Tempfile.new( nil, basepath.to_s )
      tmpfile.write data
      tmpfile.close

      # Hack: stop Tempfile from deleting the file upon finalization
      #       Too implizit in the long run, but ok for the first versions
      ObjectSpace.undefine_finalizer( tmpfile ) 
    rescue
      tmpfile.unlink
      raise $!
    else
      tmpfile.path
    end
  end
end
