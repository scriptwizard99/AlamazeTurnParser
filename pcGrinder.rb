#!/usr/bin/ruby
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

require 'rubygems'
require 'pdf/reader'

if ARGV.size == 0
   puts
   puts "Usage: ruby pcGrinder.rb <pdfFileName>.."
   puts
   exit 1
end

VERSION="0.0.1"

class AlamazeTurnParser

  # define the sections of the turn results
  SECTION_DONT_CARE=0
  SECTION_PREAMBLE=1
  SECTION_CUR_PRODUCTION=2
  SECTION_FORECAST_PRODUCTION=3
  SECTION_ARTIFACTS=4
  SECTION_RECON_GROUPS=5
  SECTION_RECON_POP=6
  SECTION_RECON_EMISSARIES=7
  SECTION_RECON_ARTIFACTS=8
  SECTION_DEAD_ROYALS=9
  SECTION_EMISSARY_LOCATIONS=10
  SECTION_MILITARY_STATUS=11
  SECTION_COV_ES_GEN=12
  SECTION_GROUP_FIND_PC=13
  SECTION_GROUP_FIND_GROUP=14
  SECTION_PC_FIND_GROUP=15
  SECTION_REGION_FIND_GROUP=16
  SECTION_REGIONAL_SUMMARY=17
  SECTION_POLITICAL_EVENTS=18
  SECTION_MILITARY_MANEUVERS=19

  @section=0
  @banner="xxxxxxx"
  @influence=0
  @gameNumber=0

  # EVERY kingdom except the Red Dragon is abbreviated
  # by the first two letters of their name. But the 
  # Red Dragon is 'RD' instead of 'RE'
  # I do not understand why
  def fixBanner(banner)
     if banner == "RE"
        return "RD"
     else
        return banner
     end
  end

  # Determine what section of the turn results we are in
  # based on key phrases.
  # This section is set in an instance variable so that
  # it can later be used when we want to process a given
  # line of text from the turn results.
  def checkSection(string)
     if( string.include? "Production collected this month" )
        @section = SECTION_CUR_PRODUCTION
     elsif ( string.include? "ACCT #:" )
        @section = SECTION_PREAMBLE
     elsif ( string.include? "Our forecast for next month" )
        @section = SECTION_FORECAST_PRODUCTION
     elsif ( string.include? "Military Naval status")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Our groups are outside of the following population centers")
        @section = SECTION_GROUP_FIND_PC
     elsif ( string.include? "Our groups are opposite the following groups")
        @section = SECTION_GROUP_FIND_GROUP
     elsif ( string.include? "Report of unusual sighting by the ")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Our population centers reported the presence of the following groups")
        @section = SECTION_PC_FIND_GROUP
     elsif ( string.include? "Reports from the countryside produce Regional Intelligence")
        @section = SECTION_REGION_FIND_GROUP
     elsif ( string.include? "Economic related events in the kingdom")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "has current influence ")
        stuff=string.split
        @influence=stuff.last.strip  # This is all we want from thsi section
        @section = SECTION_DONT_CARE
     elsif ( string.include? "We issued the following commands")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Production and Consumption Ledger")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "We received the following messages")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Matters Covert, Esoteric and General")
        @section = SECTION_COV_ES_GEN
     elsif ( string.include? "We possess the following artifacts")
        @section = SECTION_ARTIFACTS
     elsif ( string.include? "*** GROUPS: ***")
        @section = SECTION_RECON_GROUPS
     elsif ( string.include? "*** POPULATION CENTERS: ***")
        @section = SECTION_RECON_POP
     elsif ( string.include? "*** EMISSARIES: ***")
        @section = SECTION_RECON_EMISSARIES
     elsif ( string.include? "*** ARTIFACTS: ***")
        @section = SECTION_RECON_ARTIFACTS
     elsif ( string.include? "IN MEMORIUM")
        @section = SECTION_DEAD_ROYALS
     elsif ( string.include? "Political Events and Status of the Realm")
        @section = SECTION_POLITICAL_EVENTS
     elsif ( string.include? "Activities of the Royal Court")
        @section = SECTION_EMISSARY_LOCATIONS
     elsif ( string.include? "Activities of the High Council")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Results of our Military maneuvers")
        @section = SECTION_MILITARY_MANEUVERS
     elsif ( string.include? "Military Group Status")
        @section = SECTION_MILITARY_STATUS
     elsif ( string.include? "Regional Summary")
        # This line breaks the rules. I want the info from the header line.
        # Go ahead and parse out @banner
        (banner,x,x)=string.split
        @banner=fixBanner(banner[0,2])
        @section = SECTION_REGIONAL_SUMMARY
     else
        return false
     end
     return true
  end

  # Process a line of text from the turn results
  # based on what section it is from
  def processLine(string)
     case @section
     when SECTION_PREAMBLE
        processPreamble(string)
     when SECTION_CUR_PRODUCTION
#       collectProduction(string)
     when SECTION_FORECAST_PRODUCTION
        collectProduction(string)
     when SECTION_RECON_POP
