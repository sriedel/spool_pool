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
      @pathname.open( "w" ) { |fh| fh.puts data }
    rescue 
      @pathname.unlink
      raise $!
    end
  end
end
