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

#filename = "WI136R23.pdf"
#filename = "WI136R0.pdf"
#filename = "GI124R0.pdf"
#filename = "GI124R31.pdf"

if ARGV.size == 0
   puts
   puts "Usage: ruby findArtifacts.rb <pdfFileName>.."
   puts
   exit 1
end

VERSION="0.0.2"

class UnusualSightingList
   def initialize
      @list=Hash.new
      @failures=Hash.new
      @visited=Hash.new
   end
   def addVisited(game,loc)
      if @visited[game]==nil
         @visited[game]=Array.new
      end
      @visited[game].push loc
   end
   def addUS(game,loc,name)
      if name == "FAIL"
         if @failures[game]==nil
            @failures[game]=Array.new
         end
         @failures[game].push loc
         return
      end
      if @list[name] == nil
         @list[name] = UnusualSighting.new(name)
      end
      @list[name].add(game,loc)
   end

   def showAll
      print "\nSIGHTED:\n"
      @visited.keys.sort.each do |game|
         visitedLocs = @visited[game].sort.uniq.join(', ')
         printf("\tGame %3s : %s\n", game, visitedLocs)
      end
      print "\nFAILURES:\n"
      @failures.keys.sort.each do |game|
         failedAttempts = @failures[game].sort.uniq.join(', ')
         printf("\tGame %3s : %s\n", game, failedAttempts)
      end
      print "\nARTIFACTS:\n"
      @list.keys.sort.each do |artName|
         print @list[artName].toString
      end
   end

end # class UnusualSightingList

class UnusualSighting
   def initialize(name)
      @name = name
      @list=Hash.new
   end
   def add(game,loc)
      @list[game]=loc
   end
   def toString
      info=Array.new
      @list.keys.sort.each do |game|
         info.push "#{game}-#{@list[game]}"
      end
      line=printf("\t%-50s : %s\n", @name, info.join(', '))
      return line
   end
