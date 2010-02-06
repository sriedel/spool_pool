require 'spec_helper'
require 'spooler'

describe Spooler do
  before( :each ) do
    @root_pathname = Pathname.new( TEST_SPOOL_ROOT )
    @spool_path = File.join( TEST_SPOOL_ROOT, "spooler" )
    @spool_pathname = Pathname.new( @spool_path )
    @spool_pathname.mkpath

    @instance = Spooler.new( @spool_path )
  end

  after( :each ) do
    # @spool_pathname.unlink
  end

  it "should have a spool_dir attribute" do
    @instance.should respond_to( :spool_dir )
  end

  it "should store the spool_dir as a Pathname" do
    @instance.spool_dir.should be_a( Pathname )
  end

  it "should have a spools attribute" do
    @instance.should respond_to( :spools )
  end
  
  describe "#initialize" do
    it "should set the spool_dir attribute" do
      @instance.spool_dir.to_s.should == @spool_path
    end

    it "should set up the spools attribute" do
      @instance.spools.should == {}
    end

    context "the spool_dir does not exist" do
      before( :each ) do
        @spool_pathname.rmtree if @spool_pathname.exist?
      end

      context "and it can create the spool dir" do
        before( :each ) do
          @root_pathname.chmod 0755
        end

        it "should try to create the spool_dir" do
          pending
          Spooler.new( @spool_path )
          @spool_pathname.should exist
          @spool_pathname.unlink if @spool_pathname.exist?
        end
      end

      context "and it can't create the spool dir" do
        before( :each ) do
          @root_pathname.chmod 0555
        end
        after( :each ) do
          @root_pathname.chmod 0755
        end

        it "should raise an exception" do
          pending
          lambda { Spooler.new( @spool_path ) }.should raise_error( Errno::EACCES )
        end
      end
    end

    context "the spool_dir exists" do
      it "should raise an exception if it can't create a file" do
        @spool_pathname.chmod 0555
        lambda { Spooler.new( @spool_path ) }.should raise_error( Errno::EACCES )
        @spool_pathname.chmod 0755
      end

      it "should raise an exception if it can't read a file" do
        @spool_pathname.chmod 0333
        lambda { Spooler.new( @spool_path ) }.should raise_error( Errno::EACCES )
        @spool_pathname.chmod 0755
      end
    end
  end

  describe "#put" do
    it "should create queue_dir object in the queues attribute if it doesn't exist yet" do
      @instance.spools.delete :my_spool
      filename = @instance.put( :my_spool, 'some value' )
      @instance.spools[:my_spool].should_not be_nil
      File.unlink( filename ) if File.exist?( filename )
    end

    it "should return the filename of the spool file" do
      @instance.put( :my_spool, 'some value' ).should be_a( String )
    end

    context "queue names that try to escape the queue_dir" do
      it "should raise an exception on directory traversal attempts" do
        lambda { @instance.put "../../foo", 'some value' }.should raise_error
      end

      it "should not raise an exception if following a symlink" do
        real_path = Pathname.new( @spool_pathname + "real" )
        real_path.mkpath
        symlinked_path = Pathname.new( @spool_pathname + "symlink" )
        symlinked_path.make_symlink( real_path.to_s )

        lambda { @instance.put "symlink", "some value" }.should_not raise_error

        symlinked_path.unlink
        real_path.rmtree
      end
    end
  end

  describe "#fetch" do
    it "should return the deserialized contents of the oldest file in the given queue directory"
    it "should return nil if no file is available"
    it "should raise an exception if the queue directory is not readable"
    it "should delete the read file"
    it "should raise an exception if the oldest file in the queue directory is not readable"
    it "should raise an exception if the oldest file in the queue directory is not deleteable"
    context "queue names that try to escape the queue_dir" do
      it "should raise an exception on directory traversal attempts"
      it "should not raise an exception if following a symlink"
    end
  end

  describe "#flush" do
    it "should yield every file in the given queue directory to the passed block"
    it "should yield the files ordered by date, oldest first"
    it "should delete each file after it was processed"
    it "should raise an exception if the queue directory is not readable"
    it "should raise an exception if any file in the queue directory is not readable"
    it "should raise an exception if any file in the queue directory is not deleteable"
    context "queue names that try to escape the queue_dir" do
      it "should raise an exception on directory traversal attempts"
      it "should not raise an exception if following a symlink"
    end
  end
end
