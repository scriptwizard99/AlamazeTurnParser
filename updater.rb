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
require 'logger'

#----------------------------------- CONSTANTS --------------------------
ARCHIVE_DIR="archive"
CONFIG_URL="http://fallofromegame.com/alamazeorders/downloads/bananaConfig.txt"
CONFIG_FILE="bananaConfig.txt"
UPDATER_BINARY=ENV['OCRA_EXECUTABLE'] 
DOC_FILE="TurnParserInstructions.doc"
#------------------------------------------------------------------------

#-----------------------------------  GLOBALS  --------------------------
$LOG=nil
$configInfo=nil
#------------------------------------------------------------------------

def echoLog(msg)
   printf("%s\n", msg)
   $LOG.info(msg)
end

# Must open output file for writing in BINARY mode
def downloadFile(url,sizeStr,outputFile)

   size = sizeStr.to_i
   uri = URI(url)
   echoLog("Downloading %s into %s"% [uri, outputFile])
   numBytes=0
   Net::HTTP.start(uri.host, uri.port) do |http|

     request = Net::HTTP::Get.new uri.request_uri
     http.request request do |response|
     
       # Check reponse to see if there is anything to download
       if  response.is_a?(Net::HTTPSuccess)
          $LOG.info("Good response")
       else
          $LOG.error("Download failed! response(%s)"%response.message)
          printf("Download failed! Response from server: %s\n", response.message)
          return false
       end

       # Download body of response into file
       open outputFile, 'wb' do |io|
         response.read_body do |chunk|
           io.write chunk
           numBytes += chunk.size
           percent =  100 * numBytes / size
           printf("Percent Complete : %6.2f\r", percent)
         end # do chunk
       end # do io
     end # do response
   end # do http

   $LOG.info("Download complete. Size=%d bytes"% numBytes)
   printf("Percent Complete : %6.2f\r", 100.00)
   printf("\ndone.\nSize=%d bytes\n",numBytes)
   return true
end

def setupArchive
   echoLog("Running in %s" % Dir.pwd)
   if Dir.exist?(ARCHIVE_DIR)
     $LOG.info("Archive dir(%s) already exists"%ARCHIVE_DIR)
   else
     $LOG.info("Creating archive dir(%s)"%ARCHIVE_DIR)
     Dir.mkdir(ARCHIVE_DIR)
   end
end

def fetchConfig
   # TODO Ask user if they want to check for updates. Skip if not.
   echoLog("Fetching configuration")
   cfgSize="500" # roughly
   success = downloadFile(CONFIG_URL, cfgSize, CONFIG_FILE)
   success = readConfig if success
   return success
end

def readConfig
   $configInfo=Hash.new
   File.new(CONFIG_FILE).each_line do |line|
      line.chomp!
      $LOG.info("CFG : %s" % line)
      (key,val)=line.split('=')
      $configInfo[key]=val
   end
   
   return true
end

def getMD5Sum(targetFile)
   return 0 if not File.exist?(targetFile)
   data1=IO.binread(targetFile)
   md5 = Digest::MD5.hexdigest(data1)
   $LOG.info("file(%s) md5sum(%s)"% [targetFile,md5])
   return md5
end

def checkMD5Sum(targetFile,targetSum)
   actualSum=getMD5Sum(targetFile)
   $LOG.info("Checking MD5 for file(%s) target(%s) actualSum(%s)" % [targetFile,targetSum,actualSum])
   return actualSum == targetSum
end

# Returns false is need to update updater
def checkUpdater
   if UPDATER_BINARY == nil
      echoLog("Running as script, not ocra binary. Skipping updater check.")
      return true
   end
   echoLog("Checking for updates to the updater itself")
   matches = checkMD5Sum(UPDATER_BINARY, $configInfo['updaterMD5'] )
   if matches
      echoLog("Updator binary is OK. We can continue.")
      return true
   else
      echoLog("Please delete and re-download updater.")
      return false
   end
end

def downloadDoc
   url=$configInfo['documentURL'];
   size=$configInfo['documentSize'];
   version=$configInfo['documentVersion'];
   success = downloadFile(url,size,DOC_FILE)
   if success 
      matches = checkMD5Sum( DOC_FILE, $configInfo['documentMD5'] )
      if matches
         echoLog("New doc file version(%s) download successful" % version)
      else
         echoLog("Downloaded doc file is corrupt")
      end
   else
      echoLog("Failure downloading new doc file")
   end
end

def checkDoc
   matches = checkMD5Sum( DOC_FILE, $configInfo['documentMD5'] )
   if matches
      echoLog("Doc file OK")
   else
      echoLog("Need to download new doc file")
      downloadDoc
   end
end

#<<<<<<<<<<<<<<<<<<<<<<<<<<<< START >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

$LOG=Logger.new('updaterLog.out')
$LOG.info("====================== S T A R T ======================")

#if not defined?(Ocra)

   begin

      setupArchive
      doUpdate = fetchConfig
      if doUpdate
         continue = checkUpdater 
         if continue
            checkDoc
         end
      else
         echoLog("Proceeding without checking for updates")
      end

   rescue Exception => e
      printf("CAUGHT EXCEPTION! CHECK LOG FOR DETAILS")
      $LOG.error("Caught exception")
      $LOG.error(e)
   end

#else
#   puts "Detected that ocra is building script. Skipping main part"
#end

sleep 10
$LOG.info("====================== E N D ======================")
exit 0
