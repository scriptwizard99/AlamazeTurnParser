#!/bin/sh

if [[ $# -lt 1 ]]
then
   echo "Usage: $0 <releaseVersion>"
   exit 1
fi

version=$1

distDir='dist'
zipDestDir=$distDir/turnParser

echo "First cleaning out dist dir"
rm -rf $distDir
mkdir -p $zipDestDir


echo "Building dist files for version $version"

mv parseTurn.exe $distDir/parserCommand-${version}.exe
mv amap.exe      $distDir/parserGUI-${version}.exe

cp *.rb *.rbw $zipDestDir
cp -r graphics $zipDestDir
cp -r docs $zipDestDir
cp -r data $zipDestDir
cp -r lib $zipDestDir



exit 0