end # class UnusualSighting

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
  SECTION_UNUSUAL_SIGHTING=20
  SECTION_MILITARY_ENGAGEMENTS=21

  def initialize
     @section=0
     @gameNumber=0
     @artifactInfo=Array.new
     @tempArtifactInfo=nil
  end


  # Determine what section of the turn results we are in
  # based on key phrases.
  # This section is set in an instance variable so that
  # it can later be used when we want to process a given
  # line of text from the turn results.
  def checkSection(string)
     if( string.include? "Production collected this month" )
        @section = SECTION_DONT_CARE
     elsif ( string.include? "ACCT #:" )
        @section = SECTION_PREAMBLE
     elsif ( string.include? "Our forecast for next month" )
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Military Naval status")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Our groups are outside of the following population centers")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Our groups are opposite the following groups")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Report of unusual sighting by the ")
        #puts string
        @section = SECTION_UNUSUAL_SIGHTING
     elsif ( string.include? "Our population centers reported the presence of the following groups")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Reports from the countryside produce Regional Intelligence")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Economic related events in the kingdom")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "We issued the following commands")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Production and Consumption Ledger")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "We received the following messages")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Matters Covert, Esoteric and General")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "We possess the following artifacts")
        @section = SECTION_ARTIFACTS
     elsif ( string.include? "*** GROUPS: ***")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "*** POPULATION CENTERS: ***")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "*** EMISSARIES: ***")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "*** ARTIFACTS: ***")
        @section = SECTION_RECON_ARTIFACTS
     elsif ( string.include? "IN MEMORIUM")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Political Events and Status of the Realm")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Activities of the Royal Court")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Activities of the High Council")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Reports of our Military engagements")
        @section = SECTION_MILITARY_ENGAGEMENTS
     elsif ( string.include? "RECONNAISANCE OF UNUSUAL")
        collectMilitaryEngagements(string)
        @section = SECTION_MILITARY_ENGAGEMENTS
     elsif ( string.include? "ATTACK BY THE ")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "ASSAULT BY THE ")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "BATTLE BETWEEN THE ")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Results of our Military maneuvers")
        @section = SECTION_MILITARY_MANEUVERS
     elsif ( string.include? "Military Group Status")
        @section = SECTION_DONT_CARE
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
     when SECTION_ARTIFACTS
        collectArtifactStatus(string)
     when SECTION_RECON_ARTIFACTS
        collectArtifactRecon(string)
     when SECTION_UNUSUAL_SIGHTING
        collectUnusualSighting(string)
     when SECTION_MILITARY_ENGAGEMENTS
        collectMilitaryEngagements(string)
     when SECTION_MILITARY_MANEUVERS
        collectMilitaryManeuvers(string)
     when SECTION_DONT_CARE
        # do nothing
     else
        #printf("ERROR: Unknown section = %d\n", @section)
     end
  end

  def processPreamble(line)
     if line.include? "GAME #"
        (x,x,@gameNumber)=line.split
     end
  end


  def parseEncounter(line)
     #puts line
     area = "??"
     artifact = "??"
     if md=line.match(/RECONNAISANCE OF UNUSUAL SIGHTING IN AREA (\S\S) /)
        area = md[1]
     end
     artifact = "FAIL" if md=line.match(/(REPORTING HEAVY-HEARTED)/)
     artifact = "FAIL" if md=line.match(/(THE PATROL MADE A HASTY RETREAT)/)
     artifact = "FAIL" if md=line.match(/(REPELLED BY THE BOLDNESS OF THE PATROL)/)
     artifact = "FAIL" if md=line.match(/(REPELLED BY THE INCOMPATABILITY)/)
     artifact = "FAIL" if md=line.match(/(STARTLED BY THE BOLDNESS OF THE PATROL)/)
     artifact = "FAIL" if md=line.match(/(ANNOYED AT THE TIMIDNESS OF THE PATROL)/)

     artifact = md[1] if md=line.match(/ (ARTIFACT.*)/)
     artifact = md[1] if md=line.match(/ (WIZARDLY ARTIFACT.*)/)

     artifact = md[1] if md=line.match(/ (CRYSTAL OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (GEM OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (FIRE OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (WAND OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (ROD OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (STAFF OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (MAGICAL STAFF OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (SWORD OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (SPEAR OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (GOLDEN SPEAR OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (HAMMER OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (AXE OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (GREAT AXE OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (PLOW OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (THE PLOW OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (ARMOR OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (SHIELD OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (STANDARD OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (ORB OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (STONE OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (ALTER OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (HORN OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (HERD OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (LAST HERD OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (CROWN OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (RING OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (MAGICAL RING .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (BATS OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (GREAT RED BATS OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (TELEPORT\w* PORTAL)/)
     artifact = md[1] if md=line.match(/ (Portal)/)
     artifact = md[1] if md=line.match(/ (Pegasus)/)
     artifact = md[1] if md=line.match(/ (A POWER-2 WIZARD)/)
     artifact = md[1] if md=line.match(/ (PALANTIR .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (\w+ SLAYER.*)[.,!]/)
     artifact = md[1] if md=line.match(/ (\w+ BANE.*)[.,!]/)
     artifact = md[1] if md=line.match(/ (\w+ ELIMINATOR.*)[.,!]/)
     artifact = md[1] if md=line.match(/ (\w+ ANNIHILATOR.*)[.,!]/)
     #artifact = md[1] if md=line.match(/ (THE SHORT NAME OF .*)[.,!]/)
     artifact = md[1] if md=line.match(/ (KEY OF .*)[.,!]/)

     # cases where patrol does not have proper key
     artifact = "ELAN" if md=line.match(/THE \"KEY OF THE SLAYER\"/)
     artifact = "RING OF POWER" if md=line.match(/THE \"KEY OF THE MAKER\"/)
     artifact = "STAFF OF THE ORATOR" if md=line.match(/THE \"KEY OF THE STAFF\"/)
     artifact = "GEM OF THE PLANES" if md=line.match(/THE \"KEY OF THE GEM\"/)
     artifact = "STAFF OF THE ORATOR" if md=line.match(/THE \"STAFF OF THE ORATOR\"/)


     artifact = "Wandering Wizard?" if md=line.match(/POOL OF ORANGE WATER/)

     # corrections
     #artifact = "STAFF OF THE ORATOR" if artifact.include? "ORATOR"
     
     artifact=artifact.split('.')[0]
     artifact=artifact.split(',')[0]
     artifact=artifact.split('!')[0]
     print "Game=#{@gameNumber} Area=#{area} Artifact=#{artifact}\n"
     $usList.addUS(@gameNumber,area,artifact)
  end

  def collectMilitaryManeuvers(line)
     if @tempReconUS != nil
        parseEncounter(@tempReconUS)
        @tempReconUS = nil
     end
  end
  def collectMilitaryEngagements(line)
     if line.include? "RECONNAISANCE OF UNUSUAL SIGHTING IN AREA"
        if @tempReconUS != nil
           parseEncounter(@tempReconUS)
           @tempReconUS = line.strip
        end
     end
     @tempReconUS="#{@tempReconUS} #{line.strip}"
     #p line if line.include? "RECONNAISANCE OF UNUSUAL SIGHTING IN AREA"
     #p line if line.include? "DISCOV" or line.include? "INSPECT" or line.include? "ARTIFACT"
     #p line if line.include? "RING OF" or line.include? "CRYSTAL OF" or line.include? "ROD OF" or line.include? "GEM OF"
     #p line if line.include? "SWORD OF" or line.include? "STAFF OF" or line.include? "WAND OF" or line.include? "CROWN OF"
     #p line if line.include? "ALTER OF" or line.include? "HORN OF" or line.include? "STONE OF" or line.include? "SPEAR OF"
     #p line if line.include? "AXE OF" or line.include? "KEY OF" 
     #p line if line.include? "PALANTIR" or line.include? "WINGED" or line.include? "BATS" 
     #p line if line.include? "Pegasus" or line.include? "SLAYER" or line.include? "WANDERING" 
     #p line if line.include? "Portal" or line.include? "PORTAL" 
     #p line if line.include? "ELIMINATOR" or line.include? "ANNIHILATOR" or line.include? "AUTOMATICALLY"
  end


  def collectUnusualSighting(line)
     #return if line != nil
     #puts line
     if md=line.match(/\s+suspected might be at (\w\w)/)
        #print("Area #{md[1]}, ")
        $usList.addVisited(@gameNumber,md[1])
     end
     if md=line.match(/\s+area (\w\w)/)
        #print("Area #{md[1]}, ")
        $usList.addVisited(@gameNumber,md[1])
     end
  end
#          1         2         3         4         5         6         7         8         9         0
#01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
#                                            SHORT                                     STATUS
#          FULL NAME                         NAME    POSSESSOR             TYPE         PTS
#          PALANTIR AMBALAR                  92238  1st WITCHLORD          COVERT        300
#          KEY OF THE SLAYER                 68659  INARA                  KING          100
#          GOLDEN SPEAR OF LERIX             50571  1st WITCHLORD          WEAPON        300
#          RING OF POWER                     51979  2nd WITCHLORD          WIZARD        600
#          RING OF INVISIBILITY              74040  INARA                  COVERT        400
#          RING OF PROTECTION                18110  MAL REYNALDS           BENEVOLENT    200
#          RING OF PROTECTION                59902  WHISPER IN THE DARK    BENEVOLENT    200
#          KEY OF THE GEM                    36367  RIVER TAM              KING          100
  def collectArtifactStatus(line)
     return if line.include? "STATUS"
     return if line.include? "POSSESSOR"
     return if line.include? "Spies"
     #puts "[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]"
     #printf("[%s]\n",line)
     artifact=Hash.new
     artifact[:source]="Self"
     artifact[:area]=nil
     artifact[:fullName]=line[10..42].strip
     artifact[:shortName]=line[44..50].strip
     artifact[:posessor]=line[51..73].strip
     artifact[:type]=line[74..86].strip
     artifact[:statusPts]=line[87..96].strip
     @artifactInfo=Array.new if @artifactInfo == nil
     @artifactInfo.push artifact
  end

#          1         2         3         4         5         6         7         8         9         0
#01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
#          AREA    POSSESSOR                            FULL NAME                      SHORT NAME
#           CD   WITCHLORD PRINCE MAL REYNALDS
#                                                     RING OF PROTECTION                   18110
  def collectArtifactRecon(line)
     return if line.include? "POSSESSOR"
     return if line.include? "MEMORIUM"
     return if line.include? "RESULT:"
     return if line.include? "nothing to report"
     return if line.include? "Raven Familiar"
     #puts "[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]"
     #printf("[%s]\n",line)
     #return if line.strip.size < 60

     # Darn line might be broken in two
     (area,x)=line.split
     if area.size > 2 and @tempArtifactInfo != nil  # not the first line 
        @tempArtifactInfo[:fullName] = line[51..83].strip
        @tempArtifactInfo[:shortName] = line[83..100].strip
        @artifactInfo=Array.new if @artifactInfo == nil
        @artifactInfo.push @tempArtifactInfo
        @tempArtifactInfo = nil
     else
        @tempArtifactInfo=Hash.new
        @tempArtifactInfo[:source] = "Recon"
        @tempArtifactInfo[:area] = area
        @tempArtifactInfo[:posessor] = line[14..50].strip
        if line.size > 60
           @tempArtifactInfo[:fullName] = line[51..83].strip
           @tempArtifactInfo[:shortName] = line[83..100].strip if line.size > 83
           @artifactInfo=Array.new if @artifactInfo == nil
           @artifactInfo.push @tempArtifactInfo
           @tempArtifactInfo = nil
        end
     end
  end

  # forecast values will overwrite current ones.
  def collectProduction(line)
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
  

  def showArtifactInfo()
     return false if  @artifactInfo == nil
     #printf("Record Type,Data Source,Area,Full Name,Short Name,Posessor,Artifact Type,Status Points\n")
     @artifactInfo.each {|artifact|
        record=["A",artifact[:source],artifact[:area],artifact[:fullName],artifact[:shortName],
                    artifact[:posessor],artifact[:type],artifact[:statusPts]].join(',')
        puts record
     }
     return true
  end
  
end

puts "Alamaze Artifact Hunter Version #{VERSION}\n"
$usList = UnusualSightingList.new
numFiles=0
startTime = Time.new
ARGV.each do |filename|
   numFiles += 1
   receiver = AlamazeTurnParser.new
   print "Parsing #{filename} :      \n"
   pdf = PDF::Reader.file(filename,receiver)
   #puts
   #puts if receiver.showArtifactInfo() == true
end
stopTime = Time.new

duration = stopTime - startTime
print "------------------------------------------------------------------------------\n\n"
printf("Processed %d files in %.6f seconds\n", numFiles, duration.to_f)

$usList.showAll()
