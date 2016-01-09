@echo off
rem ==========================================================================
rem = This batch file calls ocra to generate a runable binary for the
rem = Alamaze Turn Parser GUI which is written in Ruby/Tk. Because ocra
rem = packages an entire ruby installation, the user does not need to have
rem = Ruby installed on their machine. The binary is fully self contained.
rem =
rem = For debug, append --verbose --debug --debug-extract to the end of the command
rem ==========================================================================

echo "Creating GUI executable."
ocra --no-autoload --add-all-core amap.rbw *.rb lib\* data\* graphics\* docs\*.txt *.txt c:\ruby193\lib\tcltk

