require 'tempfile'
require 'delegate'
require 'tmpdir'
require 'thread'

module SpoolPool
=begin rdoc
A class to deal with the writing of spool files. Currently uses Tempfile
to do most of the heavy lifting.

Most of this file has been adapted from the Tempfile code in the Ruby 1.9.1
class library, written by yugui.
=end
  class File < DelegateClass( ::File )
    attr_reader :path

=begin rdoc
  Returns the data read from the given +filename+, and deletes the file 
  before returning.

  Yields the read data also to an optionally given block. If you give a block
  to process your data and your code throws an exception, the file will not
  be deleted and another processing of the data can be attempted in the 
  future.
=end
    def self.safe_read( filename )
      data = ::File.read( filename )
      yield data if block_given?
      ::File.unlink( filename )
      data
    end

=begin rdoc
Stores the given +data+ in a unique file in the directory +basepath+.
+basepath+ can be either a file path as a String or a Pathname.

If the data can't be written to the file (permissions, quota, I/O errors...),
it will attempt to delete the file before throwing an exception.

Returns the path of the file storing the data.
=end
    def self.write( basepath, data ) 
      file = nil
      begin
        file = new( basepath.to_s )
        file.write data
      rescue
        file.unlink if file
        raise $!
      else
        file.path
      ensure
        file.close
      end
    end

    # If no block is given, this is a synonym for new().
    #
    # If a block is given, it will be passed the spool file as an argument,
    # and the spool file will automatically be closed when the block
    # terminates.  The call returns the value of the block.
    def self.open(*args)
      file = new(*args)
      return file unless block_given?

      begin
        yield(file)
      ensure
        file.close
      end
    end

    MAX_TRY = 10
    FILE_PERMISSIONS = 0600
    @@lock = Mutex.new

    # Creates a spool file of mode 0600 in the directory +basedir+,
    # opens it with mode "w+", and returns a SpoolPool::File object which
    # represents the created spool file.  A SpoolPool::File object can be
    # treated just like a normal File object.
    #
    def initialize( basedir )
      create_threadsafe_spoolname( basedir ) do |spoolname|
        @spoolfile = ::File.open( spoolname, 
                                  ::File::RDWR | ::File::CREAT | ::File::EXCL, 
                                  FILE_PERMISSIONS )
        @path = spoolname

        super(@spoolfile)
        # Now we have all the File/IO methods defined, you must not
        # carelessly put bare puts(), etc. after this.
      end
    end

    # Opens or reopens the file with mode "r+".
    def open
      @spoolfile.close if @spoolfile
      @spoolfile = ::File.open(@path, 'r+')
      __setobj__(@spoolfile)
    end

    #Closes the file.
    def close
      @spoolfile.close if @spoolfile
      @spoolfile = nil
    end

    # Unlinks the file.
    def unlink
      # keep this order for thread safeness
      begin
        if ::File.exist?(@path)
          close unless closed?
          ::File.unlink(@path)
        end
        @path = nil
      rescue Errno::EACCES
        # may not be able to unlink on Windows; just ignore
      end
    end

    # Returns the size of the file.  As a side effect, the IO
    # buffer is flushed before determining the size.
    def size
      return 0 unless @spoolfile

      @spoolfile.flush
      @spoolfile.stat.size
    end
    alias length size

    private
    def spoolfilename_for_try(n)
      "#{Time.now.to_f}-#{$$}-#{n}"
    end

    def create_threadsafe_spoolname( basedir )
      lock = spoolname = nil
      n = failure = 0

      @@lock.synchronize {
        begin
          begin
            spoolname = ::File.join( basedir, spoolfilename_for_try(n) )
            lock = spoolname + '.lock'
            n += 1
          end while ::File.exist?(lock) or ::File.exist?(spoolname)
          Dir.mkdir(lock)
        rescue
          failure += 1
          retry if failure < MAX_TRY
          raise "cannot generate spool file `%s': #{$!}" % spoolname
        end
      }

      yield spoolname
      Dir.rmdir(lock)
    end

  end
end
