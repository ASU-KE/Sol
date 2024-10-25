Sol Mamba Stack
===============

Set of scripts and implicit patches for ASU Sol's python implementation. 

We provide our users with a minimal mamba installation. 
It is used by sysadmins to build common scientific computing python
environments (for instance, pytorch and tensorflow for the gpu). 
Researchers are also encouraged to use mamba to manage their own
environments (see our [public documentation][mamba-docs]).

Acknowledgments
---------------

- Martin Cuma and team, CHPC at the University of Utah, for pointing out
  that `LD_LIBRARY_PATH` is not needed in the module file and just leads
  to painful system library conflicts, like openssl and ncurses.


[mamba-docs]: https://links.asu.edu/mamba
