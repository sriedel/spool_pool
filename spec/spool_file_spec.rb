require 'spec_helper'
require 'spool_file'

describe SpoolFile do
  
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

  it "should have a pathname attribute" do
    SpoolFile.new( @basepath ).should respond_to( :pathname )
  end

  describe "#initialize" do
    it "should set the pathname" do
      pending
      SpoolFile.new( @basepath ).pathname.should == @basepath
    end
  end

  describe ".create_for_write" do
    it "should create a filename in the given directory" do
      pending
      SpoolFile.create_for_write( @basepath ).pathname.to_s.should =~ /\A#{@basepath}/
    end

    it "should return the pathname for the file" do
      pending
      SpoolFile.create_for_write( @basepath ).should be_a( SpoolFile )
    end

    it "should have a different filename for each file" do
      pending
      spoolfile1 = SpoolFile.create_for_write( @basepath )
      spoolfile2 = SpoolFile.create_for_write( @basepath )
      spoolfile1.pathname.to_s.should_not == spoolfile2.pathname.to_s
    end
  end

  describe "#write" do
    before( :each ) do
      # @spoolfilepath = @basepath + "spoolfile_write_test"
      #@instance = SpoolFile.new( @spoolfilepath )
      #@mock_filehandle = mock( File )
    end

    it "should write the passed data to the file" do
      pending
      @instance.write( @data )
      @instance.pathname.read.should == @data
    end

    it "should raise an exception if the file can't be created" do
      pending
      @spoolfilepath.stub!( :open ).and_raise( RuntimeError )
      lambda { @instance.write( @data ) }.should raise_error( RuntimeError )
    end

    it "should raise an exception if the data can't be written" do
      pending
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
        pending
        @spoolfilepath.should_receive( :unlink ).at_least(1).times
        lambda { @instance.write( @data ) }.should raise_error( RuntimeError )
      end
    end
  end

  describe ".write" do
    before( :each ) do
      @failing_tempfile = Tempfile.new( nil, @basepath.to_s )
      @failing_tempfile.stub!( :write ).and_raise( RuntimeError )
    end

    after( :each ) do
    end

    it "should create a filename in the given directory" do
      SpoolFile.write( @basepath, @data ).should =~ /\A#{@basepath}/
    end

    it "should return the path for the file containing the spooled data" do
      path = SpoolFile.write( @basepath, @data )
      Pathname.new( path ).read.should == @data
    end

    it "should have a different filename for each file" do
      spoolfile1 = SpoolFile.write( @basepath, @data )
      spoolfile2 = SpoolFile.write( @basepath, @data )
      spoolfile1.should_not == spoolfile2
    end

    it "should raise an exception if the file can't be created" do
      @basepath.chmod 0000
      lambda { SpoolFile.write( @basepath, @data ) }.should raise_error
      @basepath.chmod 0755
    end

    it "should raise an exception if the data can't be written" do
      Tempfile.stub!( :new ).and_return( @failing_tempfile )

      lambda { SpoolFile.write( @basepath, @data ) }.should raise_error( RuntimeError )
    end

    context "on an aborted operation" do
      before( :each ) do
        Tempfile.stub!( :new ).and_return( @failing_tempfile )
      end
      
      it "should delete any created file again" do
        lambda { SpoolFile.write( @basepath, @data ) }.should raise_error( RuntimeError )
        @basepath.children.should be_empty
      end
    end
  end
end
