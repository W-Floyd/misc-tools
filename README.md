# misc-tools
## A general catchall of scripts/tools I make.

I suggest a git clone and symlink, but I will leave that up to you.

***

### fsize

#### File size tool

Quite simply prints the file size of all given files, optionally in bytes, when option '-b' is passed.

### livewrite

#### Live USB writing tool

Steps the user through selecting a file to write and a storage device to write it to, then completes the operation using dd, with a pv readout if available.

### mactool

#### A mac address tool (alternative to macchanger)

Allows the user to easily:
* print or set a random (valid) mac address
* print or revert to the hardware default mac address
* print the current mac address
* attempt to set the mac address as given by the user
* list valid interfaces to work on

### roman

#### A Roman Numeral to Base 10 converter

Converts a Roman Numeral into base 10. Optional verbose output that provides the equation produced.
