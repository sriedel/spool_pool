require 'tempfile'

module SpoolPool
=begin rdoc
A class to deal with the writing of spool files. Currently uses Tempfile
to do most of the heavy lifting.
=end
  class File

=begin rdoc
Stores the given +data+ in a unique file in the directory +basepath+. 

If the data can't be written to the file (permissions, quota, I/O errors...),
it will attempt to delete the file before throwing an exception.

Returns the path of the file storing the data.
=end
    def self.write( basepath, data ) 
      tmpfile = nil
      begin
        tmpfile = Tempfile.new( nil, basepath.to_s )
        tmpfile.write data
        tmpfile.close

        # Hack: stop Tempfile from deleting the file upon finalization
        #       Too implizit in the long run, but ok for the first versions
        ObjectSpace.undefine_finalizer( tmpfile ) 
      rescue
        tmpfile.unlink
        raise $!
      else
        tmpfile.path
      end
    end
  end
end
