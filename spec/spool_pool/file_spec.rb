require 'spec_helper'

describe SpoolPool::File do
  
  before( :each ) do
    @testspoolpath = File.join TEST_SPOOL_ROOT, "spool_files"
    @basepath = Pathname.new( @testspoolpath )
    @basepath.mkpath
    @basepath.chmod 0755
    @data = "my_data"
  end

  after( :each ) do
    @basepath.rmtree
  end

  describe ".write" do
    before( :each ) do
      @failing_tempfile = SpoolPool::File.new( @basepath.to_s )
      @failing_tempfile.stub!( :write ).and_raise( RuntimeError )
    end

    after( :each ) do
    end

    it "should create a filename in the given directory" do
      SpoolPool::File.write( @basepath, @data ).should =~ /\A#{@basepath}/
    end

    it "should return the path for the file containing the spooled data" do
      path = SpoolPool::File.write( @basepath, @data )
      Pathname.new( path ).read.should == @data
    end

    it "should have a different filename for each file" do
      spoolfile1 = SpoolPool::File.write( @basepath, @data )
      spoolfile2 = SpoolPool::File.write( @basepath, @data )
      spoolfile1.should_not == spoolfile2
    end

    it "should raise an exception if the file can't be created" do
      with_fs_mode( @basepath, 0000 ) do
        lambda { SpoolPool::File.write( @basepath, @data ) }.should raise_error
      end
    end

    it "should raise an exception if the data can't be written" do
      SpoolPool::File.stub!( :new ).and_return( @failing_tempfile )

      lambda { SpoolPool::File.write( @basepath, @data ) }.should raise_error( RuntimeError )
    end

    context "on an aborted operation" do
      before( :each ) do
        SpoolPool::File.stub!( :new ).and_return( @failing_tempfile )
      end
      
      it "should delete any created file again" do
        lambda { SpoolPool::File.write( @basepath, @data ) }.should raise_error( RuntimeError )
        @basepath.children.should be_empty
      end
    end
  end
end
