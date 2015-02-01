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
filename = ARGV[0]
if filename.nil?
   puts
   puts "Usage: ruby parser1.rb <pdfFileName>"
   puts
   exit 1
end

VERSION="0.4.0"

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
  @turnNumber=0
  @gameNumber=0
  @popCenterInfo=Hash.new
  @emissaryInfo=Hash.new
  @artifactInfo=Array.new
  @regionInfo=Hash.new
  @tempGroupInfo=nil
  @tempArtifactInfo=nil

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
        collectProduction(string)
     when SECTION_FORECAST_PRODUCTION
        collectProduction(string)
     when SECTION_RECON_GROUPS
        collectMilitaryRecon(string)
     when SECTION_RECON_POP
        collectProductionRecon(string)
     when SECTION_RECON_EMISSARIES
        collectEmissaryRecon(string)
     when SECTION_EMISSARY_LOCATIONS
        collectEmissaryLocations(string)
     when SECTION_MILITARY_MANEUVERS
        collectMilitaryManeuvers(string)
     when SECTION_MILITARY_STATUS
        collectMilitaryStatus(string)
     when SECTION_ARTIFACTS
        collectArtifactStatus(string)
     when SECTION_RECON_ARTIFACTS
        collectArtifactRecon(string)
     when SECTION_COV_ES_GEN
        collectMattersCovertEsotericAndGeneral(string)
     when SECTION_GROUP_FIND_PC
        collectGroupFindPC(string)
     when SECTION_GROUP_FIND_GROUP
        collectGroupFindGroup(string)
     when SECTION_PC_FIND_GROUP
        collectPCFindGroup(string)
     when SECTION_REGION_FIND_GROUP
        collectRegionFindGroup(string)
     when SECTION_REGIONAL_SUMMARY
        collectRegionalSummary(string)
     when SECTION_POLITICAL_EVENTS
        collectPoliticalEvents(string)
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
        (x,x,@turnNumber)=line.split
     end
     if line.include? "GAME #"
        (x,x,@gameNumber)=line.split
     end
  end

