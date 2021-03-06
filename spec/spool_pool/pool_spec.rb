require 'spec_helper'

describe SpoolPool::Pool do
  before( :each ) do
    @root_pathname = Pathname.new( TEST_SPOOL_ROOT )
    @spool_path = File.join( TEST_SPOOL_ROOT, "spooler" )
    @spool_pathname = Pathname.new( @spool_path )
    @spool_pathname.mkpath
    @spool_pathname.chmod 0755

    @instance = SpoolPool::Pool.new( @spool_path )
    @spool = :my_spool
    @data = 'some data'
  end

  after( :each ) do
    @spool_pathname.chmod 0755 if @spool_pathname.exist?
    @spool_pathname.rmtree if @spool_pathname.exist?
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

  describe ".validate_pool_dir" do
    context "if the pool directory does not exist, examine the parent dir" do
      before( :each ) do
        @spool_pathname.rmdir if @spool_pathname.exist?
      end

      after( :each ) do
        @root_pathname.chmod 0755
      end


      context "it does not allow the pool directory to be created" do
        before( :each ) do
          @root_pathname.chmod 0555
        end
        it "should throw an exception" do
          lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should raise_error( Errno::EACCES )
        end
      end
      
      context "if it is not executable" do
        before( :each ) do
          @root_pathname.chmod 0666
        end

        it "should throw an exception" do
          lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should raise_error
        end
      end

      context "it allows the pool directory to be created" do
        before( :each ) do
          @root_pathname.chmod 0755
        end

        it "should not raise an exception" do
          lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should_not raise_error
        end
      end
    end

    context "if the pool directory exists" do
      before( :each ) do
        @spool_pathname.mkpath
        @spool_pathname.chmod 0755
      end

      context "if it is not readable" do
        before( :each ) do
          @spool_pathname.chmod 0333
        end

        it "should throw an exception" do
          lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should raise_error
        end
      end

      context "if it is not writeable" do
        before( :each ) do
          @spool_pathname.chmod 0555
        end

        it "should throw an exception" do
          lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should raise_error
        end
      end

      context "if it is not executable" do
        before( :each ) do
          @spool_pathname.chmod 0666
        end

        it "should throw an exception" do
          lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should raise_error
        end
      end

      context "if it is read- and writeable" do 
        context "if subdirectories exist" do
          before( :each ) do
            @spool_dir1 = @spool_pathname + "spool1"
            @spool_dir1.mkpath
            @spool_dir1.chmod 0755
            @spool_dir2 = @spool_pathname + "spool2"
            @spool_dir2.mkpath
            @spool_dir2.chmod 0755
          end

          after( :each ) do
            @spool_dir1.chmod 0755 if @spool_dir1.exist?
            @spool_dir2.chmod 0755 if @spool_dir2.exist?
          end

          context "if any is not readable" do
            before( :each ) do
              @spool_dir1.chmod 0333
            end

            it "should throw an exception" do
              lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should raise_error
            end
          end

          context "if any is not writeable" do
            before( :each ) do
              @spool_dir1.chmod 0555
            end

            it "should throw an exception" do
              lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should raise_error
            end
          end

          context "if it is not executable" do
            before( :each ) do
              @spool_dir1.chmod 0666
            end

            it "should throw an exception" do
              lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should raise_error
            end
          end

          context "if they are all read- and writeable" do
            context "if there are files" do 
              before( :each ) do
                @spool_file1 = @spool_dir1 + "file1"
                @spool_file2 = @spool_dir1 + "file2"
                FileUtils.touch @spool_file1.to_s
                @spool_file1.chmod 0644
                FileUtils.touch @spool_file2.to_s
                @spool_file2.chmod 0644
              end

              context "if any are not readable" do
                before( :each ) do
                  @spool_file1.chmod 0222
                end

                it "should throw an exception" do
                  lambda { SpoolPool::Pool.validate_pool_dir( @spool_pathname.to_s ) }.should raise_error
                end
              end
            end
          end
        end
      end
    end
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
          SpoolPool::Pool.new( @spool_path )
          @spool_pathname.should exist
          @spool_pathname.unlink if @spool_pathname.exist?
        end
      end

      context "and it can't create the spool dir" do
        it "should raise an exception" do
          with_fs_mode( @root_pathname, 0555 ) do
            lambda { SpoolPool::Pool.new( @spool_path ) }.should raise_error( Errno::EACCES )
          end
        end
      end
    end

    context "the spool_dir exists" do
      it "should raise an exception if it can't create a file" do
        with_fs_mode( @spool_pathname, 0555 ) do
          lambda { SpoolPool::Pool.new( @spool_path ) }.should raise_error( Errno::EACCES )
        end
      end

      it "should raise an exception if it can't read a file" do
        with_fs_mode( @spool_pathname, 0333 ) do
          lambda { SpoolPool::Pool.new( @spool_path ) }.should raise_error( Errno::EACCES )
        end
      end
    end
  end

  describe "#put" do
    it "should create queue_dir object in the queues attribute if it doesn't exist yet" do
      @instance.spools.delete @spool
      filename = @instance.put( @spool, 'some value' )
      @instance.spools[@spool].should_not be_nil
      File.unlink( filename ) if File.exist?( filename )
    end

    it "should return the filename of the spool file" do
      filename = @instance.put( @spool, 'some value' )
      filename.should be_a( String )
      Pathname.new( filename ).read.should == SpoolPool::Spool.serialize( 'some value' )
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

  describe "the #get/#put pair" do
    before( :each ) do
      @data = { :foo => "some value", :bar => [ 3, 3.45, "another string" ] }
      @instance.put @spool, @data
    end

    it "should serialize/deserialize the data written and returned" do
      @instance.get( @spool ).should == @data
    end

    it "should serialize/deserialize the data written and yielded" do
      @instance.get( @spool ) do |read_data|
        read_data.should == @data
      end
    end
  end

  describe "#get" do
    it "should yield the contents of one of the files with the oldest spooling time in spool directory" do
      oldest_data = 'foo'
      youngest_data = 'blubb'
      @instance.put @spool, oldest_data
      @instance.put @spool, youngest_data

      @instance.get( @spool ) { |spool_data| spool_data.should == oldest_data }
    end

    context "if the spool object doesn't exist yet" do
      context "if such a spool directory exists" do
        before( :each ) do
          @instance.put @spool, @data
          @instance.spools.delete @spool
        end

        it "should create a spool object" do
          @instance.get( @spool ) {}
          @instance.spools[@spool].should_not be_nil
        end

        it "should return the result of the get operation" do
          @instance.get( @spool ){ |spool_data| spool_data.should == @data }
        end
      end

      context "if such a spool directory does not exist" do
        it "should return nil" do
          @instance.get( :non_existant_spool ){}.should be_nil
        end
      end
    end

    context "no file is available in the requested spool" do
      before( :each ) do
        @spool_pathname.children.each { |child| child.unlink }
      end

      it "should return nil" do
        @instance.get( @spool ){}.should be_nil
      end
    end

    it "should raise an exception if the queue directory is not readable" do
      @instance.put @spool, "some data"

      with_fs_mode( @spool_pathname, 0000 ) do
        lambda { @instance.get( @spool ){} }.should raise_error
      end
    end
  
    context "no block was passed" do
      before( :each ) do
        path = @instance.put( @spool, @data ) 
        @path = Pathname.new( path )
      end

      it "should delete the read file" do
        @instance.get @spool
        @path.should_not be_exist
      end

      it "should return the result of the get operation" do
        @instance.get( @spool ).should == @data
      end
    end

    context "a block was passed" do
      context "if no exception was raised in the block" do
        it "should delete the read file" do
          path = Pathname.new( @instance.put( @spool, @data ) )
          @instance.get( @spool ) {}
          path.should_not be_exist
        end
      end

      context "if an exception was raised in the block" do
        it "should not delete the read file" do
          path = Pathname.new( @instance.put( @spool, @data ) )
          lambda{ @instance.get( @spool ) {raise RuntimeError} }
          path.should be_exist
        end

        it "should let the exception bubble up" do
          path = Pathname.new( @instance.put( @spool, @data ) )
          lambda{ @instance.get( @spool ) {raise RuntimeError} }.should raise_error( RuntimeError )
        end
      end
    end

    it "should raise an exception if the oldest file in the queue directory is not readable" do
      path = Pathname.new( @instance.put( @spool, @data ) )
      with_fs_mode( path, 0333 ) do
        lambda { @instance.get( @spool ){} }.should raise_error
      end
      path.unlink
    end

    it "should raise an exception if the oldest file in the queue directory is not deleteable" do
      path = Pathname.new( @instance.put( @spool, @data ) )
      with_fs_mode( @instance.spools[@spool].pathname, 0555 ) do
        lambda { @instance.get( @spool ){} }.should raise_error
      end
      path.unlink
    end

    context "queue names that try to escape the queue_dir" do
      it "should raise an exception on directory traversal attempts" do
        lambda { @instance.get( "../../foo" ){} }.should raise_error
      end

      it "should not raise an exception if following a symlink" do
        real_path = Pathname.new( @spool_pathname + "real" )
        real_path.mkpath
        symlinked_path = Pathname.new( @spool_pathname + "symlink" )
        symlinked_path.make_symlink( real_path.to_s )

        lambda { @instance.get( "symlink" ){} }.should_not raise_error

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
        @oldest_file = @instance.put @spool, @oldest_data
        @middle_file = @instance.put @spool, @middle_data
        @youngest_file = @instance.put @spool, @youngest_data
      end

      it "should be yielded to the passed block" do
        times_yielded = 0
        @instance.flush( @spool ) { times_yielded += 1 }
        times_yielded.should == 3
      end

      it "should be yielded ordered by date, oldest first" do
        times_yielded = 0
        @instance.flush( @spool ) do |data|
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
        @instance.flush( @spool ) do |data|
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
      @instance.put( @spool, @data )
      with_fs_mode( @instance.spools[@spool].pathname, 0000 ) do
        lambda { @instance.flush( @spool ) }.should raise_error
      end
    end

    it "should raise an exception if the oldest file in the queue directory is not readable" do
      path = Pathname.new( @instance.put( @spool, @data ) )
      with_fs_mode( path, 0333 ) do
        lambda { @instance.flush( @spool ) }.should raise_error
      end
      path.unlink
    end

    it "should raise an exception if the oldest file in the queue directory is not deleteable" do
      path = Pathname.new( @instance.put( @spool, @data ) )
      with_fs_mode( @instance.spools[@spool].pathname, 0555 ) do
        lambda { @instance.flush( @spool ) {} }.should raise_error
      end
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
