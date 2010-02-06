require 'spec_helper'
require 'spool_file'

describe SpoolFile do
  
  before( :each ) do
    @basepath = Pathname.new( "/var/spool/spooler/my_queue" )
    @data = "my_data"
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
      @instance = SpoolFile.new( @basepath )
      @mock_filehandle = mock( File )
      @basepath.stub!( :open ).and_yield( @mock_filehandle )
      @basepath.stub!( :unlink ).and_return( true )
    end

    it "should write the passed data to the file" do
      @mock_filehandle.should_receive( :puts ).with( @data )
      @instance.write( @data )
    end

    it "should raise an exception if the file can't be created" do
      @basepath.stub!( :open ).and_raise( RuntimeError )
      lambda { @instance.write( @data ) }.should raise_error( RuntimeError )
    end

    it "should raise an exception if the data can't be written" do
      @mock_filehandle.stub!( :puts ).and_raise( RuntimeError )
      lambda { @instance.write( @data ) }.should raise_error( RuntimeError )
    end

    context "on an aborted operation" do
      before( :each ) do
        @mock_filehandle.stub!( :puts ).and_raise( RuntimeError )
      end
      
      it "should delete any created file again" do
        @basepath.should_receive( :unlink )
        lambda { @instance.write( @data ) }.should raise_error( RuntimeError )
      end
    end
  end
end
