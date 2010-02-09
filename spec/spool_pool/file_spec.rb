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

  describe ".safe_read" do
    before( :each ) do
      @spoolfile = SpoolPool::File.write( @basepath, @data )
    end

    it "should return the files content data" do
      SpoolPool::File.safe_read( @spoolfile ).should == @data
    end

    context "no block is passed" do
      it "should not yield" do
        SpoolPool::File.safe_read( @spoolfile )
      end

      it "should delete the file after reading the file" do
        SpoolPool::File.safe_read( @spoolfile )
        File.exist?( @spoolfile ).should be_false
      end
    end

    context "a block is passed" do
      it "should yield the read file data" do
        SpoolPool::File.safe_read( @spoolfile ) do |read_data|
          read_data.should == @data
        end
      end

      context "no exception was raised in the block" do
        before( :each ) do
          @block = Proc.new {}
        end

        it "should delete the file after the block completes" do
          SpoolPool::File.safe_read( @spoolfile, &@block ) 
          File.exist?( @spoolfile ).should be_false
        end
      end

      context "an exception was raised in the block" do
        before( :each ) do
          @block = Proc.new { raise RuntimeError }
        end

        it "should not delete the file after the block completes" do
          lambda{ SpoolPool::File.safe_read( @spoolfile, &@block ) }
          File.exist?( @spoolfile ).should be_true
        end

        it "should let the thrown exception bubble up further" do
          lambda{ SpoolPool::File.safe_read( @spoolfile, &@block ) }.should raise_error( RuntimeError )
        end
      end
    end
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
