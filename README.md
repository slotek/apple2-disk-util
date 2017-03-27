# apple2-disk-util
A command-line utility to CATALOG Apple 2 DOS 3.3 disk images and COPY files between them.

Installation
------------
Add the "lib" directory to your RUBYLIB environment variable,
and the "bin" directory to your PATH.

You will need both Ruby and the GLI gem installed to use this utility.

Sample Usage
------------
Here are a few sample commands:

    a2 catalog games1.dsk
    a2 ls -R
    a2 copy SABOTAGE src.dsk dest.dsk

See "a2 --help" for more info.

TODO
----
Integration test rake task.
Gem specification & installation info.
