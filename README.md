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

### mext, odir and oext

#### Basename complements

Take piped and/or option inputs and print one of the following:

* mext - Minus Extension
* odir - Only directory
* oext - Only extension

These are essensially shortcuts for sed functions, they're not
especially smart. Just easier for scripted conversion work.

### vpngate

A script that fetches a list of VPNs from vpngate.net, falling back to a number of mirrors as needed. It then parses the list and adds these configs to the system through nmcli, optionally to a limited number.

As new servers get swapped through the list, they will be added to the existing list.

If eventually there are too many connections, and you want to clean up, it allows uninstalling the connections, ready to start again.
