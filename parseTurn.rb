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

require_relative 'lib/version'
require_relative 'lib/alamazeTurnParser'

filename = ARGV[0]
if filename.nil?
   puts
   puts "Usage: ruby parseTurn.rb <pdfFileName|htmlFilename>"
   puts
   exit 1
end

#VERSION="1.2.0"

myself=$0.gsub('\\','/')
unless ENV['OCRA_EXECUTABLE'].nil?
   myself=ENV['OCRA_EXECUTABLE']
end
owd=File.dirname(myself)
logDir=owd
logFile="#{logDir}/parsePDF.log"
logOut= File.open(logFile,"a+")

begin
   filename = "#{owd}/#{filename}"
   logOut.puts "=====================================================\n"
   logOut.puts "Alamaze Turn Parser Version #{VERSION}\n"
   logOut.puts "Parser started in #{logDir} directory"

   logOut.puts "Parsing #{filename}"
   parser = AlamazeTurnParser.new
   if filename.upcase.include? "PDF"
      parser.setFormat(AlamazeTurnParser::FORMAT_PDF)
      pdf = PDF::Reader.file(filename,parser)
   else
      parser.setFormat(AlamazeTurnParser::FORMAT_HTML)
      IO.foreach(filename) do |line|
         parser.show_html(line)
      end
   end
   
   parser.showInfoRecord()
   puts
   parser.showPopInfo()
   puts
   parser.showEmissaryInfo()
   puts
   parser.showArmies()
   puts
   parser.showArtifactInfo()
   puts
   parser.showRegionalInfo()
   puts
   parser.showOwnedPopCenters()
   puts
   parser.showHCInfo()

   logOut.puts "Parsing complete."

rescue Exception => e
   logOut.puts "Caught exception trying to process file."
   logOut.puts e.inspect
   logOut.puts "\nBacktrace:\n"
   logOut.puts e.backtrace

   puts "Encountered error processing #{filename}\n"
   puts "See #{logFile} for details.\n"
end

logOut.close
