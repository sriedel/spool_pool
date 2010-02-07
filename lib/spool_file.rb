require 'tempfile'

class SpoolFile
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
