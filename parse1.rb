#!/cygdrive/c/Ruby193/bin/ruby
=begin
    Alamaze Turn Parser - Extracts portions of Alamaze PDF turn results
    and outputs the data in CSV format.

    Copyright (C) 2014  Joseph V. Gibbs III

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    You can contact the author at scriptwizard99@gmail.com
=end

require_relative 'alamazeTurnParser'

filename = ARGV[0]
if filename.nil?
   puts
   puts "Usage: ruby parser1.rb <pdfFileName>"
   puts
   exit 1
end

VERSION="1.0.0"


puts "Alamaze PDF Turn Parser Version #{VERSION}\n"
receiver = AlamazeTurnParser.new
puts "Parsing #{filename}"
puts
pdf = PDF::Reader.file(filename,receiver)

# TODO Instead we should probably be appending
# this info to a data file.
# (or better, pushing to a database)
receiver.showInfoRecord()
puts
receiver.showPopInfo()
puts
receiver.showEmissaryInfo()
puts
receiver.showArmies()
puts
receiver.showArtifactInfo()
puts
receiver.showRegionalInfo()
