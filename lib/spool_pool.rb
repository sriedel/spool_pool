=begin rdoc
= Introduction
This is a simple implementation of a file spooler. You can think of it as
a filesystem based queueing service without a service running behind it. 
Like the spools used in unix for mail servers, print jobs etc.

In this module, a Pool instance can contain several different Spool instances,
each of which can store files. Data is retrieved from the spool in a 
non-strict order, oldest first. 

Data is serialized and deserialized on storage/retrieval (currently using
YAML).

Most users will want to start using this library by instantiating a Pool 
object, pointing it to a directory that will act as the parent directory
for all subsequent Spools.

= Usage Example
# instatiate a pool, pointing to a directory with read/write permissions 
# for the effective user of the current process

require 'spool_pool'
pool = SpoolPool::Pool.new( "/path/to/my/spool/root" )

# store data in one spool
pool.put :my_spool, "some data here"


# retrieve the data

pool.get :my_spool 
# -> "some data here"

# store data in another spool, demonstrating the ordered retrieval

pool.put :my_other_spool, :foo
sleep 1
spool.put :my_other_spool, :bar

spool.get :my_other_spool 
# -> :foo
spool.get :my_other_spool 
# -> :bar

=end
module SpoolPool
end

$: << File.expand_path( File.dirname( __FILE__ ) )
require 'spool_pool/pool'
require 'spool_pool/spool'
require 'spool_pool/file'

