require 'yaml'
require 'spool_file'

class Spool
  attr_reader :pathname

  def initialize( pathname )
    @pathname = pathname
    validate_spool_directory
  end

  def put( data )
    @pathname.mkpath unless @pathname.exist?
    SpoolFile.write( @pathname, serialize( data ) )
  end

  def get
    file = oldest_spooled_file
    retval = file ? deserialize( file.read ) : nil
    file.unlink if file
    retval
  end

  def flush
    loop do
      data = get
      break if data.nil?

      yield data
    end
  end

  def serialize( data )
    self.class.serialize( data )
  end

  def self.serialize( data )
    YAML.dump( data )
  end

  def deserialize( data )
    self.class.deserialize( data )
  end

  def self.deserialize( data )
    YAML.load( data )
  end

  private
  def oldest_spooled_file
    @pathname.children.sort { |a,b| a.ctime <=> b.ctime }.first
  end

  def validate_spool_directory
    return unless @pathname.exist?

    raise Errno::EACCES.new( "Spool directory '#{@pathname}' isn't writeable!" ) unless @pathname.writable?
    raise Errno::EACCES.new( "Spool directory '#{@pathname}' isn't readable!" ) unless @pathname.readable?
  end

end
