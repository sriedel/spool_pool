require 'spec_helper'
require 'spool'

describe Spool do
  before( :each ) do
    @testspoolpath = File.join( TEST_SPOOL_ROOT, "spools" )
    @pathname = Pathname.new( @testspoolpath )
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
        @pathname.mkpath
      end

      after( :each ) do
        @pathname.unlink
      end

      it "should raise an exception if it can't create a file" do
        @pathname.chmod 0555
        lambda { Spool.new( @pathname ) }.should raise_error( Errno::EACCES )
        @pathname.chmod 0755
      end

      it "should raise an exception if it can't read a file" do
        @pathname.chmod 0333
        lambda { Spool.new( @pathname ) }.should raise_error( Errno::EACCES )
        @pathname.chmod 0755
      end
    end

    context "if the directory doesn't exist" do
      before( :each ) do
        @pathname.unlink if @pathname.exist?
      end

      it "should not check accessablity" do
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
        @pathname.unlink if @pathname.exist?
      end

      it "should try to create the queue directory" do
        path = @instance.put( @data )

        @pathname.should exist
        path.unlink if path.exist?
        @pathname.unlink
      end

      it "should raise an exception if it can't create the spool_dir" do
        @pathname.parent.chmod 000
        lambda { @instance.put( @data ) }.should raise_error
        @pathname.parent.chmod 755
      end
    end

    it "should return the pathname of the stored file" do
      path = @instance.put( @data )
      path.read.should == @data
      path.unlink 
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
