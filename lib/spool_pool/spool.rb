require 'yaml'
require 'spool_pool/file'

module SpoolPool
=begin rdoc
This class manages the data storage and retrieval within a specific spool.
=end
  class Spool
    attr_reader :pathname

=begin rdoc
Uses the directory given in +pathname+ as the directory for the subsequent
spooling operations. 

Will perform a simple check on the directory and throw an exception if the
directory already exists but isn't read- and writeable by the effective
user id of the process.
=end
    def initialize( pathname )
      @pathname = pathname
      validate_spool_directory
    end

=begin rdoc
Serializes and stores the +data+.

Returns the path of the file storing the data.
=end
    def put( data )
      @pathname.mkpath unless @pathname.exist?
      SpoolPool::File.write( @pathname, serialize( data ) )
    end

=begin rdoc
Retrieves and deserializes the oldest data in the spool. 

Ordering is based on the filename (which in turn is based on the files
creation time), but the ordering is non-strict. 

Data stored within the same second will be returned in a random order.
=end
    def get
      file = oldest_spooled_file
      retval = file ? deserialize( file.read ) : nil
      file.unlink if file
      retval
    end

    def safe_get
      file = oldest_spooled_file
      return nil unless file
      SpoolPool::File.safe_read( file ) { |data| yield deserialize(data) }
    end

=begin rdoc
Retrieves and deserializes all the data in the spool, oldest data first. 
Each piece of spooled data will be yielded to the supplied block. 

Ordering is based on the files ctime, but the ordering is non-strict. 
Data stored within the same second will be returned in a random order.
=end
    def flush
      loop do
        data = get
        break if data.nil?

        yield data
      end
    end

=begin rdoc
Serializes the data so that it can be deserialized with the +deserialize+ 
method later on.
=end
    def serialize( data )
      self.class.serialize( data )
    end

    def self.serialize( data ) # :nodoc:
      YAML.dump( data )
    end

=begin rdoc
Deserializes the +data+ that has previously been serialized with +serialize+.
=end
    def deserialize( data )
      self.class.deserialize( data )
    end

    def self.deserialize( data ) # :nodoc:
      YAML.load( data )
    end

    private
    def oldest_spooled_file
      @pathname.children.sort.first
    end

    def validate_spool_directory
      return unless @pathname.exist?

      raise Errno::EACCES.new( "Spool directory '#{@pathname}' isn't writeable!" ) unless @pathname.writable?
      raise Errno::EACCES.new( "Spool directory '#{@pathname}' isn't readable!" ) unless @pathname.readable?
    end

  end
end
