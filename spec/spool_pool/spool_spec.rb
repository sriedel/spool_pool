require 'spec_helper'

describe SpoolPool::Spool do
  before( :each ) do
    @testspoolpath = File.join( TEST_SPOOL_ROOT, "spools" )
    @pathname = Pathname.new( @testspoolpath )
    @pathname.mkpath
    @pathname.chmod 0755
    @instance = SpoolPool::Spool.new( @pathname )
  end

  after( :each ) do
    @pathname.rmtree if @pathname.exist?
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

      it "should raise an exception if it can't create a file" do
        with_fs_mode( @pathname, 0555 ) do
          lambda { SpoolPool::Spool.new( @pathname ) }.should raise_error( Errno::EACCES )
        end
      end

      it "should raise an exception if it can't read a file" do
        with_fs_mode( @pathname, 0333 ) do
          lambda { SpoolPool::Spool.new( @pathname ) }.should raise_error( Errno::EACCES )
        end
      end
    end

    context "if the directory doesn't exist" do
      before( :each ) do
        @pathname.unlink if @pathname.exist?
      end

      it "should not check accessablity" do
        @pathname.should_not_receive( :readable? )
        @pathname.should_not_receive( :writable? )
        SpoolPool::Spool.new( @pathname )
      end
    end
  end

  describe "#put" do
    before( :each ) do
      @data = 'some data'
    end

    context "the queue directory doesn't exist" do
      before( :each ) do
        @pathname.rmtree if @pathname.exist?
      end

      it "should try to create the queue directory" do
        path = @instance.put( @data )

        @pathname.should exist
      end

      it "should raise an exception if it can't create the spool_dir" do
        with_fs_mode( @pathname.parent, 0000 ) do
          lambda { @instance.put( @data ) }.should raise_error
        end
      end
    end

    it "should return the path of the stored file" do
      path = @instance.put( @data )
      Pathname.new( path ).read.should == @instance.serialize( @data )
    end
  end

  describe "the #get/#put pair" do
    it "should serialize and deserialize the data written" do
      data = { :foo => 2, :bar => [ "some string", 3.45, ] }

      @instance.put data
      read_data = @instance.get

      read_data.should == data
    end
  end

  describe "#get" do
    before( :each ) do
      @pathname.mkpath
      @pathname.chmod 0755
    end

    after( :each ) do
      @pathname.rmtree if @pathname.exist?
    end

    it "should return the contents of one of the files with the oldest ctime in spool directory" do
      oldest_data = 'foo'
      youngest_data = 'blubb'
      @instance.put oldest_data
      sleep 1
      @instance.put youngest_data

      @instance.get.should == oldest_data
    end

    context "no file is available in the requested spool" do
      before( :each ) do
        @pathname.children.each { |child| child.unlink }
      end

      it "should return nil" do
        @instance.get.should be_nil
      end
    end

    it "should raise an exception if the queue directory is not readable" do
      with_fs_mode( @pathname, 0000 ) do
        lambda { @instance.get }.should raise_error
      end
    end

    it "should delete the read file" do
      path = Pathname.new( @instance.put( @data ) )
      @instance.get
      path.should_not be_exist
    end

    it "should raise an exception if the oldest file in the queue directory is not readable" do
      path = Pathname.new( @instance.put( @data ) )
      with_fs_mode( path, 0333 ) do
        lambda { @instance.get }.should raise_error
      end
    end

    it "should raise an exception if the oldest file in the queue directory is not deleteable" do
      path = Pathname.new( @instance.put( @data ) )
      with_fs_mode( @pathname, 0555 ) do
        lambda { @instance.get }.should raise_error
      end
    end
  end

  describe "#flush" do
    context "each file in the spool directory" do
      before( :each ) do
        @oldest_data = "oldest data"
        @middle_data = "middle data"
        @youngest_data = "youngest data"
        @oldest_file = @instance.put @oldest_data
        sleep 1
        @middle_file = @instance.put @middle_data
        sleep 1
        @youngest_file = @instance.put @youngest_data
      end

      it "should be yielded to the passed block" do
        times_yielded = 0
        @instance.flush { times_yielded += 1 }
        times_yielded.should == 3
      end

      it "should be yielded ordered by date, oldest first" do
        times_yielded = 0
        @instance.flush do |data|
          times_yielded += 1
          case times_yielded
            when 1 then data.should == @oldest_data
            when 2 then data.should == @middle_data
            when 3 then data.should == @youngest_data
          end
        end
      end

      it "should be deleted after it was processed" do
        times_yielded = 0
        @instance.flush do |data|
          times_yielded += 1
          case times_yielded
            when 1 then File.exist?(@oldest_file).should_not be_true
            when 2 then File.exist?(@middle_file).should_not be_true
            when 3 then File.exist?(@youngest_file).should_not be_true
          end
        end
      end
    end

    it "should raise an exception if the queue directory is not readable" do
      with_fs_mode( @pathname, 0000 ) do
        lambda { @instance.fetch }.should raise_error
      end
    end

    it "should raise an exception if the oldest file in the queue directory is not readable" do
      path = Pathname.new( @instance.put( @data ) )
      with_fs_mode( path, 0333 ) do
        lambda { @instance.fetch }.should raise_error
      end
    end

    it "should raise an exception if the oldest file in the queue directory is not deleteable" do
      path = Pathname.new( @instance.put( @data ) )
      with_fs_mode( @pathname, 0555 ) do
        lambda { @instance.fetch }.should raise_error
      end
    end
  end
end