#       collectProductionRecon(string)
     when SECTION_EMISSARY_LOCATIONS
#       collectEmissaryLocations(string)
     when SECTION_MILITARY_MANEUVERS
#       collectMilitaryManeuvers(string)
     when SECTION_COV_ES_GEN
#       collectMattersCovertEsotericAndGeneral(string)
     when SECTION_GROUP_FIND_PC
#       collectGroupFindPC(string)
     when SECTION_POLITICAL_EVENTS
#       collectPoliticalEvents(string)
     when SECTION_DONT_CARE
        # do nothing
     else
        #printf("ERROR: Unknown section = %d\n", @section)
     end
  end

  # All we need from the first part of the turn results
  # is the turn number
  def processPreamble(line)
     if line.include? "TURN #"
        (x,x,$turnNumber)=line.split
     end
     if line.include? "GAME #"
        (x,x,@gameNumber)=line.split
     end
  end

#[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]
#[     NIMBUS SIGN               (AREA MN), A HIGH RANKING EMISSARY OF THE WARLOCK KINGDOM HAS RELOCATED HERE.                                ]
  def collectPoliticalEvents(line)
     if md=line.match(/IN AREA (\w\w) HAVE REBELLED/)
        area=md[1]
        $popCenterInfo=Hash.new if $popCenterInfo == nil
        $popCenterInfo[area]=Hash.new if $popCenterInfo[area] == nil
        #$popCenterInfo[area]['region']=""
        $popCenterInfo[area]['banner']=nil
        $popCenterInfo[area]['source']="Rebelled"
        @politicalTempArea = area
     end
  end

