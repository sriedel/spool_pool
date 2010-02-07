$: << File.expand_path( File.join( '..', 'lib' ), __FILE__ )

TEST_SPOOL_ROOT = File.expand_path( File.join( '..', 'test_spool' ) )

def with_fs_mode( pathname, mode ) 
  pathname.chmod mode
  yield
  pathname.chmod 0755
end
