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

  @section=0
  @banner="xxxxxxx"
  @turnNumber=0
  @gameNumber=0
  @popCenterInfo=Hash.new
  @emissaryInfo=Hash.new
  @tempGroupInfo=nil

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
     elsif ( string.include? "has current influence ")
        @section = SECTION_DONT_CARE
     elsif ( string.include? "Production and Consumption Ledger")
        @section = SECTION_DONT_CARE
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
     elsif ( string.include? "Emissaries No Longer at Court")
        @section = SECTION_DEAD_ROYALS
     elsif ( string.include? "Activities of the Royal Court")
        @section = SECTION_EMISSARY_LOCATIONS
     elsif ( string.include? "Military Group Status")
        @section = SECTION_MILITARY_STATUS
     elsif ( string.include? "Regional Summary")
        # This line breaks the rules. I want the info from the header line.
        # Do not set @section. 
        # Just parse out @banner
        (banner,x,x)=string.split
        @banner=fixBanner(banner[0,2])
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
     when SECTION_MILITARY_STATUS
        collectMilitaryStatus(string)
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
     @popCenterInfo[area]['banner']=@banner
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
     return if line.include? "TITLE"
     rank = line[4,16].strip
     return if rank.empty?
     name = line[20,22].strip
     (x,kingdom,x,x3,area,x4)=line[43..line.size].split
     @banner=fixBanner(kingdom[0,2]) if rank == "KING" or rank == "REGENT"
     if rank == "CONSUL"
        @banner="AN" if line.match(/ANCIENT ONES/)
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
    p string if string.include? "ARTIFACT"
#   newSection=checkSection(string)
#   processLine(string) if newSection == false
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
        printf("Turn,Record Type,Game Number,Kingdom\n")
        record=[@turnNumber,"I",@gameNumber,@banner].join(',')
        puts record
  end

  # Just print out the information stored in the army group hash
  # Fields are separated by commas (CSV)
  def showArmies()
     printf("Turn,Record Type,Data Source,Map Location,Kingdom,Name,size,archers,food,horse,leader1,leader2,leader3,wizard1,wizard2,wizard3\n")
     @militaryInfo.keys.sort.each {|id|
        m=@militaryInfo[id]
        record=[@turnNumber,"G",m[:source],m[:area],m[:banner],id,m[:size],m[:archers],m[:foot],m[:horse],
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

end

ARGV.each do |fname|
   receiver = AlamazeTurnParser.new
   puts "Parsing #{fname}"
   puts
   pdf = PDF::Reader.file(fname,receiver)
end

# TODO Instead we should probably be appending
# this info to a data file.
# (or better, pushing to a database)
#receiver.showInfoRecord()
#puts
#receiver.showPopInfo()
#puts
#receiver.showEmissaryInfo()
#puts
#receiver.showArmies()

