require 'pathname'
require 'spool_pool/spool'

module SpoolPool
=begin rdoc
This is a container class used to manage the interaction with the 
individual Spool instances. Spool directories are created using the name
given in the put/get methods on demand as subdirectories of the +spool_dir+
passed to the initializer..
  
= Security Note
Some naive tests are in place to catch the most blatant directory traversal
attempts. But for real security you should never blindly pass any 
user-supplied or computed queue name to these methods. Always validate 
user input!

=end
  class Pool
    attr_reader :spool_dir
    attr_reader :spools

=begin rdoc
Sets up a spooling pool in the +spool_path+ given. 
If the directory does not exist, it will try to create it for you. 

Will throw an exception if it can't create the directoy, or if the 
directory exists and is not read- and writeable by the effective user id
of the process.
=end
    def initialize( spool_path )
      @spool_dir = Pathname.new spool_path
      @spools = {}

      setup_spooldir unless @spool_dir.exist?
      assert_readable @spool_dir
      assert_writeable @spool_dir
    end

=begin rdoc
Serializes and stores the +data+ in the given +spool+. If the +spool+ 
doesn't exist yet, it will try to create a new spool and directory.

Returns the path of the file storing the data.

This method performs a naive check on the spool name for directory 
traversal attempts. *DO NOT* rely on this for security relevant systems,
always validate user supplied queue names yourself before handing them 
off to this method!
=end
    def put( spool, data )
      validate_spool_path spool
      @spools[spool] ||= SpoolPool::Spool.new( @spool_dir + spool.to_s )
      @spools[spool].put( data )
    end

=begin rdoc
Retrieves and deserializes oldest data in the given +spool+. 

Note that while data is retrieved oldest first, the order is non-strict, i.e.
different data written during the same second to the storage will be
retrieved in a random order. Or to put it another way: Ordering is exact down
to the second, but sub-second ordering is random.

This method performs a naive check on the spool name for directory 
traversal attempts. *DO NOT* rely on this for security relevant systems,
always validate user supplied queue names yourself before handing them 
off to this method!
=end
    def get( spool )
      validate_spool_path spool

      missing_spool_on_read_handler( spool ) unless @spools.has_key?( spool )

      @spools[spool].get if @spools[spool] 
    end

    def safe_get( spool )
      validate_spool_path spool

      missing_spool_on_read_handler( spool ) unless @spools.has_key?( spool )

      if @spools[spool] 
        @spools[spool].safe_get { |spool_data| yield spool_data }
      end
    end

=begin rdoc
Retrieves and deserializes all data in the given +spool+, yielding
each deserialized data to the supplied block. Ordering is oldest data first.

Note that while data is retrieved oldest first, the order is non-strict, i.e. 
different data written during the same second to the storage will be
retrieved in a random order. Or to put it another way: Ordering is 
exact down to the second, but sub-second ordering is random.

This method performs a naive check on the spool name for directory 
traversal attempts. *DO NOT* rely on this for security relevant systems,
always validate user supplied queue names yourself before handing them 
off to this method!
=end
    def flush( spool, &block )
      validate_spool_path spool

      missing_spool_on_read_handler( spool ) unless @spools.has_key?( spool )

      @spools[spool].flush( &block ) if @spools[spool]
    end

    private
    def setup_spooldir
      raise Errno::EACCES.new("The directory '#{@spool_dir}' does not exist and I don't have enough permissions to create it!") unless @spool_dir.parent.writable?
      @spool_dir.mkpath 
      @spool_dir.chmod 0755
    end

    def create_spool_for_existing_path( pathname )
      pathname.exist? ? SpoolPool::Spool.new( pathname ) : nil
    end

    def missing_spool_on_read_handler( spool )
      spool_instance = create_spool_for_existing_path( @spool_dir + spool.to_s )
      @spools[spool] = spool_instance if spool_instance
    end

    def assert_readable( pathname )
      raise Errno::EACCES.new( "I can't read in the directory '#{pathname}'!" ) unless pathname.readable?
    end

    def assert_writeable( pathname )
      raise Errno::EACCES.new( "I can't write to the directory '#{pathname}'!" ) unless pathname.writable?
    end

    def validate_spool_path( spool )
      raise "Directory traversal attempt" if spool =~ %r{/\.\./} ||
                                             spool =~ %r{\A\.\.\/}
    end
  end
end