#           1         2         3         4         5         6         7         8         9         0
#[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]
#[          AMBERLAND        NK   WARLOCK         CITY     AVALON                19872]
  def collectGroupFindPC(line)
     return if line.include? "REGION"
     #puts "[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]"
     #printf("[%s]\n",line)
     area = line[27..28]

     $popCenterInfo=Hash.new if $popCenterInfo == nil
     $popCenterInfo[area]=Hash.new if $popCenterInfo[area] == nil
     #$popCenterInfo[area]['region']=""
     $popCenterInfo[area]['banner']=fixBanner(line[32..33])
     $popCenterInfo[area]['name']=line[57..78].strip
     $popCenterInfo[area]['type']=line[48..56].strip
     $popCenterInfo[area]['defense']=line[77..85].strip
     $popCenterInfo[area]['source']="Encounter"
  end

  def collectMattersCovertEsotericAndGeneral(line)
     if md = line.match(/THERE IS A (\S+) LOCATED IN AREA (\w\w)/)
        area = md[2]
        $popCenterInfo=Hash.new if $popCenterInfo == nil
        $popCenterInfo[area]=Hash.new if $popCenterInfo[area] == nil
        $popCenterInfo[area]['type']=md[1]
        $popCenterInfo[area]['source']="Divined"
     end
     if md = line.match(/THERE IS A (\S+) (\S+) LOCATED IN AREA (\w\w)/)
        #p md
        area = md[3]
        $popCenterInfo=Hash.new if $popCenterInfo == nil
        $popCenterInfo[area]=Hash.new if $popCenterInfo[area] == nil
        $popCenterInfo[area]['banner']=fixBanner(md[1][0..1])
        $popCenterInfo[area]['type']=md[2]
        $popCenterInfo[area]['source']="Divined"
     end
  
  end 


  def collectMilitaryManeuvers(line)
     return if line.include? "NO POPULATION CENTERS"
     return if not line.include? "WE PASSED"
     #printf("[%s]\n",line)
     line.split(',').each do |part|
        if md=part.match(/.* A (.*) AT (\w\w)/)
           area=md[2]
           $popCenterInfo=Hash.new if $popCenterInfo == nil
           $popCenterInfo[area]=Hash.new if $popCenterInfo[area] == nil
           $popCenterInfo[area]['type']=md[1]
           $popCenterInfo[area]['source']="Passed"
        end
     end
  end
  # Process the section of the turn results that lists
  # the current or forecasted production
  # forecast values will overwrite current ones.
  def collectProduction(line)
     return if line.include? "---"
     return if line.include? "==="
     return if line.include? "CENSUS"
     return if line.include? "Our kingdom"
     line.gsub!(',','')
     (region,area)=line.split
     return if area =~ /\d/

     name=line[18..38].strip
     type=line[39..42].strip
     (defense,census,food,gold,other)=line[43..line.size].split

     $popCenterInfo=Hash.new if $popCenterInfo == nil
     $popCenterInfo[area]=Hash.new if $popCenterInfo[area] == nil
     $popCenterInfo[area]['banner']=@banner if  $popCenterInfo[area]['banner'] == nil
     $popCenterInfo[area]['name']=name
     $popCenterInfo[area]['type']=type
     $popCenterInfo[area]['defense']=defense
     $popCenterInfo[area]['census']=census
     $popCenterInfo[area]['food']=food
     $popCenterInfo[area]['gold']=gold
     $popCenterInfo[area]['source']="Self"

     if $popCenterInfo[area]['region'] == nil
       $popCenterInfo[area]['region'] = 1
       $popCenterInfo[area]['other']=@banner
     else
       $popCenterInfo[area]['region'] += 1 
       $popCenterInfo[area]['other'] += " #{@banner}"
     end
  end

  # Process the section of the recon status that covers population centers
  #     1    CD  WITCHLORD  LORETHANE  CITY 23,112  55,200  -4,480  16,800      NA
  # 
  def collectProductionRecon(line)
     return if line.include? "CENSUS"
     line.gsub!(',','')
     (region,area)=line.split
     return if area =~ /\d/
     banner=fixBanner(line[19,2])
     name=line[30..40].strip
     type=line[40..44].strip
     (defense,census,food,gold,other)=line[45..line.size].split

     $popCenterInfo=Hash.new if $popCenterInfo == nil
     $popCenterInfo[area]=Hash.new if $popCenterInfo[area] == nil
     #$popCenterInfo[area]['region']=""
     $popCenterInfo[area]['banner']=banner
     $popCenterInfo[area]['name']=name
     $popCenterInfo[area]['type']=type
     $popCenterInfo[area]['defense']=defense
     $popCenterInfo[area]['census']=census
     $popCenterInfo[area]['food']=food
     $popCenterInfo[area]['gold']=gold
     $popCenterInfo[area]['other']=other
     $popCenterInfo[area]['source']="Recon"
  end


  # 
  #      PRINCE            MAL REYNALDS          THE WITCHLORD CITY AT CD IN OAKENDELL.
  def collectEmissaryLocations(line)
     #puts "[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]"
     #printf("[%s]\n",line)
     return if line.include? "TITLE"
     rank = line[4,16].strip
     return if rank.empty?
     name = line[20,22].strip
     (x,kingdom,x,x3,area,x4)=line[43..line.size].split
     @banner=fixBanner(kingdom[0,2]) if rank == "KING" or rank == "REGENT"
     area = x4 if area == 'AT' and x4.size == 2
     if area.size != 2
        printf("WARNING: problem parsing the following line. Skipping.\n%s\n", line)
        return
     end


     # We can pull some population center information from these lines as well.
     md=line.match(/.* THE (.*) AT (\w\w) IN \w+/)
     pcBanner=fixBanner(md[1][0..1])
     pcType=md[1].split.last
     area=md[2]
     $popCenterInfo=Hash.new if $popCenterInfo == nil
     $popCenterInfo[area]=Hash.new if $popCenterInfo[area] == nil
     $popCenterInfo[area]['banner']=pcBanner
     $popCenterInfo[area]['type']=pcType
     $popCenterInfo[area]['source']="SelfEmLoc"
  end


  # Callback for PDF processing thingy
  # This routine gets passed a plain text string of the turn results.
  # First check to see if we are in a new section of the turn resutls or not.
  # If not, then process the line based on what section we are in.
  def show_text(string, *params)
    newSection=checkSection(string)
    processLine(string) if newSection == false
  end

  # Callback for PDF processing thingy
  # The majority of the results are output via this routine
  # but just call the simple show_text routine since there
  # is really nothing different.
  def move_to_next_line_and_show_text(string, *params)
    #printf("\nMS: %s\n", string)
     show_text(string)
  end

  # Callback for PDF processing thingy
  # This only appears a few times and never has anything we want
  # so make this method do nothing.
  def show_text_with_positioning(array, *params)
    # make use of the show text method we already have
    # assuming we don't care about positioning right now and just want the text
    #show_text("TP: "+array.select{|i| i.is_a?(String)}.join(""), params)
  end

end # class

def showInfoRecord()
      record=[$turnNumber,"I",'PCGrinder','PCGrinder',0].join(',')
      puts record
end

def showPopInfo()
   $popCenterInfo.keys.sort.each {|area|
      p=$popCenterInfo[area]
      record=[$turnNumber,"P",p['source'],area,p['banner'],p['name'],p['region'],p['type'],p['defense'],p['census'],p['food'],p['gold'],p['other']].join(',')
      puts record
   }
end

def showPopInfo2()
   print "Area   Count   Kingdoms Found There\n"
   print "----   -----   ---------------------------------------\n"
   $popCenterInfo.keys.sort.each {|area|
      p=$popCenterInfo[area]
      printf(" %2s    %4s    %s\n",area,p['region'],p['other'])
   }
end


puts "Alamaze Population Center Grinder Version #{VERSION}\n"
numFiles=0
$turnNumber=0
$popCenterInfo=Hash.new
startTime = Time.new
ARGV.each do |filename|
   puts "Processing #{filename}\n"
   numFiles += 1
   receiver = AlamazeTurnParser.new
   pdf = PDF::Reader.file(filename,receiver)
end
stopTime = Time.new
duration = stopTime - startTime
print "------------------------------------------------------------------------------\n\n"
printf("Processed %d files in %.6f seconds\n", numFiles, duration.to_f)

print "\nGUI Readible:\n\n"
showInfoRecord()
showPopInfo()
print "\nHuman Readible:\n\n"
showPopInfo2()
