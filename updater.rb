#!/cygdrive/c/Ruby193/bin/ruby
=begin
    Alamaze Turn Parser - Auto Updator Module
    Takes care of downloading the latest versions of stuff

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

require 'net/http'
require 'digest'

# Must open output file for writing in BINARY mode
def downloadFile(uri,size,outputFile)

   printf("Downloading %s into %s\n", uri, outputFile)
   numBytes=0
   Net::HTTP.start(uri.host, uri.port) do |http|
     request = Net::HTTP::Get.new uri.request_uri
   
     http.request request do |response|
       if  response.is_a?(Net::HTTPSuccess)
          printf("Good response\n")
       else
          printf("Bad response: %s\n", response.message)
          return
       end
       open outputFile, 'wb' do |io|
         response.read_body do |chunk|
           io.write chunk
           numBytes += chunk.size
           percent =  100 * numBytes / size
           printf("Percent Complete : %6.2f\r", percent)
         end
       end
     end
   end
   printf("Percent Complete : %6.2f\r", 100.00)
   printf("\ndone.\nSize=%d bytes\n",numBytes)
end

#<<<<<<<<<<<<<<<<<<<<<<<<<<<< START >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

#uri = URI('http://fallofromegame.com/alamazeorders/downloads/TurnParserInstructions.doc')
#uri = URI('http://fallofromegame.com/alamazeorders/downloads/parserGUI.exe')
uri = URI('http://fallofromegame.com/alamazeorders/downloads/bananaConfig.txt')

#size=2153472
size=7911904
outputFile='download.out'

downloadFile(uri,size, outputFile)

# Must open input file for reading in BINARY mode
data1=IO.binread(outputFile)
md5 = Digest::MD5.hexdigest(data1)
printf("md5sum=%s\n", md5)

