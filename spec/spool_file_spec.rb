require 'spec_helper'
require 'spool_file'

describe SpoolFile do
  
  before( :each ) do
    @testspoolpath = File.join TEST_SPOOL_ROOT, "spool_files"
    @basepath = Pathname.new( @testspoolpath )
    @basepath.mkpath
    @data = "my_data"
  end

  after( :each ) do
    @basepath.unlink
  end

  it "should have a pathname attribute" do
    SpoolFile.new( @basepath ).should respond_to( :pathname )
  end

  describe "#initialize" do
    it "should set the pathname" do
      SpoolFile.new( @basepath ).pathname.should == @basepath
    end
  end

  describe ".create_for_write" do
    it "should create a filename in the given directory" do
      SpoolFile.create_for_write( @basepath ).pathname.to_s.should =~ /\A#{@basepath}/
    end

    it "should return the pathname for the file" do
      SpoolFile.create_for_write( @basepath ).should be_a( SpoolFile )
    end
  end

  describe "#write" do
    before( :each ) do
      @spoolfilepath = @basepath + "spoolfile_write_test"
      @instance = SpoolFile.new( @spoolfilepath )
      @mock_filehandle = mock( File )
    end

    after( :each ) do
      @spoolfilepath.unlink rescue nil
    end

    it "should write the passed data to the file" do
      @instance.write( @data )
      @instance.pathname.read.should == @data
    end

    it "should raise an exception if the file can't be created" do
      @spoolfilepath.stub!( :open ).and_raise( RuntimeError )
      lambda { @instance.write( @data ) }.should raise_error( RuntimeError )
    end

    it "should raise an exception if the data can't be written" do
      @spoolfilepath.stub!( :open ).and_yield( @mock_filehandle )
      @mock_filehandle.stub!( :write ).and_raise( RuntimeError )
      lambda { @instance.write( @data ) }.should raise_error( RuntimeError )
    end

    context "on an aborted operation" do
      before( :each ) do
        @mock_filehandle.stub!( :write ).and_raise( RuntimeError )
        @spoolfilepath.stub!( :open ).and_yield( @mock_filehandle )
      end
      
      it "should delete any created file again" do
        @spoolfilepath.should_receive( :unlink ).at_least(1).times
        lambda { @instance.write( @data ) }.should raise_error( RuntimeError )
      end
    end
  end
end
