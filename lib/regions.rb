#!/usr/bin/ruby
=begin
    Alamaze RegionList Module - This module contains classes 
    which pertain to the ten Alamaze regions

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

$regionMap = {
   '-1' => 'unknown',
    'X' => 'destroyed',
    '1' => 'OAKENDELL',
    '2' => 'THE NORTHERN MISTS',
    '3' => 'THE TALKING MOUNTAINS',
    '4' => 'TORVALE',
    '5' => 'AMBERLAND',
    '6' => 'THE EASTERN STEPPES',
    '7' => 'RUNNIMEDE',
    '8' => 'ARCANIA',
    '9' => 'SYNISVANIA',
   '10' => 'THE SOUTHERN SANDS'
}

#--------------------------------------------------------------------------
# CLASS: RegionList
#--------------------------------------------------------------------------
class RegionList

   REGION_INFO_FILE="data/RegionBorders.csv"

   @list           # Hash of Region objects
   @regionLocMap   # Map of area to regionNumber

   def initialize
      @list=Hash.new
      $regionMap.keys.each do |regNum|
         @list[regNum] = Region.new( regNum,  $regionMap[regNum] )
      end
      @regionLocMap=nil
      #readRegionBorderFile
   end

   def readRegionBorderFile
      return unless @regionLocMap.nil?
      appendText("Reading region border information from #{REGION_INFO_FILE}\n")
      @regionLocMap=Hash.new
      IO.foreach(REGION_INFO_FILE) do |line|
         #$stderr.puts line
         (area,junk,regNum)=line.split(',')
         @regionLocMap[area]=regNum
      end
   end

   def getRegionByArea(area)
      return @regionLocMap[area]
   end

   def getNumControlled(banner)
      count = 0
      @list.keys.each do |regNum|
         next unless controller = @list[regNum].getLatestController
         count += 1 if fixBanner(controller[0..1]) == banner
      end
      return count
   end
   def getRegionByNum(num)
      if @list[num] == nil
         appendTextWithTag("Error: No region number[#{num}]\n",TEXT_TAG_DANGER)
         return nil
      end
      return @list[num]
   end
   def gatherStats
      $popCenterList.getAllLocs.each do |area|
         pc = $popCenterList.getPopCenter(area)
         region = pc.getRegion
         @list[region].addPC( pc.getType, pc.getLastKnownPopulation) unless @list[region] == nil
      end
   end
   def addTurn(turn,num,reaction,controller,refBanner=$myKingdom)
      if @list[num] == nil
         appendTextWithTag("Error: No region number[#{num}]\n",TEXT_TAG_DANGER)
         return
      end
      @list[num].addTurn(turn,reaction,controller,refBanner)
   end
   def printHeader
      appendTextWithTag("Region Name                            Cities Towns Villages   Estimated Population  Reaction   Current Controller  \n", TEXT_TAG_HEADING)
      appendTextWithTag("------ ------------------------------- ------ ----- --------   -------------------- ---------- ---------------------\n", TEXT_TAG_HEADING)
   end
   def showAllStats(refBanner=$myKingdom)
      clearText
      unHighlight
      appendTextWithTag("Region Statistics\n\n", TEXT_TAG_TITLE)
      printHeader
      @list.keys.each do |index|
         next if index.to_i < 1
         appendText(@list[index].toString(refBanner))
      end
      showRegionalLeaders
      tagText($textBox, "FRIENDLY", TEXT_TAG_GOOD)
      tagText($textBox, "HOSTILE", TEXT_TAG_DANGER)
   end
   def saveDataToFile(ofile)
      @list.each do |area,region|
            region.saveDataToFile(ofile)
      end
   end
   def getLatestController(num)
      if @list[num] == nil
         appendTextWithTag("Error: No region number[#{num}]\n",TEXT_TAG_DANGER)
         return nil
      end
      return @list[num].getLatestController
   end
end # class RegionList



#--------------------------------------------------------------------------
# CLASS: Region
#--------------------------------------------------------------------------
class Region
   def initialize(number,name)
      @name = name
      @number = number
      @estimatedPopulation=0
      @popCount = Hash.new
      @popCount[:city]=0
      @popCount[:town]=0
      @popCount[:village]=0
      @turnInfo = Hash.new
      @turnList = nil
   end
   def addPC(type,pop)
      case type[0]
         when "C"
            @popCount[:city] += 1
         when "T"
            @popCount[:town] += 1
         when "V"
            @popCount[:village] += 1
      end
      @estimatedPopulation += pop.to_i
   end
   def addTurn(turn,reaction,owner,refBanner)
      if @turnInfo[turn] == nil
         @turnInfo[turn] = Hash.new
         @turnInfo[turn][:owner] = owner.strip
      end
      if @turnInfo[turn][:reaction] == nil
         @turnInfo[turn][:reaction] = Hash.new
         @turnInfo[turn][:reaction][refBanner] = reaction
      else
         appendTextWithTag("WARNING: Region #{@name} already has info for turn #{turn} for #{refBanner}. Ignoring extra data \n",TEXT_TAG_WARNING) if $debug.to_i == 1
      end
   end
   def getName
      return @name
   end
   def getTurnList
       if @turnList == nil
          @turnList = @turnInfo.keys.sort_by(&:to_i)
       end
       return @turnList
   end
   def getLatestController
      lastTurn = getTurnList.last
      return nil if  lastTurn == nil or @turnInfo[lastTurn] == nil
      return  @turnInfo[lastTurn][:owner]
   end
   def getLatestReaction(refBanner=$myKingdom)
      lastTurn = getTurnList.last
      return nil if  lastTurn == nil or @turnInfo[lastTurn] == nil
      return  @turnInfo[lastTurn][:reaction][refBanner]
   end
   def toString(refBanner=$myKingdom)
      lastTurn = getTurnList.last
      line = sprintf("  %2s    %-30s    %2d    %2d      %2d  %21d   %-10s  %s\n",
              @number, @name, @popCount[:city], @popCount[:town], @popCount[:village], @estimatedPopulation,
              @turnInfo[lastTurn][:reaction][refBanner], @turnInfo[lastTurn][:owner] )
      return line
   end
   def saveDataToFile(ofile)
      getTurnList.each do |turn|
         r=@turnInfo[turn]
         r[:reaction].keys.each do |refBanner|
            record=[turn,"R",'Self',@name,@number,r[:reaction][refBanner],r[:owner],refBanner].join(',')
            ofile.puts record
         end
      end
   end

end # class Region
