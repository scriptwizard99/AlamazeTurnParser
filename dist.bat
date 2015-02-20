rem ==========================================================================
rem = This batch file calls ocra to generate a runable binary for the
rem = Alamaze Turn Parser GUI which is written in Ruby/Tk. Because ocra
rem = packages an entire ruby installation, the user does no need to have
rem = Ruby installed on their machine. The binary is fully self contained.
rem =
rem = For debug, append --verbose --debug --debug-extract to the end of the command
rem ==========================================================================
ocra --chdir-first --no-dep-run --add-all-core --windows amap.rbw *.rb graphics\* \ruby193\lib\tcltk\**\* \Ruby193\bin\tk85.dll 

