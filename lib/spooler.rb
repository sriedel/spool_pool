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
    @spools[spool] ||= Spool.new( @spool_dir + spool )
    spoolfile_pathname = @spools[spool].put( data )
    spoolfile_pathname.to_s
  end

  private
  def setup_spooldir
    raise Errno::EACCES.new("The directory '#{@spool_dir}' does not exist and I don't have enough permissions to create it!") unless @spool_dir.parent.writable?
    @spool_dir.mkpath 
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
