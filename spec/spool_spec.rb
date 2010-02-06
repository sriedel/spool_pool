require 'spec_helper'
require 'spool'

describe Spool do
  before( :each ) do
    @pathname = mock( Pathname, :exist? => true,
                                :writable? => true,
                                :readable? => true,
                                :+ => mock( Pathname, :null_object => true ) )
    @instance = Spool.new( @pathname )
  end

  it "should have a pathname attribute" do
    @instance.should respond_to( :pathname )
  end

  describe "#initialize" do
    it "should set the pathname attribute" do
      @instance.pathname.should == @pathname
    end

    context "if the directory exists" do
      before( :each ) do
        @pathname.stub!( :exist? ).and_return( true )
      end

      it "should raise an exception if it can't create a file" do
        @pathname.stub!( :writable? ).and_return( false )
        lambda { Spool.new( @pathname ) }.should raise_error( Errno::EACCES )
      end

      it "should raise an exception if it can't read a file" do
        @pathname.stub!( :readable? ).and_return( false )
        lambda { Spool.new( @pathname ) }.should raise_error( Errno::EACCES )
      end
    end

    context "if the directory doesn't exist" do
      it "should not check accessablity" do
        @pathname.stub!( :exist? ).and_return( false )
        @pathname.should_not_receive( :readable? )
        @pathname.should_not_receive( :writable? )
        Spool.new( @pathname )
      end
    end
  end

  describe "#put" do
    before( :each ) do
      @data = 'some data'
    end

    context "the queue directory doesn't exist" do
      before( :each ) do
        @pathname.stub!( :exist? ).and_return( false )
      end

      it "should try to create the queue directory" do
        @pathname.should_receive( :mkpath )
        @instance.put( @data )
      end

      it "should raise an exception if it can't create the spool_dir"
    end

    context "the queue directory exists" do
      before( :each ) do
        @pathname.stub!( :exist? ).and_return( true )
      end

      it "shouldn't try to create the directory" do
        @pathname.should_not_receive( :mkpath )
        @instance.put( @data )
      end
    end

    it "should return the pathname of the stored file" do
      mock_spoolfile = mock( SpoolFile, :write => true,
                                        :pathname => mock( Pathname ) )
      SpoolFile.stub!( :new ).and_return( mock_spoolfile )
      @instance.put( @data ).to_s.should == mock_spoolfile.pathname.to_s
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
