require 'spec_helper'
require 'spooler'

describe Spooler do
  before( :each ) do
    @spool_path = "/var/spool/spooler"
    @spool_pathname = Pathname.new( @spool_path )
    @spool_pathname.stub!( :exist? ).and_return( true )
    @spool_pathname.stub!( :writable? ).and_return( true )
    @spool_pathname.stub!( :readable? ).and_return( true )
    @spool_pathparent = mock( Pathname, :writable? => true  )
    @spool_pathname.stub!( :parent ).and_return( @spool_pathparent )

    Pathname.stub!( :new ).and_return( @spool_pathname )
    @instance = Spooler.new( @spool_path )
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
      Spooler.new( @spool_path ).spool_dir.to_s.should == @spool_path
    end

    it "should set up the spools attribute" do
      Spooler.new( @spool_path ).spools.should == {}
    end

    context "the spool_dir does not exist" do
      before( :each ) do
        @spool_pathname.stub!( :exist? ).and_return( false )
      end

      context "and it can create the spool dir" do
        before( :each ) do
          @spool_pathparent.stub!( :writable? ).and_return( true )
        end

        it "should try to create the spool_dir" do
          @spool_pathname.should_receive( :mkpath ).once
          Spooler.new( @spool_path )
        end
      end

      context "and it can't create the spool dir" do
        before( :each ) do
          @spool_pathparent.stub!( :writable? ).and_return( false )
        end

        it "should raise an exception" do
          lambda { Spooler.new( @spool_path ) }.should raise_error( Errno::EACCES )
        end
      end
    end

    context "the spool_dir exists" do
      it "should raise an exception if it can't create a file" do
        @spool_pathname.stub!( :writable? ).and_return( false )
        lambda { Spooler.new( @spool_path ) }.should raise_error( Errno::EACCES )
      end

      it "should raise an exception if it can't read a file" do
        @spool_pathname.stub!( :readable? ).and_return( false )
        lambda { Spooler.new( @spool_path ) }.should raise_error( Errno::EACCES )
      end
    end
  end

  describe "#put" do
    before( :each ) do
      @stubbed_spool = mock( Spool, :put => true )
      Spool.stub!( :new ).and_return( @stubbed_spool )
    end
    it "should create queue_dir object in the queues attribute if it doesn't exist yet" do
      @instance.spools.delete :my_spool
      @instance.put( :my_spool, 'some value' )
      @instance.spools[:my_spool].should_not be_nil
    end

    it "should return the filename of the spool file" do
      pending
      @instance.put( :my_spool, 'some value' ).should be_a( String )
    end

    context "queue names that try to escape the queue_dir" do
      it "should raise an exception on directory traversal attempts" do
        lambda { @instance.put "../../foo", 'some value' }.should raise_error
      end
      it "should not raise an exception if following a symlink"
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