#[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]
#[     NIMBUS SIGN               (AREA MN), A HIGH RANKING EMISSARY OF THE WARLOCK KINGDOM HAS RELOCATED HERE.                                ]
  def collectPoliticalEvents(line)
     if line.include? "HAS RELOCATED HERE"
        #puts "[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]"
        #printf("[%s]\n",line)
        md=line.match(/.*\(AREA (\w+).*OF THE (\w+)/)
        #print md
        area=md[1]
        banner=fixBanner(md[2][0..1])
        name="#{@turnNumber}#{area}#{banner}-Unknown"
        #printf("\n\narea=%s banner=%s name=%s\n", area, banner,name)
        @emissaryInfo=Hash.new if @emissaryInfo == nil
        @emissaryInfo[name]=Hash.new if @emissaryInfo[name] == nil
        @emissaryInfo[name]['banner']=banner
        @emissaryInfo[name]['rank']="Unknown"
        @emissaryInfo[name]['area']=area
        @emissaryInfo[name]['source']="Self"
     end
     if md=line.match(/IN AREA (\w\w) HAVE REBELLED/)
        area=md[1]
        @popCenterInfo=Hash.new if @popCenterInfo == nil
        @popCenterInfo[area]=Hash.new if @popCenterInfo[area] == nil
        #@popCenterInfo[area]['region']=""
        @popCenterInfo[area]['banner']=nil
        @popCenterInfo[area]['source']="Rebelled"
        @politicalTempArea = area
     end
     #if md=line.match(/IT IS BELIEVED THE RANGER GOVERNOR NAMED SIR RICHARD PIERCE WAS/)
     if md=line.match(/IT IS BELIEVED THE (\S+) (\S+) NAMED (.+) WAS/)
        name=md[3]
        @emissaryInfo=Hash.new if @emissaryInfo == nil
        @emissaryInfo[name]=Hash.new if @emissaryInfo[name] == nil
        @emissaryInfo[name]['banner']=fixBanner(md[1][0..1])
        @emissaryInfo[name]['rank']=md[2]
        @emissaryInfo[name]['area']=@politicalTempArea
        @emissaryInfo[name]['source']="Political"
     end
  end

  def collectRegionalSummary(line)
     return if line.include? "REGION"
     md=line.match(/(.*)\((\d+)\)\s+\w+\s+(\w+)(.*)/)
     regionName=md[1].strip
     regionNum=md[2]
     reaction=md[3]
     controller=md[4].strip
     @regionInfo=Hash.new if @regionInfo == nil
     @regionInfo[regionNum]=Hash.new
     @regionInfo[regionNum][:name]=regionName
     @regionInfo[regionNum][:reaction]=reaction
     @regionInfo[regionNum][:controller]=controller
  end

#           1         2         3         4         5         6         7         8         9         0
#[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]
#[          ARCANIA                   2ND GIANT               ARMY      ]
  def collectRegionFindGroup(line)
     return if line.include? "REGION"
     return if line.include? "military"
     return if line.include? "Economic"
     #puts "[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]"
     #printf("[%s]\n",line)
     id = line[36] + fixBanner(line[40..41])
     @militaryInfo[id] = Hash.new if @militaryInfo[id] == nil
     @militaryInfo[id][:banner] = id[1..2]
     @militaryInfo[id][:size] = line[60..70].strip
     @militaryInfo[id][:region] = line[10..31]
     @militaryInfo[id][:source] = "Encounter"
  end
#           1         2         3         4         5         6         7         8         9         0
#[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]
#[          WYRMWOOD            MO    ARMY         2GI           MARSHAL I  IKAVAN      ]
  def collectPCFindGroup(line)
     return if line.include? "PC NAME"
     #puts "[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]"
     #printf("[%s]\n",line)
     id = line[49..51]
     @militaryInfo[id] = Hash.new if @militaryInfo[id] == nil
     @militaryInfo[id][:banner] = id[1..2]
     @militaryInfo[id][:size] = line[36..48].strip
     @militaryInfo[id][:area] = line[30..31]
     @militaryInfo[id][:leader1] = line[63..92].strip
     @militaryInfo[id][:source] = "Encounter"
  end
#           1         2         3         4         5         6         7         8         9         0
#[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]
#[          AMBERLAND              NK      1UN           BRIGADE        MARSHAL I  BLACK       ]
#[          THE SOUTHERN SANDS     XV      1RA           {MASKED}       UNKNOWN]
  def collectGroupFindGroup(line)
     return if line.include? "REGION"
     #puts "[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]"
     #printf("[%s]\n",line)
     id = line[41..43]
     @militaryInfo[id] = Hash.new if @militaryInfo[id] == nil
     @militaryInfo[id][:banner] = id[1..2]
     @militaryInfo[id][:size] = line[55..68].strip
     @militaryInfo[id][:area] = line[33..34]
     @militaryInfo[id][:leader1] = line[70..92].strip
     @militaryInfo[id][:source] = "Encounter"
  end
#           1         2         3         4         5         6         7         8         9         0
#[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]
#[          AMBERLAND        NK   WARLOCK         CITY     AVALON                19872]
  def collectGroupFindPC(line)
     return if line.include? "REGION"
     #puts "[01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789]"
     #printf("[%s]\n",line)
     area = line[27..28]

     @popCenterInfo=Hash.new if @popCenterInfo == nil
     @popCenterInfo[area]=Hash.new if @popCenterInfo[area] == nil
     #@popCenterInfo[area]['region']=""
     @popCenterInfo[area]['banner']=fixBanner(line[32..33])
     @popCenterInfo[area]['name']=line[57..78].strip
     @popCenterInfo[area]['type']=line[48..56].strip
     @popCenterInfo[area]['defense']=line[77..85].strip
     @popCenterInfo[area]['source']="Encounter"
  end

  def collectMattersCovertEsotericAndGeneral(line)
     if md = line.match(/AN ARTIFACT NAMED (.*) \(SHORT NAME (.*)\)/)
        #printf("name(%s) short(%s)\n", md[1], md[2])
        artifact=Hash.new
        artifact[:source]="Priestess"
        artifact[:fullName]=md[1].gsub(',','')
        artifact[:shortName]=md[2]
        @artifactInfo=Array.new if @artifactInfo == nil
        @artifactInfo.push artifact
     end
     if md = line.match(/THERE IS A (\S+) LOCATED IN AREA (\w\w)/)
        area = md[2]
        @popCenterInfo=Hash.new if @popCenterInfo == nil
        @popCenterInfo[area]=Hash.new if @popCenterInfo[area] == nil
        @popCenterInfo[area]['type']=md[1]
        @popCenterInfo[area]['source']="Divined"
     end
     if md = line.match(/THERE IS A (\S+).* (\S+) LOCATED IN AREA (\w\w)/)
        #p md
        area = md[3]
        @popCenterInfo=Hash.new if @popCenterInfo == nil
        @popCenterInfo[area]=Hash.new if @popCenterInfo[area] == nil
        @popCenterInfo[area]['banner']=fixBanner(md[1][0..1])
        @popCenterInfo[area]['type']=md[2]
        @popCenterInfo[area]['source']="Divined"
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
     if area.size > 2  and @tempArtifactInfo != nil    # not the first line
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
           @tempArtifactInfo[:shortName] = line[83..100].strip
           @artifactInfo=Array.new if @artifactInfo == nil
           @artifactInfo.push @tempArtifactInfo
           @tempArtifactInfo = nil
        end
     end
  end


  def collectMilitaryManeuvers(line)
     return if line.include? "NO POPULATION CENTERS"
     return if not line.include? "WE PASSED"
     #printf("[%s]\n",line)
     line.split(',').each do |part|
        if md=part.match(/.* A (.*) AT (\w\w)/)
           area=md[2]
           @popCenterInfo=Hash.new if @popCenterInfo == nil
           @popCenterInfo[area]=Hash.new if @popCenterInfo[area] == nil
           @popCenterInfo[area]['type']=md[1]
           @popCenterInfo[area]['source']="Passed"
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

     @popCenterInfo=Hash.new if @popCenterInfo == nil
     @popCenterInfo[area]=Hash.new if @popCenterInfo[area] == nil
     @popCenterInfo[area]['region']=region
     @popCenterInfo[area]['banner']=@banner if  @popCenterInfo[area]['banner'] == nil
     @popCenterInfo[area]['name']=name
     @popCenterInfo[area]['type']=type
     @popCenterInfo[area]['defense']=defense
     @popCenterInfo[area]['census']=census
     @popCenterInfo[area]['food']=food
     @popCenterInfo[area]['gold']=gold
     @popCenterInfo[area]['other']=other
     @popCenterInfo[area]['source']="Self"
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

     @popCenterInfo=Hash.new if @popCenterInfo == nil
     @popCenterInfo[area]=Hash.new if @popCenterInfo[area] == nil
     #@popCenterInfo[area]['region']=""
     @popCenterInfo[area]['banner']=banner
     @popCenterInfo[area]['name']=name
     @popCenterInfo[area]['type']=type
     @popCenterInfo[area]['defense']=defense
     @popCenterInfo[area]['census']=census
     @popCenterInfo[area]['food']=food
     @popCenterInfo[area]['gold']=gold
     @popCenterInfo[area]['other']=other
     @popCenterInfo[area]['source']="Recon"
  end

  #
  def collectMilitaryRecon(line)
     return if line.include? "BRIGADES OF"
     return if line.include? "RECRUITS"
     (id,brigs,reg,area,rest)=line.split(' ',5)
     if( id.size == 3 )
        @tempGroupInfo = Hash.new
        @tempGroupInfo[:id]=id
        @tempGroupInfo[:banner]=fixBanner(id[1,2])
        @tempGroupInfo[:area]=area
        @tempGroupInfo[:size]=brigs
        line=rest.strip
        @tempGroupInfo[:leader1]=line[0,23].strip
        @tempGroupInfo[:wiz1]=line[24,20].strip
     else
        line.strip!
        if( @tempGroupInfo[:leader2] == nil) 
           @tempGroupInfo[:leader2]=line[0,23].strip
           @tempGroupInfo[:wiz2]=line[24,20].strip
        else
           @tempGroupInfo[:leader3]=line[0,23].strip
           @tempGroupInfo[:wiz3]=line[24,20].strip

           @militaryInfo = Hash.new if @militaryInfo == nil
           id= @tempGroupInfo[:id] 
           @militaryInfo[id] = Hash.new if @militaryInfo[id] == nil
           @militaryInfo[id][:banner] = @tempGroupInfo[:banner]
           @militaryInfo[id][:size] = @tempGroupInfo[:size]
           @militaryInfo[id][:area] = @tempGroupInfo[:area]
           @militaryInfo[id][:wiz1] = @tempGroupInfo[:wiz1]
           @militaryInfo[id][:wiz2] = @tempGroupInfo[:wiz2]
           @militaryInfo[id][:wiz3] = @tempGroupInfo[:wiz3]
           @militaryInfo[id][:leader1] = @tempGroupInfo[:leader1]
           @militaryInfo[id][:leader2] = @tempGroupInfo[:leader2]
           @militaryInfo[id][:leader3] = @tempGroupInfo[:leader3]
           @militaryInfo[id][:source] = "Recon"
        end
     end
  end # collectMilitaryRecon



  #
  def collectMilitaryStatus(line)
     return if line.include? "XXXX"
     if( line.include? "GROUP:" )
        (x,num,kingdom)=line.split
        groupID="#{num[0]}#{kingdom[0,2]}"
        @tempGroupInfo = Hash.new
        @tempGroupInfo[:id]=groupID
        @tempGroupInfo[:banner]= fixBanner(kingdom[0,2])
     end
     if( line.include? "SIZE:" )
#       puts line
        (x1,gsize,x2,numArchers,x3,leader)=line.split(' ',6)
        if numArchers.include? "DRAGON"
           numArchers = x3
           leader.gsub!("LEADERS:","")
        end
        if leader == nil
           leader=numArchers
           numArchers=nil
        end
        @tempGroupInfo[:size]=gsize
        @tempGroupInfo[:archers]=numArchers
        @tempGroupInfo[:leader1]=leader.strip
     end
     if( line.include? "WYVERNS"  and !line.include? ":" )
        (x,numHorse,leader)=line.split(' ',3)
        @tempGroupInfo[:horse]=numHorse
        @tempGroupInfo[:leader2]=leader.strip
     end
     if( line.include? "CAVALRY" )
        #puts line
        (x,numHorse,leader)=line.split(' ',3)
        @tempGroupInfo[:horse]=numHorse
        @tempGroupInfo[:leader2]=leader.strip
     end
     if( line.include? "LOCATED:" )
        (x,x,loc,x,foot,leader)=line.split(' ',6)
        if foot == nil
           leader=x
        elsif leader == nil
           leader=foot
           foot=nil
        end
        @tempGroupInfo[:area]=loc
        @tempGroupInfo[:foot]=foot
        @tempGroupInfo[:leader3]=leader.strip
     end
     if line.include? "REGION"
        @tempGroupInfo[:region]=line[14..60].strip
     end
     if( line.include? "POWER-" or line.include? "ADEPT" )
        wiz=line[71..line.size].strip
        if line.include? "WIZARDS:"
           @tempGroupInfo[:wiz1]=wiz.strip
        elsif line.include? "TERRAIN:"
           @tempGroupInfo[:wiz2]=wiz.strip
        else
           @tempGroupInfo[:wiz3]=wiz.strip
        end
     end
     if( line.include? "TERRAIN MOD" )
        @militaryInfo = Hash.new if @militaryInfo == nil
        id= @tempGroupInfo[:id] 
        @militaryInfo[id] = Hash.new if @militaryInfo[id] == nil
        @militaryInfo[id][:banner] = @tempGroupInfo[:banner]
        @militaryInfo[id][:size] = @tempGroupInfo[:size]
        @militaryInfo[id][:area] = @tempGroupInfo[:area]
        @militaryInfo[id][:region] = @tempGroupInfo[:region]
        @militaryInfo[id][:archers] = @tempGroupInfo[:archers]
        @militaryInfo[id][:horse] = @tempGroupInfo[:horse]
        @militaryInfo[id][:foot] = @tempGroupInfo[:foot]
        @militaryInfo[id][:wiz1] = @tempGroupInfo[:wiz1]
        @militaryInfo[id][:wiz2] = @tempGroupInfo[:wiz2]
        @militaryInfo[id][:wiz3] = @tempGroupInfo[:wiz3]
        @militaryInfo[id][:leader1] = @tempGroupInfo[:leader1]
        @militaryInfo[id][:leader2] = @tempGroupInfo[:leader2]
        @militaryInfo[id][:leader3] = @tempGroupInfo[:leader3]
        @militaryInfo[id][:source] = "Self"
#       puts @militaryInfo[id]
     end
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
     if rank == "CONSUL"
        #@banner="AN" if line.match(/ANCIENT ONES/)
        @banner="AN" 
     end
     area = x4 if area == 'AT' and x4.size == 2
     if area.size != 2
        printf("WARNING: problem parsing the following line. Skipping.\n%s\n", line)
        return
     end

     @emissaryInfo=Hash.new if @emissaryInfo == nil
     @emissaryInfo[name]=Hash.new if @emissaryInfo[name] == nil
     @emissaryInfo[name]['banner']=@banner
     @emissaryInfo[name]['rank']=rank
     @emissaryInfo[name]['area']=area
     @emissaryInfo[name]['source']="Self"


     # We can pull some population center information from these lines as well.
     md=line.match(/.* THE (.*) AT (\w\w) IN \w+/)
     pcBanner=fixBanner(md[1][0..1])
     pcType=md[1].split.last
     area=md[2]
     @popCenterInfo=Hash.new if @popCenterInfo == nil
     @popCenterInfo[area]=Hash.new if @popCenterInfo[area] == nil
     @popCenterInfo[area]['banner']=pcBanner
     @popCenterInfo[area]['type']=pcType
     @popCenterInfo[area]['source']="SelfEmLoc"
  end

  # 
  #    GI  COUNT          GURG HEARTCRUSHER     CD  LORETHANE   AWAITING FURTHER ORDERS.                                         
  # 
  def collectEmissaryRecon(line)
     return if line.include? "POP-NAME"
     banner = fixBanner(line[5,2])
     rank = line[9..23].strip
     name = line[24..45].strip
     area = line[46,2]

     @emissaryInfo=Hash.new if @emissaryInfo == nil
     @emissaryInfo[name]=Hash.new if @emissaryInfo[name] == nil
     @emissaryInfo[name]['banner']=banner
     @emissaryInfo[name]['rank']=rank
     @emissaryInfo[name]['area']=area
     @emissaryInfo[name]['source']="Recon"
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

  def showInfoRecord()
        printf("Turn,Record Type,Game Number,Kingdom,Influence\n")
        record=[@turnNumber,"I",@gameNumber,@banner,@influence].join(',')
        puts record
  end

  # Just print out the information stored in the army group hash
  # Fields are separated by commas (CSV)
  def showArmies()
     printf("Turn,Record Type,Data Source,Map Location,Kingdom,Name,Region,size,archers,food,horse,leader1,leader2,leader3,wizard1,wizard2,wizard3\n")
     @militaryInfo.keys.sort.each {|id|
        m=@militaryInfo[id]
        record=[@turnNumber,"G",m[:source],m[:area],m[:banner],id,m[:region],m[:size],m[:archers],m[:foot],m[:horse],
                                m[:leader1],m[:leader2],m[:leader3],m[:wiz1],m[:wiz2],m[:wiz3]].join(',')
        puts record
     }
  end 

  # Just print out the information stored in the population center hash
  # Fields are separated by commas (CSV)
  def showPopInfo()
     printf("Turn,Record Type,Data Source,Map Location,Kingdom,Name,Type,Defense,Census,Food,Gold,Other\n")
     @popCenterInfo.keys.sort.each {|area|
        p=@popCenterInfo[area]
        record=[@turnNumber,"P",p['source'],area,p['banner'],p['name'],p['region'],p['type'],p['defense'],p['census'],p['food'],p['gold'],p['other']].join(',')
        puts record
     }
  end

  # Just print out the information stored in the emissary info hash
  # Fields are separated by commas (CSV)
  def showEmissaryInfo()
     printf("Turn,Record Type,Data Source,Map Location,Kingdom,Name,Rank\n")
     @emissaryInfo.keys.sort.each {|name|
        e=@emissaryInfo[name]
        record=[@turnNumber,"E",e['source'],e['area'],e['banner'],name,e['rank']].join(',')
        puts record
     }
  end

  def showArtifactInfo()
     return if  @artifactInfo == nil
     printf("Turn,Record Type,Data Source,Area,Full Name,Short Name,Posessor,Artifact Type,Status Points\n")
     @artifactInfo.each {|artifact|
        record=[@turnNumber,"A",artifact[:source],artifact[:area],artifact[:fullName],artifact[:shortName],
                                artifact[:posessor],artifact[:type],artifact[:statusPts]].join(',')
        puts record
     }
  end

  def showRegionalInfo()
     printf("Turn,Record Type,Data Source,Region Name,Region Number,Reaction Level,Controller\n")
     @regionInfo.keys.each {|regionNum|
        r=@regionInfo[regionNum]
        record=[@turnNumber,"R",'Self',r[:name],regionNum,r[:reaction],r[:controller]].join(',')
        puts record
     }
  end
end

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
