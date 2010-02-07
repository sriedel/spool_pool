require 'spec_helper'
require 'spooler'

describe Spooler do
  before( :each ) do
    @root_pathname = Pathname.new( TEST_SPOOL_ROOT )
    @spool_path = File.join( TEST_SPOOL_ROOT, "spooler" )
    @spool_pathname = Pathname.new( @spool_path )
    @spool_pathname.mkpath
    @spool_pathname.chmod 0755

    @instance = Spooler.new( @spool_path )
    @data = 'some data'
  end

  after( :each ) do
    @spool_pathname.rmtree
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
      filename = @instance.put( :my_spool, 'some value' )
      filename.should be_a( String )
      Pathname.new( filename ).read.should == 'some value'
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

  describe "#get" do
    it "should return the deserialized contents of the oldest file in the given queue directory"

    it "should return the contents of one of the files with the oldest ctime in spool directory" do
      oldest_data = 'foo'
      youngest_data = 'blubb'
      @instance.put :my_spool, oldest_data
      sleep 1
      @instance.put :my_spool, youngest_data

      @instance.get( :my_spool ).should == oldest_data
    end

    context "if the spool object doesn't exist yet" do
      context "if such a spool directory exists" do
        before( :each ) do
          @instance.put :my_spool, @data
          @instance.spools.delete :my_spool
        end

        it "should create a spool object" do
          @instance.get :my_spool
          @instance.spools[:my_spool].should_not be_nil
        end

        it "should return the result of the get operation" do
          @instance.get( :my_spool ).should == @data
        end
      end

      context "if such a spool directory does not exist" do
        it "should return nil" do
          @instance.get( :non_existant_spool ).should be_nil
        end
      end
    end

    context "no file is available in the requested spool" do
      before( :each ) do
        @spool_pathname.children.each { |child| child.unlink }
      end

      it "should return nil" do
        @instance.get( :my_spool ).should be_nil
      end
    end

    it "should raise an exception if the queue directory is not readable" do
      @instance.put :my_spool, "some data"

      @spool_pathname.chmod 0
      lambda { @instance.get( :my_spool ) }.should raise_error
      @spool_pathname.chmod 0755
    end

    it "should delete the read file" do
      path = Pathname.new( @instance.put( :my_spool, @data ) )
      @instance.get :my_spool
      path.should_not be_exist
    end

    it "should raise an exception if the oldest file in the queue directory is not readable" do
      path = Pathname.new( @instance.put( :my_spool, @data ) )
      path.chmod 0333
      lambda { @instance.get( :my_spool ) }.should raise_error
      path.chmod 0755
      path.unlink
    end

    it "should raise an exception if the oldest file in the queue directory is not deleteable" do
      path = Pathname.new( @instance.put( :my_spool, @data ) )
      @instance.spools[:my_spool].pathname.chmod 0555
      lambda { @instance.get( :my_spool ) }.should raise_error
      @instance.spools[:my_spool].pathname.chmod 0755
      path.unlink
    end

    context "queue names that try to escape the queue_dir" do
      it "should raise an exception on directory traversal attempts" do
        lambda { @instance.get "../../foo" }.should raise_error
      end

      it "should not raise an exception if following a symlink" do
        real_path = Pathname.new( @spool_pathname + "real" )
        real_path.mkpath
        symlinked_path = Pathname.new( @spool_pathname + "symlink" )
        symlinked_path.make_symlink( real_path.to_s )

        lambda { @instance.get "symlink" }.should_not raise_error

        symlinked_path.unlink
        real_path.rmtree
      end
    end
  end

  describe "#flush" do
    context "each file in the spool directory" do
      before( :each ) do
        @oldest_data = "oldest data"
        @middle_data = "middle data"
        @youngest_data = "youngest data"
        @oldest_file = @instance.put :my_spool, @oldest_data
        sleep 1
        @middle_file = @instance.put :my_spool, @middle_data
        sleep 1
        @youngest_file = @instance.put :my_spool, @youngest_data
      end

      it "should be yielded to the passed block" do
        times_yielded = 0
        @instance.flush( :my_spool ) { times_yielded += 1 }
        times_yielded.should == 3
      end

      it "should be yielded ordered by date, oldest first" do
        times_yielded = 0
        @instance.flush( :my_spool ) do |data|
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
        @instance.flush( :my_spool ) do |data|
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
      @instance.put( :my_spool, @data )
      @instance.spools[:my_spool].pathname.chmod 0
      lambda { @instance.flush( :my_spool ) }.should raise_error
      @instance.spools[:my_spool].pathname.chmod 0755
    end

    it "should raise an exception if the oldest file in the queue directory is not readable" do
      path = Pathname.new( @instance.put( :my_spool, @data ) )
      path.chmod 0333
      lambda { @instance.flush( :my_spool ) }.should raise_error
      path.chmod 0755
      path.unlink
    end

    it "should raise an exception if the oldest file in the queue directory is not deleteable" do
      path = Pathname.new( @instance.put( :my_spool, @data ) )
      @instance.spools[:my_spool].pathname.chmod 0555
      lambda { @instance.flush( :my_spool ) {} }.should raise_error
      @instance.spools[:my_spool].pathname.chmod 0755
      path.unlink
    end

    context "queue names that try to escape the queue_dir" do
      it "should raise an exception on directory traversal attempts" do
        lambda { @instance.flush( "../../foo" ) {} }.should raise_error
      end

      it "should not raise an exception if following a symlink" do
        real_path = Pathname.new( @spool_pathname + "real" )
        real_path.mkpath
        symlinked_path = Pathname.new( @spool_pathname + "symlink" )
        symlinked_path.make_symlink( real_path.to_s )

        lambda { @instance.flush( "symlink" ) {} }.should_not raise_error

        symlinked_path.unlink
        real_path.rmtree
      end
    end
  end
end
