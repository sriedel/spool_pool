require 'pathname'
require 'spool'

class Spooler
  attr_reader :spool_dir
  attr_reader :spools

  def initialize( spool_path )
    @spool_dir = Pathname.new spool_path
    @spools = {}

    setup_spooldir unless @spool_dir.exist?
    assert_readable @spool_dir
    assert_writeable @spool_dir
  end

  def put( spool, data )
    validate_spool_path spool
    @spools[spool] ||= Spool.new( @spool_dir + spool.to_s )
    @spools[spool].put( data )
  end

  def get( spool )
    validate_spool_path spool

    missing_spool_on_read_handler( spool ) unless @spools.has_key?( spool )

    @spools[spool].get if @spools[spool] 
  end

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
    pathname.exist? ? Spool.new( pathname ) : nil
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
