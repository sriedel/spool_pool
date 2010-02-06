require 'mockfs'
require 'mockfs/override'

module MockedFilesystem

  class MockedNode
    attr_reader :path
    attr_reader :mode
    def initialize( path, mode )
      @path, @mode = path, mode
      create
      set_mode
    end

    def create
      raise "Override me!"
    end

    def set_mode
      MockFS.file.chmod @mode, @path
    end
  end

  class MockedDirectory < MockedNode
    def create
      MockFS.fill_path @path
    end
  end

  class MockedFile < MockedNode
    def initialize( path, mode, content = nil )
      @content = content
      super( path, mode )
    end

    def create
      MockFS.file.open( @path, File::CREAT ) do |fh|
        fh.puts @content if @content
      end
    end
  end

  class MockedFileSystem
    SPOOLER_ROOT = File.join( "var", "spool", "spooler" )

    attr_reader :hierarchy

    def initialize
      MockFS.mock = true
      @hierarchy = {
        :root => MockedDirectory.new( SPOOLER_ROOT, 0777 ),
        :inaccessable_queue_dir => MockedDirectory.new( File.join( SPOOLER_ROOT, "non_executable" ), 0000 ),
        :unreadable_queue_dir => MockedDirectory.new( File.join( SPOOLER_ROOT, "non_readable" ), 0333 ),
        :unwriteable_queue_dir => MockedDirectory.new( File.join( SPOOLER_ROOT, "non_writeable" ), 0555 ),
        :empty_queue_dir => MockedDirectory.new( File.join( SPOOLER_ROOT, "empty_queue" ), 0777 ),
        :queue_dir => MockedDirectory.new( File.join( SPOOLER_ROOT, "my_queue" ), 0777 ),
        :unreadable_queued_file => MockedFile.new( File.join( SPOOLER_ROOT, "my_queue", "unreadable" ), 0333 ),
        :unwriteable_queued_file => MockedFile.new( File.join( SPOOLER_ROOT, "my_queue", "unwriteable" ), 0555 ),
        :queue_file => MockedFile.new( File.join( SPOOLER_ROOT, "my_queue", "queued_file" ), 0666 )
      }
    end
  end
end
