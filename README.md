# apple2-disk-util
A command-line utility to CATALOG Apple 2 DOS 3.3 disk images and COPY files between them.

Installation
------------
Place an executable copy of the file "a2" into your search path.
You will need both Ruby and the GLI gem installed to use this utility.

Sample Usage
------------
Here are a few sample commands:

    a2 catalog games1.dsk
    a2 ls -R
    a2 copy SABOTAGE src.dsk dest.dsk

See `a2 --help` for more info.
