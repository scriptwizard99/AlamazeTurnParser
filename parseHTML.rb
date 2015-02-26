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
   puts "Usage: ruby parserHTML.rb <htmlFileName>"
   puts
   exit 1
end

VERSION="0.1.0"


puts "Alamaze HTML Turn Parser Version #{VERSION}\n"
parser = AlamazeTurnParser.new
puts "Parsing #{filename}"
puts

IO.foreach(filename) do |line|
   parser.show_html(line)
end

# TODO Instead we should probably be appending
# this info to a data file.
# (or better, pushing to a database)
parser.showInfoRecord()
puts
parser.showPopInfo()
#puts
#parser.showEmissaryInfo()
#puts
#parser.showArmies()
#puts
#parser.showArtifactInfo()
#puts
#parser.showRegionalInfo()
