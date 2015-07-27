#!/usr/bin/env rubyw

=begin
    Alamaze Turn Parser - This is a GUI for displaying data parsed out
    from pdf turn results from the Alamaze PBEM game.

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

$runRoot=File.dirname($0)

require 'tk'
require_relative 'lib/version'
require_relative 'lib/regions'
require_relative 'lib/emmyTool'
require_relative 'lib/emmyToolWindow'
require_relative 'lib/exploredDialog'
require_relative 'lib/groupPlotter'
require_relative 'lib/manualEntry'
require_relative 'lib/unusualSighting'
require_relative 'lib/alamazeTurnParser'
require_relative 'lib/highCouncil'
require_relative 'lib/battle'
#require 'win32/sound'
#include Win32

$debug=0


BOX_HEIGHT=14
BOX_WIDTH=BOX_HEIGHT
HISTORY_ALL=0
HISTORY_LATEST=1
HISTORY_CURRENT=2
BOX_OUTLINE_NORMAL='grey'
BOX_OUTLINE_HIGHLIGHTED='red'
I_AM_A_BOX='box'
FILTER_LABEL_COLOR='black'
EMISSARY_ARROW_COLOR='red'
EMISSARY_ARROW_WIDTH=4
ARMY_ARROW_COLOR=EMISSARY_ARROW_COLOR
ARMY_ARROW_WIDTH=EMISSARY_ARROW_WIDTH

EXPLORED_COLOR='white'
EXPLORED_MARKER='#'

TEXT_TAG_TITLE='title'
TEXT_TAG_HEADING='heading'
TEXT_TAG_NORMAL='normal'
TEXT_TAG_STALE='stale'
TEXT_TAG_GOOD='good'
TEXT_TAG_WARNING='warning'
TEXT_TAG_WARNING2='warning2'
TEXT_TAG_DANGER='danger'

$kingdomColors = {
    'AN' => '#35d5ff',
    'BL' => 'black',
    'DA' => '#934000',
    'DE' => '#ff2994',
    'DW' => '#ff9901',
    'EL' => '#00fd00',
    'GI' => '#ffffff',
    'GN' => '#fefe00',
    'RA' => '#6900ff',
    'RD' => '#fc0000',
    'SO' => '#4e80bb',
    'TR' => '#90ce4e',
    'UN' => '#e0b3b2',
    'WA' => '#9700ca',
    'WI' => '#386197',
    'HU' => '#943634',
    'NE' => 'grey',
    'XX' => 'black',
    'black' => 'black',
    'unknown' => '#f8be8f',
    EXPLORED_MARKER => EXPLORED_COLOR
}


$kingdomNameMap = {
    'AN' => 'Ancient Ones',
    'BL' => 'Black Dragons',
    'DA' => 'Dark Elves',
    'DE' => 'Demon Princes',
    'DU' => 'Druids',
    'DW' => 'Dwarves',
    'EL' => 'High Elves',
    'GI' => 'Stone Giants',
    'GN' => 'Gnomes',
    'HA' => 'Halfling',
    'NO' => 'Nomads',
    'PA' => 'Paladin',
    'RA' => 'Rangers',
    'RD' => 'Red Dragons',
    'SO' => 'Sorcerer',
    'SW' => 'Swamp Men',
    'TR' => 'Trolls',
    'UN' => 'Underworld',
    'WA' => 'Warlock',
    'WE' => 'Westmen',
    'WI' => 'Witchlord',
    'NE' => 'Neutral',
    'XX' => 'Destroyed'
}

$mapSquares = [
    "fffssffwwfppmmmwwwpmmmmmpp",
    "ffffffffwfmppwwpppmmmmmmpp",
    "wffffmmfwffpswwffppmmmmppp",
    "wfffffffwwppsswwfppmmpmmpd",
    "wsffffppwwwwwwwwfppmmmmppd",
    "wsspppppwwfffpwwffppmmppdd",
    "wfffffffpfppfpppffpppffppd",
    "wwfffffppffpffpmppffpffpmm",
    "wppmpfppppppffpmppffffpppm",
    "wmmmffpfpmmmpppmdpppffwwpm",
    "wwpfppmffpmmppmmdppssswwpm",
    "pwwfpmpdppwwppfppppsswwffp",
    "wwwffppppwwwwpffpwwwwwwffp",
    "wppfffffwwfwpmffpwpwpsssff",
    "wppffpffwpmwpffffwwwpfmmff",
    "wffpfpppwwwwppfpppwwwfpppp",
    "wppfppsswwpsspppppwpwppsss",
    "wwpfppppspppppmpppwwwffpss",
    "pwpppddppfpfppmppffwpffsss",
    "wwppmmmmpfpffppppfppppppss",
    "wfffppfppppppfpppppmppppff",
    "wffffpfpppmpppffpmmmmmpppp",
    "wwsppppffpmmmdpppmpfpppppp",
    "ssspmppfpdmmddpppdppppddmm",
    "mmmmmpmdddpppppdddppdddddm",
    "mmmmmmmmddpppppdddpppddddd"
]

#@MAP
$canvas
$textBox
$history = TkVariable.new
$cursorLoc = TkVariable.new
$myGameInfoText = TkVariable.new
$textWindow = nil
#$emmyToolText = nil


$currentTopTag = 'small'


# New OO stuff
$areaList = nil
$emissaryList = nil
$popCenterList= nil
$groupList= nil
$artifactList = nil
$unusualSightings = nil
$toggles = nil
$resultsDir= "."
$highCouncilList=nil
$passThroughRecords=nil
$battleList=nil

$boldFont = TkFont.new( "weight" => "bold")

#---------------------------------------------------------------------
# The human_sort method was taken from
# http://blog.zenspider.com/blog/2012/01/array-natural_sort.html
#---------------------------------------------------------------------
class Array
  def human_sort
    sort_by { |item| item.to_s.split(/(\d+)/).map { |e| [e.to_i, e] } }
  end
end

#--------------------------------------------------------------------------
# CLASS: AreaList
#--------------------------------------------------------------------------
class AreaList
   def initialize
      @bigList=Hash.new
      @smallList=Hash.new
   end
   def addBox(loc,smallBox,bigBox)
      if @smallList[loc] == nil
         @smallList[loc] = Area.new(loc,smallBox)
         @bigList[loc] = Area.new(loc,bigBox)
      else
         appendTextWithTag("WARNING: We already have a box at #{loc}. Skipping.\n",TEXT_TAG_WARNING) if $debug.to_i == 1

      end
   end
   def addtag(loc,tag)
      if @smallList[loc] == nil
         appendTextWithTag("WARNING: Cannot add tag #{tag} at #{loc}. Skipping.\n",TEXT_TAG_WARNING) if $debug.to_i == 1
      else
         @smallList[loc].addTag(tag)
         @bigList[loc].addTag(tag)
      end
   end
   def addEmissary(id, loc)
      if @smallList[loc] == nil
         appendTextWithTag("WARNING: Cannot add emissary #{id} at #{loc}. Skipping.\n",TEXT_TAG_WARNING) if $debug.to_i == 1
      else
         @smallList[loc].addEmissary(id)
      end
   end
   def getEmissaryList(loc)
      return nil if @smallList[loc] == nil
      return @smallList[loc].getEmissaryList
   end
   def addGroup(id, loc, turn, region)
      if @smallList[loc] == nil
         appendTextWithTag("WARNING: Group #{id} was somewhere non-specific in #{region} on turn #{turn}.\n",TEXT_TAG_WARNING)
      else
         @smallList[loc].addGroup(id)
      end
   end
   def getGroupList(loc)
      return nil if @smallList[loc] == nil
      return @smallList[loc].getGroupList
   end
   def computeDistance(loc1, loc2)
      return 999 if loc1 == nil or loc1.empty?
      return 999 if loc2 == nil or loc2.empty?
      yPart = loc1[0].ord - loc2[0].ord
      xPart = loc1[1].ord - loc2[1].ord
      return [xPart.abs , yPart.abs].max
   end
end # class AreaList

#--------------------------------------------------------------------------
# CLASS: Area
#--------------------------------------------------------------------------
class Area
   def initialize(loc,box)
      @loc = loc
      @box = box
      #@pcList=Hash.new
      @emissaryList=Hash.new
      @groupList=Hash.new
      #@region=nil
   end
   def addTag(tag)
      @box.addtag(tag)
   end
   def getLoc
      return(@loc)
   end
   def addEmissary(id)
      @emissaryList[id] = 1
   end
   def getEmissaryList
      return @emissaryList.keys.sort
   end
   def addGroup(id)
      @groupList[id] = 1
   end
   def getGroupList
      return @groupList.keys.sort
   end

   def Area.isLocValid(loc)
      return false if loc.size != 2
      uloc = loc.upcase
      uloc.each_char do |char|
         return false if char < 'A' or char > 'Z'
      end
      return true
   end
end # class Area

class ArtifactList
   def initialize
      @list=Array.new
   end
   #@turnNumber,"A",artifact[:source],artifact[:area],artifact[:fullName],artifact[:shortName],
   #                                artifact[:posessor],artifact[:type],artifact[:statusPts]].join(',')
   def addArtifact(line)
      (turn,x,source,area,fullName,shortName,posessor,type,statusPts)=line.split(',')
      index = findIndexByShortName(shortName)
      if index == nil
         artifact=Artifact.new(fullName,shortName,type,statusPts)
         artifact.addTurn(turn,source,area,posessor)
         @list.push artifact
         return artifact
      end

      @list[index].addTurn(turn,source,area,posessor)
      return @list[index]
   end
   def findIndexByShortName(name)
      @list.each_index do |index|
         return index if @list[index].getShortName == name
      end
      return nil
   end
   def printHeader
      appendTextWithTag("Trn  Source             Full Name             Short Name         Possessor              Area    Type       Status Pts\n",TEXT_TAG_HEADING)
      appendTextWithTag("--- --------- ------------------------------- ---------- ------------------------------ ---- ------------  ------------\n",TEXT_TAG_HEADING)
   end
   def showAll
      @list.each_index do |index|
         turn = @list[index].getTurnList.last
         if turn == $currentTurn
            appendText(@list[index].toString( nil ))
         else
            appendTextWithTag(@list[index].toString( nil ), TEXT_TAG_STALE)
         end
      end
   end
   def saveDataToFile(ofile)
      @list.each do |artifact|
            artifact.saveDataToFile(ofile)
      end
   end
end # class ArtifactList

class Artifact
   def initialize(fullName,shortName,type,statusPts)
      @fullName = fullName
      @shortName = shortName
      @type = type
      @statusPts = statusPts.strip
      @turnInfo = Hash.new
      @turnList = nil
   end
   def addTurn(turn,source,area,posessor)
      if @turnInfo[turn] == nil
         @turnInfo[turn] = Hash.new
         @turnInfo[turn][:source] = source
         @turnInfo[turn][:area] = area if area != nil
         @turnInfo[turn][:posessor] = posessor if posessor != nil
      else
         appendTextWithTag("WARNING: Artifact #{@shortName} already has info for turn #{turn}. Ignoring data from #{source}\n", 
                            TEXT_TAG_WARNING) if $debug.to_i == 1
      end
   end
   def getShortName
      return @shortName
   end
   def getTurnList
       if @turnList == nil
          @turnList = @turnInfo.keys.sort_by(&:to_i)
       end
       return @turnList
   end
   def toString(turn)
      turn = getTurnList.last if turn == nil
      if @turnInfo[turn] == nil 
         if $debug.to_i == 1
            return("Error: no artifact info data for area[#{@fullName}] on turn[#{turn}]\n")
         else
            return("")
         end
      end
      line=sprintf("%3d %-9s %-30s  %10s  %-30s %2s  %-12s %6s \n", 
                   turn, 
                   @turnInfo[turn][:source], 
                   @fullName,
                   @shortName,
                   @turnInfo[turn][:posessor], 
                   @turnInfo[turn][:area], 
                   @type,
                   @statusPts)
      return line
   end # toString
   def saveDataToFile(ofile)
      getTurnList.each do |turn|
         artifact=@turnInfo[turn]
         record=[turn,"A",artifact[:source],artifact[:area],@fullName,@shortName,
                                artifact[:posessor],@type,@statusPts].join(',')
         ofile.puts record
      end
   end
end # class Artifact

#--------------------------------------------------------------------------
# CLASS: PopCenterList
#--------------------------------------------------------------------------
class PopCenterList
   def initialize
      @list=Hash.new
   end
   def addPopCenter(line)
      (turn,x,source,area,banner,name,region,type,defense,census,food,gold,other)=line.split(',')
      if @list[area] == nil
         @list[area] = PopCenter.new(name,area,type,region)
      end # if new emissary
      @list[area].addTurn(type,name,turn,source,banner,region,defense,census,food,gold,other.strip)
      return @list[area]
   end
   def printHeader
      appendTextWithTag("Trn Source     Type       Name            Regn Area KI Defnse Census  Food   Gold   Other\n",TEXT_TAG_HEADING)
      appendTextWithTag("--- --------- ------ -------------------- ---- ---- -- ------ ------ ------ ------ ------\n",TEXT_TAG_HEADING)
   end
   def getPopCenter(area)
      return @list[area]
   end
   def getByLatestKingdom(banner)
      pcList = Array.new
      @list.each do |area,popCenter|
         if popCenter.getLastKnownOwner == banner
            pcList.push popCenter
         end
      end
      return pcList
   end
   def getByKingdomAndTurn(banner,turn)
      pcList = Array.new
      @list.each do |area,popCenter|
         if popCenter.getOwnerByTurn(turn) == banner
            pcList.push popCenter
         end
      end
      return pcList
   end # getByKingdomAndTurn

   def getByRegion(region)
      pcList = Array.new
      @list.each do |area,popCenter|
         if popCenter.getRegion == region
            pcList.push popCenter
         end
      end
      return pcList
   end

   def getCurrentProductionByRegionAndKingdom(region, banner)
      food = gold = 0
      @list.each do |area,popCenter|
         next if banner != nil and popCenter.getOwnerByTurn($currentTurn) != banner 
         next if region != nil and popCenter.getRegion.to_i != region.to_i 
         (f,g)=popCenter.getProduction($currentTurn)
         food += f.to_i
         gold += g.to_i
      end
      return food, gold
   end # end getCurrentProductionByRegionAndKingdom
   def saveDataToFile(ofile)
      @list.each do |area,popCenter|
            popCenter.saveDataToFile(ofile)
      end
   end
   def getAllLocs
      return @list.keys
   end
   def addMarkers
      @list.each do |area,pop|
         addColoredMapMarker(area, pop.getType[0], pop.getLastKnownOwner, pop.getRegion)
      end
   end
   # Look for PC that used to be ours but are not anymore.
   # Add a new record with the banner as unknown
   def  findLostPC
      lostPopCenters = Array.new
      lastTurn = $currentTurn.to_i - 1
      @list.each do |area,popCenter|
         #appendText("area[#{area}] lastOwner[#{popCenter.getOwnerByTurn("#{lastTurn}")}] curOwner[#{popCenter.getOwnerByTurn($currentTurn)}] myKingdom[#{$myKingdom}]\n")
         if popCenter.getOwnerByTurn("#{lastTurn}") == $myKingdom
            #appendText("- owned last turn\n")
            if popCenter.getOwnerByTurn($currentTurn) != $myKingdom
               #appendText("- not owned now\n")
               lostPopCenters.push area
            end
         end
      end
      return lostPopCenters
   end

   def  findGainedPC
      gainedPopCenters = Array.new
      lastTurn = $currentTurn.to_i - 1
      @list.each do |area,popCenter|
         if popCenter.getOwnerByTurn($currentTurn) == $myKingdom
            if popCenter.getOwnerByTurn("#{lastTurn}") != $myKingdom
               #appendText("lastTurn=#{lastTurn}  PrevOwner=#{popCenter.getOwnerByTurn(lastTurn)}\n")
               gainedPopCenters.push area
            end
         end
      end
      return gainedPopCenters
   end

   def changeOwner(area,owner)
      @list[area].changeOwner(owner)
   end

   def destroyPC(area)
      @list[area].destroyPC
      $canvas.raise($currentTopTag)
   end
   
   def fixRegions(quiet=false)
      appendText("Fixing Regions.\n\n") unless quiet
      numUpdated=0
      @list.each do |area,popCenter|
         needsFixin=false
         regNum = popCenter.getRegion
         newReg = $regionList.getRegionByArea(area)
         if regNum.nil? or regNum.empty? 
            appendText("Updating popCenter at #{area} with region #{newReg}.\n") unless quiet
            needsFixin=true
         elsif regNum != newReg
            # We cheat and use region number "X" to denote a destroyed PC
            if regNum != "X"
               appendText("Updating popCenter at #{area} with region #{newReg}. Had been incorrectly set to #{regNum}.\n")
               needsFixin=true
            end
         end
         if needsFixin
            numUpdated += 1
            popCenter.setRegion(newReg)
            addColoredMapMarker(area, popCenter.getType[0], popCenter.getLastKnownOwner, popCenter.getRegion)
            highlightTag("box-#{area}",false) unless quiet
         end
      end
      appendText("\nUpdated #{numUpdated} population centers.\n") unless quiet
      appendText("Do not forget to save!\n") if numUpdated > 0 and not quiet
   end # end fixRegions

   def checkOwners(ownedString)
      return if ownedString.nil?
      ownedList=ownedString.split(',')

      potentialList=Array.new
      getByLatestKingdom($myKingdom).each do |popCenter|
         potentialList.push popCenter.getArea
      end

      lostPCs= potentialList - ownedList
      #appendText("potential[#{potentialList}]\nowned[#{ownedList}]\nlost=[#{lostPCs}]\n")

      lostPCs.each do |area|
         changeOwner(area,"??")
      end
   end

end # end class PopCenterList

#--------------------------------------------------------------------------
# CLASS: PopCenter
#--------------------------------------------------------------------------
class PopCenter
   def initialize(name,area,type,region)
      @name = name
      @reconName = name[0..9]
      @area = area
      @type = type[0..3] if type != nil
      @region = region
      @turnInfo = Hash.new
      @turnList = nil
   end
   def addTurn(type,name,turn,source,banner,region,defense,census,food,gold,other)
      @region = region unless region == nil or region.empty?  #we do not get region on recon, so it may be nil
      @type = type[0..3] unless type == nil or type.empty?  #we do not get type on encounter, so it may be nil
      @name = name if source == 'Self'  # recon truncates names
      if @turnInfo[turn] == nil
         @turnInfo[turn] = Hash.new
         @turnInfo[turn][:source] = source
         @turnInfo[turn][:banner] = banner
         @turnInfo[turn][:defense] = defense
         @turnInfo[turn][:census] = census
         @turnInfo[turn][:food] = food
         @turnInfo[turn][:gold] = gold
         @turnInfo[turn][:other] = other
         @turnList = nil # force it to be recomputed later
         #$areaList.addEmissary( getID(), area )
      else
         appendTextWithTag("WARNING: PopCenter #{@name} at #{@area} already has info for turn #{turn}. Ignoring data from #{source}\n",
                           TEXT_TAG_WARNING) unless source == "Recon" or $debug.to_i == 0
      end
   end

   def changeOwner(owner)
      turn = $currentTurn
      if @turnInfo[turn] == nil
         addTurn(nil,nil,$currentTurn,"manual",nil,nil,nil,nil,nil,nil,nil)
      end
      appendText("Changing owner from #{@turnInfo[turn][:banner]} to #{owner}\n")
      @turnInfo[turn][:source] = "manual"
      @turnInfo[turn][:banner] = owner
      addColoredMapMarker(@area, @type[0], getLastKnownOwner, @region)
   end

   def destroyPC
      setRegion("X")
      changeOwner("XX")
      turn=$currentTurn
      @turnInfo[turn][:defense] = 0
      @turnInfo[turn][:census] = 0
      @turnInfo[turn][:food] = 0
      @turnInfo[turn][:gold] = 0
      @turnInfo[turn][:other] = "DESTROYED"
   end

   def toString(turn)
      turn = getTurnList.last if turn == nil
      if @turnInfo[turn] == nil 
         if $debug.to_i == 1
            return("Error: no pop info data for area[#{@area}] on turn[#{turn}]\n")
         else
            return("")
         end
      end
      line=sprintf("%3d %-9s %-6s %-20s  %2s   %2s  %2s %6s %6s %6s %6s %s\n", 
                   turn, 
                   @turnInfo[turn][:source], 
                   @type,
                   @name,
                   @region,
                   @area, 
                   @turnInfo[turn][:banner], 
                   @turnInfo[turn][:defense], 
                   @turnInfo[turn][:census],
                   @turnInfo[turn][:food],
                   @turnInfo[turn][:gold], 
                   @turnInfo[turn][:other])
      return line
    end

    def getLatestStats
       turn = getTurnList.Last
       if turn == nil or @turnInfo[turn] == nil
          return 0,0
       else
          ti= @turnInfo[turn]
          return ti[:banner],ti[:defense],ti[:census],ti[:food],ti[:gold]
       end
    end

    def getLastKnownPopulation
       return getPopulationByTurn( getTurnList.last)
    end
    def getPopulationByTurn(turn)
       return 0 if @turnInfo[turn] == nil
       return @turnInfo[turn][:census]
    end
    def getProduction(turn)
       if turn == nil or @turnInfo[turn] == nil
          return 0,0
       else
          return @turnInfo[turn][:food], @turnInfo[turn][:gold]
       end
    end
    def getTurnList
       if @turnList == nil
          @turnList = @turnInfo.keys.sort_by(&:to_i)
       end
       return @turnList
    end
    def getLatestTurn
       return getTurnList.last
    end
    def getOwnerByTurn(turn) 
       return nil if @turnInfo[turn] == nil
       return @turnInfo[turn][:banner]
    end
    def getLastKnownOwner
       lastTurn= getTurnList.last
       return getOwnerByTurn(lastTurn)
    end
    def getArea
       return @area
    end
    def getType
       return @type
    end
    def getName
       return @name
    end
    def getRegion
       return @region
    end
    def setRegion(regNum)
       @region=regNum
    end
    def saveDataToFile(ofile)
      getTurnList.each do |turn|
         p=@turnInfo[turn]
         record=[turn,"P",p[:source],@area,p[:banner],@name,@region,@type,
                 p[:defense],p[:census],p[:food],p[:gold],p[:other]].join(',')
         ofile.puts record
      end
    end
   # more of 'acceptable' vs 'valid'
   def PopCenter.isValidType(pcType)
      case pcType[0..2].upcase
      when "CIT"
         return true
      when "TOW"
         return true
      when "VIL"
         return true
      else
         return false
      end
   end
end # end class Popcenter

#--------------------------------------------------------------------------
# CLASS: GroupList
#--------------------------------------------------------------------------
class GroupList
   def initialize
      @list=Hash.new
   end
   def addGroup(line)
      (turn,x,source,area,banner,name,region,size,archers,foot,horse,l1,l2,l3,w1,w2,w3)=line.split(',')
      id="#{banner}-#{name}"
      if @list[id] == nil
         @list[id] = Group.new(banner,name)
      end # if new emissary
      @list[id].addTurn(turn,source,area,region,size,archers,foot,horse,l1,l2,l3,w1,w2,w3)
   end
   def showArmyHeader
      appendTextWithTag("Trn Source    Area KI Name     Size   \n",TEXT_TAG_HEADING)
      appendTextWithTag("--- --------- ---- -- ---- -----------\n",TEXT_TAG_HEADING)
   end
   def getGroupByID(id)
      return @list[id]
   end
   def saveDataToFile(ofile)
      @list.each do |area,group|
            group.saveDataToFile(ofile)
      end
   end
   def getGroupsByKingdom(banner)
      groupList = Array.new
      @list.each do |id,group|
         groupList.push group if group.getBanner == banner
      end
      return groupList
   end
   def getGroupNotOfKingdom(banner)
      groupList = Array.new
      @list.each do |id,group|
         groupList.push group unless group.getBanner == banner
      end
      return groupList
   end

   def showAllGroups(printReport=true)
      unHighlight
      if printReport
         clearText 
         appendTextWithTag("Last known location of all groups (ordered by group ID)\n\n",TEXT_TAG_TITLE) 
         showArmyHeader
      end
      @list.keys.sort.each do |groupKey|
         turn = @list[groupKey].getLastTurn 
         line = @list[groupKey].toString(  turn )
         if turn == $currentTurn
            appendText(line) if printReport
            #addColoredMapMarker(@list[groupKey].getLocOnTurn(turn), @list[groupKey].getName, @list[groupKey].getBanner)
            addColoredMapMarker(@list[groupKey].getLocOnTurn(turn), 'A', @list[groupKey].getBanner, @list[groupKey].getName[0])
         else
            appendTextWithTag(line, TEXT_TAG_STALE) if printReport
         end
      end
      $canvas.raise($currentTopTag)
   end

end # end class Group List

#--------------------------------------------------------------------------
# CLASS: Group
#--------------------------------------------------------------------------
class Group
   def initialize(banner,name)
      @name = name
      @banner = banner
      @turnInfo = Hash.new
      @turnList = nil
   end
   def addTurn(turn,source,area,region,size,archers,foot,horse,l1,l2,l3,w1,w2,w3)
       if @turnInfo[turn] == nil or @turnInfo[turn][:source] == "Encounter"
          @turnInfo[turn] = Hash.new
          @turnInfo[turn][:source] = source
          @turnInfo[turn][:area] = area unless area == nil
          @turnInfo[turn][:region] = region unless region == nil
          @turnInfo[turn][:size] = size unless size == nil
          @turnInfo[turn][:archers] = archers unless archers == nil
          @turnInfo[turn][:foot] = foot unless foot == nil
          @turnInfo[turn][:horse] = horse unless horse == nil
          @turnInfo[turn][:l1] = l1 unless l1 == nil
          @turnInfo[turn][:l2] = l2 unless l2 == nil
          @turnInfo[turn][:l3] = l3 unless l3 == nil
          @turnInfo[turn][:w1] = w1 unless w1 == nil
          @turnInfo[turn][:w2] = w2 unless w2 == nil
          @turnInfo[turn][:w3] = w3 unless w3 == nil
          @turnList = nil # force it to be recomputed later
          $areaList.addGroup( getID(), area, turn, region)
       else
          appendTextWithTag("WARNING: ArmyGroup #{@banner}-#{@name} already has info for turn #{turn}. Ignoring data from #{source}\n",
                            TEXT_TAG_WARNING) unless source == "Recon" or $debug.to_i == 1
       end
   end
   def getBanner
      return @banner
   end
   def getName
      return @name
   end
   def getRank(turn)
      return @turnInfo[turn][:rank]
   end
   def getID
       return "#{@banner}-#{@name}"
   end
   def getAreaList
       return nil if @turnInfo == nil
       aList = Array.new
       getTurns.each do |turn|
          aList.push "#{turn}-#{@turnInfo[turn][:area]}"
       end
       return aList
   end
   def hasTurn(turn)
      return  @turnInfo[turn] != nil
   end
   def getTurns
      if @turnList == nil
         @turnList = @turnInfo.keys.sort_by(&:to_i)
      end
      return @turnList
   end
   def getLastTurn
      return getTurns().last
   end
   def getSize(turn)
      if hasTurn(turn)
         return  @turnInfo[turn][:size]
      else
         return  nil
      end
   end
   def getLocOnTurn(turn)
      if hasTurn(turn)
         return  @turnInfo[turn][:area]
      else
         return  nil
      end
   end

   def toString(turn)
      if @turnInfo[turn] == nil
         if $debug.to_i == 1
            return("Error: We do not know where group #{@name} of the #{@banner} kingdom was on turn[#{turn}]\n")
         else
            return("")
         end
      end
      line=sprintf("%3d %-9s  %2.2s  %2s %3s  %-12s \n", 
                    turn, 
                    @turnInfo[turn][:source],
                    @turnInfo[turn][:area], 
                    @banner,
                    @name, 
                    @turnInfo[turn][:size]) 
      return line
   end # toString

   def saveDataToFile(ofile) 
      getTurns.each do |turn|
            m = @turnInfo[turn]
            record=[turn,"G",m[:source],m[:area],@banner,@name,m[:region],m[:size],m[:archers],m[:foot],m[:horse],
                                m[:leader1],m[:leader2],m[:leader3],m[:wiz1],m[:wiz2],m[:wiz3]].join(',')
            ofile.puts record
      end
   end # save data to file

   def Group.isValid(banner,name)
      return false if banner != name[1..2]
      return true
   end

end # end class Group

#--------------------------------------------------------------------------
# CLASS: EmissaryList
#--------------------------------------------------------------------------
class EmissaryList
   def initialize
      @list=Hash.new
   end
   def addEmissary(line)
      (turn,x,source,area,banner,name,rank)=line.split(',')
      id="#{banner}-#{name}"
      if @list[id] == nil
         @list[id] = Emissary.new(banner,name)
      end # if new emissary
      @list[id].addTurn(turn,rank.strip,area,source)
   end
   def getEmissaryNotOfKingdom(banner, politicalOnly)
      emList = Array.new
      @list.each do |id,emissary|
         isPol = emissary.isPolitical
         #appendText(" #{emissary.getName} isPolitical = #{isPol}\n")
         next if politicalOnly == true and isPol == false
         emList.push emissary unless emissary.getBanner == banner
      end
      return emList
   end

   def  findLostEmissaries
      lostRoyals = Array.new
      lastTurn = $currentTurn.to_i - 1
      @list.each do |id,emissary|
         next if emissary.hasTurn( $currentTurn )
         next if emissary.getBanner != $myKingdom
         lostRoyals.push id if emissary.getLastTurn.to_i == lastTurn.to_i
      end
      return lostRoyals
   end
   
   def findNewEmissaries
      newRoyals = Array.new
      lastTurn = $currentTurn.to_i - 1
      @list.each do |id,emissary|
         next if emissary.getLastTurn != $currentTurn 
         next if emissary.getBanner != $myKingdom
            newRoyals.push id if ! emissary.hasTurn( "#{lastTurn}")
      end
      return newRoyals
   end

   def getEmissaryByKingdom(banner)
      emList = Array.new
      @list.each do |id,emissary|
         emList.push emissary if emissary.getBanner == banner
      end
      return emList
   end
   def showEmHeader
      appendTextWithTag("Trn Source    Area KI          Name               Rank\n",TEXT_TAG_HEADING)
      appendTextWithTag("--- --------- ---- -- ------------------------- ---------\n",TEXT_TAG_HEADING)
   end
   def getEmissaryByID(id)
      return @list[id]
   end
   def saveDataToFile(ofile)
      @list.each do |area,emissary|
            emissary.saveDataToFile(ofile)
      end
   end
end

#--------------------------------------------------------------------------
# CLASS: Emissary
#--------------------------------------------------------------------------
class Emissary
   def initialize(banner,name)
      @name = name
      @banner = banner
      @turnInfo = Hash.new
      @turnList = nil
   end
   def addTurn(turn,rank,area,source)
      if @turnInfo[turn] == nil
         @turnInfo[turn] = Hash.new
         @turnInfo[turn][:rank] = rank
         @turnInfo[turn][:area] = area
         @turnInfo[turn][:source] = source
         @turnList = nil # force it to be recomputed later
         $areaList.addEmissary( getID(), area )
      else
         appendTextWithTag("WARNING: Emissary #{@banner}-#{@name} already has info for turn #{turn}. Ignoring data from #{source}\n",
                           TEXT_TAG_WARNING) unless source == "Recon" or $debug.to_i == 1
      end
   end
   def getAreaList
       return nil if @turnInfo == nil
       aList = Array.new
       getTurns.each do |turn|
          aList.push "#{turn}-#{@turnInfo[turn][:area]}"
       end
       return aList
   end
   def isPolitical
      rank = getRank( getLastTurn )
      case rank[0..3]
      when "AGEN"
         return false
      when "FANA"
         return false
      when "PRIE"
         return false
      when "PRIS"
         return false
      else
         return true
      end
   end
   def getBanner
      return @banner
   end
   def getName
      return @name
   end
   def getRank(turn)
      return @turnInfo[turn][:rank]
   end
   def getID
       return "#{@banner}-#{@name}"
   end
   def hasTurn(turn)
      return  @turnInfo[turn] != nil
   end
   def getTurns
      if @turnList == nil
         @turnList = @turnInfo.keys.sort_by(&:to_i)
      end
      return @turnList
   end
   def getLastTurn
      return getTurns().last
   end
   def getLocOnTurn(turn)
      if hasTurn(turn)
         return  @turnInfo[turn][:area] 
      else
         return  nil
      end
   end
   def toString(turn)
      if @turnInfo[turn] == nil 
         if $debug.to_i == 1
            return("Error: We do not know where emissary #{@name} of the #{@banner} kingdom was on turn[#{turn}]\n")
         else
            return("")
         end
      end
      line=sprintf("%3d %-9s  %2.2s  %2s %-25s %s\n", 
                      turn, 
                      @turnInfo[turn][:source], 
                      @turnInfo[turn][:area], 
                      @banner,
                      @name, 
                      @turnInfo[turn][:rank])
      return line
   end # toString
   def saveDataToFile(ofile)
      getTurns.each do |turn|
              e = @turnInfo[turn]
              record=[turn,"E",e[:source],e[:area],@banner,@name,e[:rank]].join(',')
              ofile.puts record
      end
   end # save data to file

   # more of 'acceptable' vs 'valid'
   def Emissary.isValidRank(rank)
      case rank[0..2].upcase
      when "BAR"
         return true
      when "DUK"
         return true
      when "DUC"
         return true
      when "GOV"
         return true
      when "PRO"
         return true
      when "AMB"
         return true
      when "ENV"
         return true
      when "PRI"
         return true
      when "DEM"
         return true
      when "COU"
         return true
      when "KIN"
         return true
      when "REG"
         return true
      when "CON"
         return true
      when "AGE"
         return true
      when "FAN"
         return true
      else
         return false
      end
   end
end # class Emissary

#--------------------------------------------------------------------------
# Other stuff below here
#--------------------------------------------------------------------------

def fixBanner(banner)
   if banner == "RE"
      return "RD"
   else
      return banner
   end
end

# Show emissaries currently in pop centers owned by banner
def showScaryRoyals(threatenedBanner, turn)
   emList = $emissaryList.getEmissaryNotOfKingdom(threatenedBanner,true)
   appendTextWithTag("\n\nLooking for Emissaries threatending the #{threatenedBanner} kingdom on turn #{turn}\n\n",TEXT_TAG_TITLE)
   $popCenterList.printHeader
   emList.each do | emissary |
      emissaryLoc = emissary.getLocOnTurn(turn)
      next if emissaryLoc == nil
      popCenter = $popCenterList.getPopCenter(emissaryLoc)
      next if popCenter == nil
      owner = popCenter.getOwnerByTurn(turn)
      if owner == threatenedBanner
         pcInfo = popCenter.toString(turn).strip
         line = "  #{pcInfo}      is threatened by #{emissary.getName}(#{emissary.getRank(turn)}) of the #{emissary.getBanner} kingdom\n"
         appendTextWithTag(line,TEXT_TAG_DANGER)
      #appendText(emissary.toString(turn) )if owner == threatenedBanner
      end
   end
end

def showScaryGroups(threatenedBanner, turn)
   groupList = $groupList.getGroupNotOfKingdom(threatenedBanner)
   appendTextWithTag("\n\nLooking for Groups threatending the #{threatenedBanner} kingdom on turn #{turn}\n\n",TEXT_TAG_TITLE)
   $popCenterList.printHeader
   groupList.each do | group |
      groupLoc = group.getLocOnTurn(turn)
      next if groupLoc == nil
      popCenter = $popCenterList.getPopCenter(groupLoc)
      next if popCenter == nil
      owner = popCenter.getOwnerByTurn(turn)
      if owner == threatenedBanner
         pcInfo = popCenter.toString(turn).strip
         line = " #{pcInfo}      is threatened by #{group.getName}(#{group.getSize(turn)}) of the #{group.getBanner} kingdom\n"
         appendTextWithTag(line,TEXT_TAG_DANGER)
      #appendText(emissary.toString(turn) )if owner == threatenedBanner
      end
   end
end


def tweakVolume
   #(l,r)=Sound.get_wave_volume
   #appendText("l=#{l} r=#{r}\n")
#  Sound.set_wave_volume(3000)
   #(l,r)=Sound.get_wave_volume
   #appendText("l=#{l} r=#{r}\n")
end

# hard coded for now.
# Later, we want to play a unique tune
# for each kingdom as it loads.
def playSound
#  Sound.play('Alamazethingy1.wav',Sound::ASYNC)
end

def getBannerColor(banner)
   color = $kingdomColors[banner]
   color = $kingdomColors['NE'] if color==nil
   return color
end


# remove all previous highlights
def unHighlightTag(tag)
  $canvas.itemconfigure(tag, 
                        'width' => 1,
                        'state' => 'hidden',
                        'outline' => BOX_OUTLINE_NORMAL)
end

def unHighlight()
  $canvas.delete('line')
  unHighlightTag(I_AM_A_BOX)
end

def highlightTag(tag, clearOtherHighlights)
  unHighlight if clearOtherHighlights
  # highlight all of the boxes with the given tag
  $canvas.raise(tag) 
  $canvas.raise('Marker') 
  #$canvas.itemconfigure('Marker', 'fill' =>'black' ) 
  $canvas.itemconfigure(tag, 
                        'width' => 3,
                        'state' => 'normal',
                        'outline' => BOX_OUTLINE_HIGHLIGHTED)
                        #'fill' => 'green')
   $canvas.raise($currentTopTag)
end

def showPopCenterChanges
   clearText
   unHighlight
   appendTextWithTag("Population centers which we have gained or lost this turn.\n\n",TEXT_TAG_TITLE)
   $popCenterList.printHeader
   $popCenterList.findLostPC.each do |area|
      line = $popCenterList.getPopCenter(area).toString($currentTurn)
      appendTextWithTag(line,TEXT_TAG_DANGER)
   end
   $popCenterList.findGainedPC.each do |area|
      line = $popCenterList.getPopCenter(area).toString($currentTurn)
      appendTextWithTag(line,TEXT_TAG_GOOD)
   end
end

def showEmissaryChanges
   clearText
   unHighlight
   appendTextWithTag("Emissaries which we have gained or lost this turn.\n\n",TEXT_TAG_TITLE)
   lastTurn = $currentTurn.to_i - 1
   $emissaryList.showEmHeader
   $emissaryList.findLostEmissaries.each do |id|
      line = $emissaryList.getEmissaryByID(id).toString("#{lastTurn}")
      appendTextWithTag(line,TEXT_TAG_DANGER)
   end
   $emissaryList.findNewEmissaries.each do |id|
      line = $emissaryList.getEmissaryByID(id).toString($currentTurn)
      appendTextWithTag(line,TEXT_TAG_GOOD)
   end
end

def showAllArtifacts
   clearText
   unHighlight
   appendTextWithTag("Last known information we have on all artifacts\n\n",TEXT_TAG_TITLE)
   $artifactList.printHeader
   $artifactList.showAll
end

def showMyThreatenedProduction
   clearText
   unHighlight
   showScaryRoyals($myKingdom,$currentTurn)
   showScaryGroups($myKingdom,$currentTurn)
end

def showMyProduction
   clearText
   unHighlight
   #showProductionStatsByRegion
   showProductionStatsByKingdom
   showPopCentersByRegion
end


def showProductionForKingdomPerRegion(banner)
   appendTextWithTag("  Production for the #{banner} kingdom as of turn #{$currentTurn}\n\n",TEXT_TAG_TITLE)
   appendTextWithTag("  Region            Food              Gold\n",TEXT_TAG_HEADING)
   appendTextWithTag(" ----------   ---------------- ----------------\n",TEXT_TAG_HEADING)
   (1..12).each do |region|
      (food,gold) = $popCenterList.getCurrentProductionByRegionAndKingdom(region, banner)
      next if food.to_i == 0 and gold.to_i == 0
      line = sprintf("    %2d          %8d            %7d\n", region, food, gold)
      appendText(line)
   end
end

def showEmissaryInfoFor(banner)
   emList = $emissaryList.getEmissaryByKingdom(banner)
   appendTextWithTag("Last Known Wherabouts of the #{banner} Emissaries\n\n", TEXT_TAG_TITLE)
   $emissaryList.showEmHeader
   emList.each do |emissary|
      turn= emissary.getLastTurn 
      line = emissary.toString( turn )
      if turn == $currentTurn
         appendText(line)
      else
         appendTextWithTag(line,TEXT_TAG_STALE)
      end
   end
end

# TODO
def showGroupInfoFor(banner)
   grList = $groupList.getGroupsByKingdom(banner)
   appendTextWithTag("Last Known Wherabouts of the #{banner} Groups\n\n", TEXT_TAG_TITLE)
   $groupList.showArmyHeader
   grList.each do |group|
      turn= group.getLastTurn 
      line = group.toString( turn )
      if turn == $currentTurn
         appendText(line)
      else
         appendTextWithTag(line,TEXT_TAG_STALE)
      end
   end
end
# 
def showPopsOfKingdom(banner, myTurn)
   pcList = nil
   if myTurn == nil 
      appendTextWithTag("Last known information on population centers the #{banner} kingdom owns or has owned.\n",TEXT_TAG_TITLE)
      pcList = $popCenterList.getByLatestKingdom(banner)
   else
      appendTextWithTag("The #{banner} kingdom has these population centers on turn #{myTurn}\n",TEXT_TAG_TITLE)
      pcList = $popCenterList.getByKingdomAndTurn(banner, myTurn)
   end
   $popCenterList.printHeader 
   pcList.each do |popCenter|
      if myTurn == nil 
         turn = popCenter.getLatestTurn
      else
         turn = myTurn
      end
      line = popCenter.toString(turn)
      if turn == $currentTurn
        appendText(line)
      else
        appendTextWithTag(line, TEXT_TAG_STALE)
      end
   end
#  appendText("\n\n")
#  showScaryRoyals(banner,$currentTurn)
end



def findEmissaryAreas(banner, name)
   emissary = $emissaryList.getEmissaryByID("#{banner}-#{name}")
   return emissary.getAreaList
end

def findArmyAreas(banner, name)
   group = $groupList.getGroupByID("#{banner}-#{name}")
   return group.getAreaList
end

def updateLB(listbox,values)
  listbox.delete(0,'end')
  values.keys.sort.each do |value|
     next if value == nil or value.empty?
     listbox.insert('end',value)
  end
end

# For the kingdom, emissary, and army group lists, 
# Update the list box contents
def updateFilterLists
  updateLB($klb,$kingdoms)
  updateLB($elb,$emissaries)
  updateLB($alb,$armies)
end

# go through the list of pop centers.
# if the pop center is not in this list,
# and the last known owner is me, set it neutral
def checkPopCenterOwners(line)
   return if line.nil?
   (turn,x,banner,ownedList)=line.chomp.split(',',4)
   switchKingdoms(banner)
   $popCenterList.checkOwners(ownedList) 
end

# [@turnNumber,"I",@gameNumber,@banner].join(',')
def addInfoData(line)
   isAnOtherGame = false
   (turn,x,gameNumber,banner,influence)=line.split(',')
   $gameNumber = gameNumber if( $gameNumber == nil )
   if ($gameNumber != gameNumber )
      appendTextWithTag("WARNING! This file appears to be from game #{gameNumber} instead of #{$gameNumber}\n",
                         TEXT_TAG_WARNING) 
      isAnOtherGame = true
   end

   banner.strip!
   switchKingdoms(banner,true) if $myKingdom != banner
   #$myKingdom = banner if( $myKingdom == nil )
#  if( $myKingdom != banner )
#     appendTextWithTag("WARNING! This file contains data from the #{banner} turn instead of #{$myKingdom}\n",
#                        TEXT_TAG_WARNING) 
#     isAnOtherKingdom = true 
#  end

   unless isAnOtherGame
      $influence[turn.to_i] = Hash.new if $influence[turn.to_i].nil?
      $influence[turn.to_i][$myKingdom]=influence
      $infoData.push line
   end

   return isAnOtherGame
end

def addUnusualSighting(line)
   us = $unusualSightings.addUS(line)
   addMapMarker(us.getLocation,EXPLORED_MARKER_US)
end

# [@turnNumber,"P",p['source'],area,p['banner'],p['name'],p['type'],p['defense'],p['census'],p['food'],p['gold'],p['other']].join(',')
def addPopCenter(line)
 pop = $popCenterList.addPopCenter(line)

 (turn,x,source,area,banner,name,region,type,defense,census,food,gold,other)=line.split(',')
 #addColoredMapMarker(pop.getArea, pop.getType[0], banner)
 
 $kingdoms[banner]=1

 $areaList.addtag(area,"banner-#{banner}")
 $turns[turn]=1
end

#[@turnNumber,"R",'Self',r[:name],regionNum,r[:reaction],r[:controller]].join(',')
def addRegion(line)
   (turn,x,x,name,num,reaction,controller,refBanner)=line.chomp.split(',')
   $regionList.addTurn(turn,num,reaction,controller,refBanner)
end

def addHighCouncil(line)
   $highCouncilList.addIssue(line)
end

def addBattle(line)
   $passThroughRecords.push line
   $battleList.addBattle(line)
end

#@turnNumber,"A",artifact[:source],artifact[:area],artifact[:fullName],artifact[:shortName],
#                                artifact[:posessor],artifact[:type],artifact[:statusPts]].join(',')
def addArtifact(line)
   $artifactList.addArtifact(line)
end

# TODO 
def markExplored(tag)
   appendText("Marking #{tag} as explored \n")
end

def addExploredAreas(line)
   (turn,x,areaList)=line.strip.split(',',3)
   return if areaList == nil or areaList.size == 0
   areaList.split(',').each do |area|
      $exploredAreas.push area.strip
      addMapMarker(area,EXPLORED_MARKER_NOPC)
   end
end

def addNoUSAreas(line)
#  appendText("line=[#{line}]\n")
   (turn,x,areaList)=line.strip.split(',',3)
   return if areaList == nil or areaList.size == 0
#  appendText("areaList=[#{areaList}]\n")
   areaList.split(',').each do |area|
#     appendText("area=[#{area}]\n")
      $noUSAreas.push area.strip
      addMapMarker(area,EXPLORED_MARKER_NOUS)
   end
end

def addAllClearAreas(line)
   (turn,x,areaList)=line.strip.split(',',3)
   return if areaList == nil or areaList.size == 0
   areaList.split(',').each do |area|
      $allClearAreas.push area.strip
      addMapMarker(area,EXPLORED_MARKER_ALLCLEAR)
   end
end


# [@turnNumber,"P",p['source'],area,p['banner'],p['name'],p['type'],p['defense'],p['census'],p['food'],p['gold'],p['other']].join(',')
def addEmissary(line)
 
 $emissaryList.addEmissary(line)

 (turn,x,source,area,banner,name,rank)=line.split(',')

 $kingdoms[banner]=1
 nameTag="#{banner}-#{name}"
 $emissaries[nameTag]=banner
 $areaList.addtag(area,nameTag)
 $areaList.addtag(area,"banner-#{banner}")
 #@MAP[area].addtag(nameTag)
end

# Turn,Record Type,Data Source,Map Location,Kingdom,Name,size,archers,foot,horse,leader1,leader2,leader3,wizard1,wizard2,wizard3
def addArmyGroup(line)
 $groupList.addGroup(line)
 (turn,x,source,area,banner,name,region,size,archers,foot,horse,l1,l2,l3,w1,w2,w3)=line.split(',')
 $kingdoms[banner]=1
 $armies[name]=banner
 $areaList.addtag(area,"banner-#{banner}")
 $areaList.addtag(area,name)
 #addMapMarker(area,name)
end

def showRegionalLeaders
   appendTextWithTag("\n\nWho has the most regions?\n",TEXT_TAG_TITLE)
   leaders=Array.new
   $kingdomNameMap.keys.each do |banner|
      next if banner == 'XX'
      count = $regionList.getNumControlled(banner)
      next if count == 0
      line=sprintf("%9d  %s\n", count, $kingdomNameMap[banner])
      leaders.push line
   end
   leaders.sort.reverse.each do |line|
      appendText(line)
   end
end

def showEmHeader
   $emissaryList.showEmHeader
   #appendText("Trn Source  Area KI          Name               Rank\n")
   #appendText("--- ------- ---- -- ------------------------- ---------\n")
end

def showUnusualSightings(area,showHeader)
   if showHeader == true
      appendTextWithTag("\nUnusual Sightings? :\n", TEXT_TAG_TITLE)
   end

   us=$unusualSightings.getUS(area)
   if us.nil?
      appendText("\nSorry")
   else
      appendText("\nYES, there is an Unusual Sighting here!\n")
      appendText("Difficulty:  #{us.getDifficulty}\n")
      appendText("Description:  #{us.getDescription}\n")
   end

end

def showEmissary(area,target,showHeader,targetTurn)

   outputLines=false

   emNameList = $areaList.getEmissaryList(area)
   return if emNameList == nil

   if showHeader == true
      appendTextWithTag("\nEmissaries Present:\n", TEXT_TAG_TITLE)
      showEmHeader
   end

   # print all the emissary info
   emNameList.each do | emissaryID|


      (id, emissaryName)=emissaryID.split('-',2)
      # if wa want a specific emissary, skip all the others
      if target != nil
         next unless emissaryName == target
      end
      emissary = $emissaryList.getEmissaryByID(emissaryID)

      # Get turn list from Emissary based on HISTORY choice
      turnList = [$currentTurn] 
      turnList = emissary.getTurns unless $history.value.to_i == HISTORY_CURRENT
      turns = turnList.sort_by(&:to_i)
      turns.reverse_each do |turn|
      #turns.each do |turn|
         next unless targetTurn == nil or targetTurn == turn
         next unless emissary.getLocOnTurn(turn) == area
         line = emissary.toString(turn)
         if turn == $currentTurn
            appendText( line )
         else
            appendTextWithTag( line , TEXT_TAG_STALE)
         end
         outputLines=true
         break if $history.value.to_i == HISTORY_LATEST
      end # each turn in reverse

   end # end for each emissary
   return outputLines
end

def showBattleReport(area, showHeader)
   if showHeader == true
      appendTextWithTag("\nBattles That Occurred Here:\n", TEXT_TAG_TITLE)
      $battleList.showBattleHeader
   end

   $battleList.showBattles(area)

end

def showArmyHeader
   $groupList.showArmyHeader
#  appendText("Trn Source  Area KI Name Size        Archer  Foot  Horse         Leaders           Wizards\n")
#  appendText("--- ------- ---- -- ---- ----------- ------ ------ ------ -------------------- --------------------\n")
end

def showArmyGroup(area, target, showHeader, targetTurn)
    
   outputLines = false

   groupNameList = $areaList.getGroupList(area)
   return if groupNameList == nil

   if showHeader == true
      appendTextWithTag("\nArmy Groups Present:\n", TEXT_TAG_TITLE)
      showArmyHeader
   end

   # print all the group info
   groupNameList.each do | groupID |
      (id, groupName)=groupID.split('-',2)
      # if wa want a specific group, skip all the others
      if target != nil
         next unless groupName == target
      end
      group = $groupList.getGroupByID(groupID)

      # Get turn list from Emissary based on HISTORY choice
      turnList = [$currentTurn]
      turnList = group.getTurns unless $history.value.to_i == HISTORY_CURRENT
      turns = turnList.sort_by(&:to_i)
      turns.reverse_each do |turn|
      #turns.each do |turn|
         next unless targetTurn == nil or targetTurn == turn
         next unless group.getLocOnTurn(turn) == area
         line = group.toString(turn)
         if turn == $currentTurn
            appendText( line )
         else
            appendTextWithTag( line , TEXT_TAG_STALE)
         end
         outputLines = true
         break if $history.value.to_i == HISTORY_LATEST
      end # each turn in reverse

   end # end for each emissary

   return outputLines 

end # end showArmyGroup

def showPopCenterData(area,turn)
      p=$popCenterList.getPopCenter(area)
      if p == nil 
         return
      end
      turn = p.getLatestTurn if turn == nil
      line = p.toString(turn)
      if turn == $currentTurn
         appendText( line )
      else
         appendTextWithTag( line , TEXT_TAG_STALE)
      end

      ### TODO
      EmmyToolWindow.new($influence.last[$myKingdom], area)
      #regionNum=p.getRegion
      #region=$regionList.getRegionByNum(regionNum)
      #return if region.nil?
      #react=region.getLatestReaction
      #$emmyTool=EmmyTool.new(p.getType,$influence.last,react, p.getArea, p.getName, region)
      #val=$emmyTool.getNeutralScore
      #appendText("Neutral Score = #{val}\n")
      #(one,two)=$emmyTool.getChances("COUNT")
      #appendText("Count: oneStep = #{one}  twoSteps = #{two}\n")
      ### TODO
end

def showPopCenter(area,showHeader)
   $popCenterList.printHeader if showHeader
   case $history.value.to_i
   when HISTORY_ALL
      ('0'..$currentTurn).each do |turn|
         showPopCenterData(area,turn)
      end
   when HISTORY_LATEST
      showPopCenterData(area,nil)
   when HISTORY_CURRENT
      showPopCenterData(area,$currentTurn)
   end
end

def showHighCouncilRecords
   clearText
   $highCouncilList.printRecords
end

def showProductionStatsByKingdom
   clearText
   unHighlight
   appendTextWithTag("\nProduction Stats by Kingdom:\n", TEXT_TAG_TITLE)
   line=sprintf("%-25s %10s %10s\n", "Kingdom Name", "Food", "Gold")
   appendText(line)
   appendText("------------------------  ---------- ----------\n")
   $kingdomNameMap.keys.sort.each do |banner|
      (food,gold) = $popCenterList.getCurrentProductionByRegionAndKingdom(nil, banner)
      line=sprintf("%-25s %10s %10s\n", $kingdomNameMap[banner], food, gold)
      appendTextWithTag(line,banner)
   end
end

def showProductionStatsByRegion
   appendTextWithTag("\nProduction Stats by Region:\n", TEXT_TAG_TITLE)
   line=sprintf("%-25s %10s %10s\n", "Region Name", "Food", "Gold")
   appendTextWithTag(line,TEXT_TAG_HEADING)
   appendTextWithTag("------------------------  ---------- ----------\n",TEXT_TAG_HEADING)
   $regionMap.keys.sort_by(&:to_i).each do |region|
      next if region < 1
      #pcList = $popCenterList.getByRegion(region)
      (food,gold) = $popCenterList.getCurrentProductionByRegionAndKingdom(region, nil)
      line=sprintf("%-25s %10s %10s\n", $regionMap[region], food, gold)
      appendText(line)
   end   
   showPopCentersByRegion
end

def showPopCentersByRegion
   clearText
   unHighlight
   appendTextWithTag("\nPopulation Centers by Region:\n", TEXT_TAG_TITLE)
   $regionMap.keys.sort_by(&:to_i).each do |region|
      #next if region == ' ' or region == 'X';
      next if region.to_i < 1
      controller=$regionList.getLatestController(region)
      appendTextWithTag("\n\n#{$regionMap[region]} Controlled by #{controller}\n",TEXT_TAG_HEADING)
      $popCenterList.printHeader
      pcList = $popCenterList.getByRegion(region)
      pcList.each do |pc|
         line=pc.toString( pc.getLatestTurn)
         appendTextWithTag(line, pc.getLastKnownOwner)
      end
   end   
end

def loadDocument(filename)

  # Start off assuming the file is for this kingdom
  # The return code from addInfoData may change that.
  isAnOtherKingdom = false 
  currentOwnersLine=Array.new

  appendText("Loading data from #{filename}\n")
  IO.foreach(filename) { |line|
     appendTextWithTag("Data file contains warnings.\n",TEXT_TAG_WARNING) if line.match(/WARNING/)
     next if !line.match(/^\d+/)
#     appendText(line)
     (turn,recordType,rest)=line.split(',',3)
     case recordType
     when 'I'
        isAnOtherKingdom = addInfoData(line)
     when 'P'
        addPopCenter(line)
     when 'E'
        addEmissary(line)
     when 'G'
        addArmyGroup(line)
     when 'A'
        addArtifact(line)
     when 'R'
        addRegion(line) 
     when 'H'
        addHighCouncil(line) 
     when 'B'
        addBattle(line) 
     when 'O'
        # We cannot process this line yet because $currentTurn 
        # has not been increased yet. Save for later.
        currentOwnersLine.push line  
     when EXPLORED_MARKER_NOPC
        addExploredAreas(line)
     when EXPLORED_MARKER_NOUS
        addNoUSAreas(line)
     when EXPLORED_MARKER_ALLCLEAR
        addAllClearAreas(line)
     when EXPLORED_MARKER_US
        addUnusualSighting(line)
     else
        appendTextWithTag("Unknown record type=#{recordType}\n", TEXT_TAG_DANGER)
     end
  }
  updateFilterLists
  setInfoLabel
  fixRegions(true)
  $popCenterList.addMarkers
  $regionList.gatherStats
  #playSound
  $currentTurn= $turns.keys.sort_by(&:to_i).last
  appendText("\nCurrent turn is #{$currentTurn}\n")
  currentOwnersLine.each do |oline|
     checkPopCenterOwners(oline) 
  end
  hideExplored
  hideGroups
  hideBattles
  showGroups
  showBattles
  $canvas.raise($currentTopTag)
end

def switchKingdoms(newBanner, quiet=false)
  appendText("Switching kingdoms to #{newBanner}\n") unless quiet
  $emmyDialog.destroy if TkWinfo.exist?($emmyDialog)
  $emmyDialog = nil
  $myKingdom = newBanner
  setInfoLabel
end

def openDocument
  clearText
  filetypes = [ ["Parser Data Files", "*.dat"],["All Files", "*"] ]
  filename = Tk.getOpenFile('filetypes' => filetypes,
                            'parent' => $root )
  if filename != ""
    loadDocument(filename)
    $currentOpenFile=filename
  end
end

def runParser(filename,format=AlamazeTurnParser::FORMAT_HTML)
   begin
      tempFile = "ofile.dat"
      File.delete(tempFile) if File.exists?(tempFile)
      #cmd="ruby parse1.rb #{filename} > #{tempFile}"
      appendText("Attempting to parse #{filename}\n")
   
      ofile = File.new(tempFile, File::CREAT|File::TRUNC|File::RDWR)
      if ofile == nil or File.writable?(tempFile) == false
         appendTextWithTag("Failure opening #{tempFile} for writing. Parsing FAILED!\n", TEXT_TAG_DANGER)
         return
      end
   
      parser = AlamazeTurnParser.new
      if( format == AlamazeTurnParser::FORMAT_PDF) 
         appendText("Processing PDF file\n")
         parser.setFormat(AlamazeTurnParser::FORMAT_PDF)
         pdf = PDF::Reader.file(filename,parser)
      else
         appendText("Processing HTML file\n")
         parser.setFormat(AlamazeTurnParser::FORMAT_HTML)
         IO.foreach(filename) do |line|
            parser.show_html(line)
         end
      end
      parser.showInfoRecord(ofile)
      parser.showPopInfo(ofile)
      parser.showEmissaryInfo(ofile)
      parser.showArmies(ofile)
      parser.showArtifactInfo(ofile)
      parser.showRegionalInfo(ofile)
      parser.showOwnedPopCenters(ofile)
      parser.showHCInfo(ofile)
      parser.showBattles(ofile)
      ofile.close
   rescue Exception => e
         appendText("Caught Exception.\n")
         appendText("#{e.inspect}.\n")
         appendText("\nBacktrace:.\n")
         appendText("#{e.backtrace}.\n")
   end # end rescue


   loadDocument(tempFile)
end # end runParser

# When a file name or path has a blank in it,
# each file is surrounded in curly braces.
def splitFileNames(nameString)
   goodNames=nil

   if nameString[0] == '{'

      goodNames=Array.new
      nameArray=nameString.gsub(' {','').tr('{',' ').split('}')

      nameArray.each do |drivelessName|
#        appendText("name=[#{drivelessName}]\n")
         next if drivelessName.strip.empty?
         goodNames.push drivelessName.strip
      end
   else
      goodNames=nameString.split
   end

   return goodNames
end

def parseTurn
  filetypes = [ ["Alamaze Turn Results", "*.PDF *.html"],["All Files", "*"] ]
  filenameString = Tk.getOpenFile('filetypes' => filetypes,
                            'initialdir' => $resultsDir,
                            'multiple' => true,
                            'parent' => $root )

  clearText
  appendText("File list to process [#{filenameString}]\n")
  filenames=splitFileNames(filenameString)
  filenames.human_sort.each do |filename|
     next if filename.strip.empty?
     if filename.upcase.include? "PDF" 
        format = AlamazeTurnParser::FORMAT_PDF
     else
        format = AlamazeTurnParser::FORMAT_HTML
     end
   
     if filename != ""
       $resultsDir=File.dirname(filename)
       runParser(filename,format)
     end
     Tk.update_idletasks
  end
end

def saveDocument(filename)
   appendText("Saving data to #{filename}\n")
   ofile = File.new(filename, File::CREAT|File::TRUNC|File::RDWR)
   if ofile == nil or File.writable?(filename) == false
      appendTextWithTag("Failure opening #{filename} for writing. Nothing saved!\n", TEXT_TAG_DANGER)
      return
   end

   ofile.puts "saving data"


   # Save the population information in the same format 
   # that it was read out (ie, generated by the parser)
   
   ofile.puts $infoData
   $popCenterList.saveDataToFile(ofile)
   $emissaryList.saveDataToFile(ofile)
   $groupList.saveDataToFile(ofile)
   $artifactList.saveDataToFile(ofile)
   $regionList.saveDataToFile(ofile)
   $unusualSightings.saveDataToFile(ofile)
   $highCouncilList.saveDataToFile(ofile)

   $passThroughRecords.each do |line|
      ofile.puts line
   end

   record = [$currentTurn, EXPLORED_MARKER_NOPC, $exploredAreas].join(',')
   ofile.puts record

   record = [$currentTurn, EXPLORED_MARKER_NOUS, $noUSAreas].join(',')
   ofile.puts record

   record = [$currentTurn, EXPLORED_MARKER_ALLCLEAR, $allClearAreas].join(',')
   ofile.puts record

   ofile.close
   $currentOpenFile = filename
end

def saveData
   if $currentOpenFile == nil
      saveAsData
   else
      saveDocument($currentOpenFile)
   end
end

def saveAsData
  filetypes = [ ["Parser Data Files", "*.dat"],["All Files", "*"] ]
  filename = Tk.getSaveFile('filetypes' => filetypes,
                            'parent' => $root )
  if filename != ""
    filename += ".dat" unless filename.match(/\.dat$/)
    saveDocument(filename)
  end
end

def appendTextWithTag(string,tag,tb=nil)
   createTextWindow
   tb=$textBox if tb.nil?
   tb.insert('end',string, tag)
end

def appendText(string,tb=nil)
   tb=$textBox if tb.nil?
   appendTextWithTag(string,TEXT_TAG_NORMAL,tb)
end

def clearText(tb=nil)
   createTextWindow
   tb=$textBox if tb.nil?
   tb.delete(1.0,'end')
end

def getCenter(loc, size=:small)
   return if loc == nil or loc.empty?
   yPart = loc[0].ord - 'A'.ord
   xPart = loc[1].ord - 'A'.ord
   #size = :small
   x = $offsets[size][:frameX] + ($offsets[size][:boxX]*xPart) + $offsets[size][:boxX]/2.0
   y = $offsets[size][:frameY] + ($offsets[size][:boxY]*yPart) + $offsets[size][:boxY]/2.0
   return [x,y]
end


def addSizedMarker(size,x,y,marker,markerText,loc,banner)

   x = $offsets[size][:frameX] + ($offsets[size][:boxX]*x) + $offsets[size][:boxX]/2.0
   y = $offsets[size][:frameY] + ($offsets[size][:boxY]*y) + $offsets[size][:boxY]/2.0

   banner = "unknown" if $kingdomBitmaps[banner] == nil
   color = $kingdomColors[banner]
   color = 'black' if color == nil
   

   if marker == "C" 
      m = TkcImage.new($canvas,x,y, 'image' => $kingdomBitmaps[banner][marker][size] , :tags => [marker,loc,'Marker', $offsets[size][:tag] ])
   elsif marker == "A"
      (m,t) = drawAnArmy(size,x,y,markerText,color)
   elsif marker == "V"
      (m,t) = drawAVillage(size,x,y,markerText,color)
   elsif marker == "T"
      (m,t) = drawATown(size,x,y,markerText,color)
   elsif marker == "B"
      m = $battleList.drawBattle(size,x,y,loc)
   elsif marker == EXPLORED_MARKER_NOPC
      m = drawNoPC(size,x,y,loc)
   elsif marker == EXPLORED_MARKER_NOUS
      m = drawNoUS(size,x,y,loc)
   elsif marker == EXPLORED_MARKER_ALLCLEAR
      m = drawAllClear(size,x,y,loc)
   elsif marker == EXPLORED_MARKER_US
      m = $unusualSightings.drawUnusualSighting(size,x,y,loc)
   elsif marker == EXPLORED_MARKER_TEMP
      m = drawTempMarker(size,x,y,loc)
   else
      m = TkcText.new($canvas, x, y, 'text' => markerText, 'tags' => [marker,loc,'Marker', $offsets[size][:tag] ],
                      'fill' => color, 'font' => $offsets[size][:font] )
   end

   m.bind('1', proc { boxClick loc } )
   m.bind('3', proc { |x,y| rightClickMarker(x,y,loc,marker) }, "%X %Y" )
   m.bind('Enter', proc { $cursorLoc.value = loc } )
   
   unless t.nil?
      t.bind('1', proc { boxClick loc } ) 
      t.bind('3', proc { |x,y| rightClickMarker(x,y,loc,marker) }, "%X %Y" ) 
      t.bind('Enter', proc { $cursorLoc.value = loc } )
   end
end


def addMapMarker(loc,marker)
   return if loc == nil or loc.empty?
   addColoredMapMarker(loc,marker,'black')
end

def addColoredMapMarker(loc,marker,banner, markerText="")
   return if loc == nil or loc.size != 2
   yPart = loc[0].ord - 'A'.ord
   xPart = loc[1].ord - 'A'.ord
   addSizedMarker(:big, xPart, yPart, marker,markerText,loc,banner)
   addSizedMarker(:medium, xPart, yPart, marker,markerText,loc,banner)
   addSizedMarker(:small, xPart, yPart, marker,markerText,loc,banner)
end


def drawLine(start,stop,color,width)
   return if start == nil or stop == nil
   (turn,startArea)=start.split('-')
   (turn,stopArea)=stop.split('-')
   return if startArea == nil or stopArea == nil
   (x1,y1)=getCenter(startArea)
   (x2,y2)=getCenter(stopArea)
   line = TkcLine.new($canvas,x1,y1,x2,y2,
                      'arrow' => 'last',
                      'fill' => color,
                      'width' => width,
                      'tags' => 'line')
end

def drawLines(banner, name, areaList, color, width)
   for x in 1..areaList.size 
      drawLine( areaList[x-1], areaList[x], color, width)
   end
end

# Clicking on a box on the map gives you 
# the location on the Alamaze map.
# You can use that to either access the box object
# which is stored in @MAP or access the data from
# the parsed results for that location
def boxClick(loc)
   clearText
   loc.gsub!("box-","") if loc.include? "box"
   appendTextWithTag("Area #{loc}\n\n",TEXT_TAG_TITLE)
   #@MAP[loc].configure( 'fill' => 'red')
   showPopCenter(loc, true)
   showEmissary(loc, nil, true, nil)
   showArmyGroup(loc, nil, true, nil)
   showBattleReport(loc,true)
   showUnusualSightings(loc,true)
   $textBox.focus

end

def changeKingdom(entry)
   text = entry.get.strip.upcase
   appendText("So you want to be the #{text}\n")
   $menuDialog.destroy if TkWinfo.exist?($menuDialog)
   if $kingdomNameMap[text] == nil
      Tk::messageBox :message => "#{text} is not a valid kingdom name"
      return
   end

   switchKingdoms(text)
end

def enterNewOwner(entry, area)
   text = entry.get.strip.upcase
   appendText("entered #{text} for #{area}\n")
   $menuDialog.destroy if TkWinfo.exist?($menuDialog)
   if $kingdomNameMap[text] == nil
      Tk::messageBox :message => "#{text} is not a valid kingdom name"
      return
   end
   $popCenterList.changeOwner(area,text)
   $canvas.raise($currentTopTag)
end

def editUnusualSighting(area)
   $unusualSightings.drawEditDialog(area)
end

def deleteUSMarker(area)
   us = $unusualSightings.getUS(area)
   if us == nil 
      Tk::messageBox :message => "There is no Unusual Sighting center at area  #{area}"
      return
   end
   $unusualSightings.deleteUS(area)
   $canvas.raise($currentTopTag)
end

def destroyPC(area)
   pc = $popCenterList.getPopCenter(area)
   if pc == nil 
      Tk::messageBox :message => "There is no population center at area  #{area}"
      return
   end
   $popCenterList.destroyPC(area)
   $canvas.raise($currentTopTag)
end

def changeMainKingdomDialog

   unHighlight
   $menuDialog.destroy if TkWinfo.exist?($menuDialog)
   $menuDialog = TkToplevel.new($root) do
      title "Change Kingdom"
   end
   frame = TkFrame.new($menuDialog) do
      relief 'sunken'
      borderwidth 3
      background 'darkgrey'
      padx 10
      pady 10
   end

   TkLabel.new(frame) do
      text 'Who do you want to be today?: '
      pack('side'=>'left')
   end

   entry = TkEntry.new(frame) do
      width '10'
      pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
   end
   entry.insert('end', $myKingdom )
   entry.bind('Return', proc { changeKingdom(entry) } )
   frame.pack

end


def changePCOwner(area)
   pc = $popCenterList.getPopCenter(area)
   if pc == nil 
      Tk::messageBox :message => "There is no population center at area  #{area}"
      return
   end

   pcName = $popCenterList.getPopCenter(area).getName
   owner =  $popCenterList.getPopCenter(area).getLastKnownOwner

   unHighlight
   $menuDialog.destroy if TkWinfo.exist?($menuDialog)
   $menuDialog = TkToplevel.new($root) do
      title "Changing Owner of #{pcName}"
   end
   frame = TkFrame.new($menuDialog) do
      relief 'sunken'
      borderwidth 3
      background 'darkgrey'
      padx 10
      pady 10
   end

   TkLabel.new(frame) do
      text 'Enter New Owner: '
      pack('side'=>'left')
   end

   entry = TkEntry.new(frame) do
      width '10'
      pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
   end
   entry.insert('end', owner)
   entry.bind('Return', proc { enterNewOwner(entry,area) } )
   frame.pack

end

def deleteNoPCMarker(area)
      $exploredAreas.delete(area.strip)
      uniqueTag="NoPC-#{area}"
      $canvas.delete(uniqueTag)
end

def deleteNoUSMarker(area)
      $noUSAreas.delete(area.strip)
      uniqueTag="NoUS-#{area}"
      $canvas.delete(uniqueTag)
end

def deleteAllClearMarker(area)
      $allClearAreas.delete(area.strip)
      uniqueTag="AllClear-#{area}"
      $canvas.delete(uniqueTag)
end

def deleteTempMarker(area)
      uniqueTag="Temp-#{area}"
      $canvas.delete(uniqueTag)
end

def rightClickMarker(x,y,area,marker)
   pm = TkMenu.new do
     title 'Actions'
     type  'normal' 
   end
   if marker == 'C' or marker == 'T' or marker == 'V'
      pm.add('command',
             'label'     => "Change PC Owner...",
             'command'   => proc { changePCOwner area}
             )
      pm.add('command',
             'label'     => "Destroy PC",
             'command'   => proc { destroyPC area}
             )
   elsif marker == EXPLORED_MARKER_US
      pm.add('command',
             'label'     => "Edit Unusual Sighting",
             'command'   => proc { editUnusualSighting area}
             )
      pm.add('command',
             'label'     => "Delete Unusual Sighting",
             'command'   => proc { deleteUSMarker area}
             )
   elsif marker == EXPLORED_MARKER_NOPC
      pm.add('command',
             'label'     => "Delete Exploration Marker",
             'command'   => proc { deleteNoPCMarker area}
             )
   elsif marker == EXPLORED_MARKER_NOUS
      pm.add('command',
             'label'     => "Delete Exploration Marker",
             'command'   => proc { deleteNoUSMarker area}
             )
   elsif marker == EXPLORED_MARKER_ALLCLEAR
      pm.add('command',
             'label'     => "Delete Exploration Marker",
             'command'   => proc { deleteAllClearMarker area}
             )
   elsif marker == EXPLORED_MARKER_TEMP
      pm.add('command',
             'label'     => "Delete Temp Marker",
             'command'   => proc { deleteTempMarker area}
             )
   end
   pm.post(x.to_i,y.to_i)
end

def setupMenus(root)

   menu_bar = TkMenu.new
   file_menu = TkMenu.new(root)
   
   file_menu.add('command',
                 'label'     => "New...",
                 'command'   => proc { closeFile },
                 'underline' => 0)
   file_menu.add('command',
                 'label'     => "Open...",
                 'command'   => proc { openDocument },
                 'underline' => 0)
   file_menu.add('command',
                 'label'     => "Close",
                 'command'   => proc { closeFile },
                 'underline' => 0)
   file_menu.add('separator')
   file_menu.add('command',
                 'label'     => "Save",
                 'command'   => proc { saveData },
                 'underline' => 0)
   file_menu.add('command',
                 'label'     => "Save As...",
                 'command'   => proc { saveAsData },
                 'underline' => 5)
   file_menu.add('separator')
   file_menu.add('command',
                 'label'     => "Parse...",
                 'command'   => proc { parseTurn },
                 'underline' => 0)
   file_menu.add('separator')
   file_menu.add('command',
                 'label'     => "Exit",
                 'command'   => proc { exit 0} ,
                 'underline' => 3)
   
   menu_bar.add('cascade',
                'menu'  => file_menu,
                'label' => "File")
   
   map_menu = TkMenu.new(root)
   map_menu.add('command',
                 'label'     => "Zoom In Big",
                 'command'   => proc { zoomInBig },
                 'underline' => 5)
   
   map_menu.add('command',
                 'label'     => "Zoom In Medium",
                 'command'   => proc { zoomInMedium },
                 'underline' => 5)
   
   map_menu.add('command',
                 'label'     => "Zoom Out",
                 'command'   => proc { zoomOut },
                 'underline' => 5)
   
   map_menu.add('command',
                 'label'     => "Mark Explored...",
                 'command'   => proc { createAddExploredDialog },
                 'underline' => 6)
   
   map_menu.add('command',
                 'label'     => "Manual Entry...",
                 'command'   => proc { startManualEntryDialog },
                 'underline' => 0)
   
   map_menu.add('command',
                 'label'     => "Group Movement Plotter...",
                 'command'   => proc { startGroupMovementPlotter },
                 'underline' => 15)
   
#  map_menu.add('command',
#                'label'     => "Fix Regions",
#                'command'   => proc { fixRegions },
#                'underline' => 0)
   
   map_menu.add('command',
                 'label'     => "Toggle Explored",
                 'command'   => proc { toggleExplored },
                 'underline' => 7)
   
   map_menu.add('command',
                 'label'     => "Toggle Groups",
                 'command'   => proc { toggleGroups },
                 'underline' => 7)
   
   map_menu.add('command',
                 'label'     => "Toggle Battles",
                 'command'   => proc { toggleBattles },
                 'underline' => 7)
   
   map_menu.add('command',
                 'label'     => "Change Kingdom",
                 'command'   => proc { changeMainKingdomDialog },
                 'underline' => 0)
   
   menu_bar.add('cascade',
                'menu'  => map_menu,
                'label' => "Map")

   report_menu = TkMenu.new(root)
   report_menu.add('command',
                   'label'     => "Region Stats",
                   'command'   => proc { $regionList.showAllStats },
                   'underline' => 0)

   report_menu.add('command',
                   'label'     => "All Groups",
                   'command'   => proc { $groupList.showAllGroups },
                   'underline' => 4)

   report_menu.add('command',
                   'label'     => "All Artifacts",
                   'command'   => proc { showAllArtifacts },
                   'underline' => 0)

   report_menu.add('command',
                   'label'     => "Production By Kingdom",
                   'command'   => proc { showProductionStatsByKingdom },
                   'underline' => 14)

   report_menu.add('command',
                   'label'     => "PopCenters By Region",
                   'command'   => proc { showPopCentersByRegion },
                   'underline' => 0)

   report_menu.add('command',
                   'label'     => "All Battles",
                   'command'   => proc { $battleList.showAllBattles },
                   'underline' => 4)

   report_menu.add('command',
                   'label'     => "Threatened Production",
                   'command'   => proc { showMyThreatenedProduction },
                   'underline' => 0)

   report_menu.add('command',
                   'label'     => "Lost/Gained PopCenters",
                   'command'   => proc { showPopCenterChanges },
                   'underline' => 12)

   report_menu.add('command',
                   'label'     => "Lost/Hired Emissaries",
                   'command'   => proc { showEmissaryChanges },
                   'underline' => 11)

   report_menu.add('command',
                   'label'     => "High Council Records",
                   'command'   => proc { showHighCouncilRecords },
                   'underline' => 0)



   menu_bar.add('cascade',
                'menu'  => report_menu,
                'label' => "Reports")
   
   root.menu(menu_bar)
end

def drawBox(canvas,x,y,tag)
   bBox = drawABlock(:big, x,y)
   bBox.addtag(I_AM_A_BOX)
   bBox.addtag(tag)
   bBox.bind('1', proc { boxClick tag } )
   bBox.bind('3', proc { markExplored tag } )
   bBox.bind('Enter', proc { $cursorLoc.value = tag.gsub('box','Area') } )

   mBox = drawABlock(:medium, x,y)
   mBox.addtag(I_AM_A_BOX)
   mBox.addtag(tag)
   mBox.bind('1', proc { boxClick tag } )
   mBox.bind('3', proc { markExplored tag } )
   mBox.bind('Enter', proc { $cursorLoc.value = tag.gsub('box','Area') } )

   sBox = drawABlock(:small, x,y)
   sBox.addtag(I_AM_A_BOX)
   sBox.addtag(tag)
   sBox.bind('1', proc { boxClick tag } )
   sBox.bind('3', proc { markExplored tag } )
   sBox.bind('Enter', proc { $cursorLoc.value = tag.gsub('box','Area') } )
   return bBox,sBox
end

def fillGrid
   # creat the 26x26 grid of boxes
   for x in 0..25
     l1=('A'.ord+x).chr
     for y in 0..25
        l2=('A'.ord+y).chr
        loc="#{l2}#{l1}"
        (bBox,sBox)= drawBox($canvas,x,y,"box-#{loc}")
        $areaList.addBox(loc,sBox,bBox)
        #@MAP[loc]= sBox
     end
   end
   $canvas.bind('Leave', proc { $cursorLoc.value = " " } )
end

def chooseEmissary(lb)
   idx = lb.curselection
   clearText
   return if idx == nil or idx.empty?
   selection = lb.get(idx)
   (banner,name)=selection.split('-',2) # some emissaries have dashes in their names!
   unHighlight
   appendTextWithTag("Tracking the movements of  #{name} of the #{banner} kingdom!\n\n",TEXT_TAG_TITLE)
   areaList = findEmissaryAreas(banner, name)
   showEmHeader
   areaList.reverse_each do |areaEntry|
      (turn,area)=areaEntry.split('-')
      highlightTag("box-#{area}", false)
      break if showEmissary(area,name,false,turn) and $history.value.to_i == HISTORY_LATEST
   end
   drawLines(banner, name, areaList, EMISSARY_ARROW_COLOR, EMISSARY_ARROW_WIDTH)
end

def chooseArmy(lb)
   idx = lb.curselection
   clearText
   return if idx == nil or idx.empty?
   selection = lb.get(idx)
   name = selection
   banner=name[1..2]
   appendTextWithTag("Tracking the movements of  #{name} of the #{banner} kingdom!\n\n",TEXT_TAG_TITLE)
   areaList = findArmyAreas(banner, name)
   showArmyHeader
   unHighlight
   areaList.reverse_each do |areaEntry|
      (turn,area)=areaEntry.split('-')
      highlightTag("box-#{area}",false)
      break if showArmyGroup(area,name,false,turn) and $history.value.to_i == HISTORY_LATEST
   end
   drawLines(banner, name, areaList, ARMY_ARROW_COLOR, ARMY_ARROW_WIDTH)
end

def chooseKingdom(lb)
   idx = lb.curselection
   clearText
   #appendText("clicked on #{lb}. idx=#{idx}\n")
   return if idx == nil or idx.empty?
   selection = lb.get(idx)
   #appendText("selected #{selection}\n")
   highlightTag("banner-#{selection}",true)
   hWhen = $history.value
   targetTurn = $currentTurn
   targetTurn = nil if $history.to_i != HISTORY_CURRENT
   #appendText("hist=[#{hWhen}]-[#{HISTORY_CURRENT}]  curTurn=[#{$currentTurn}] targetTurn=[#{targetTurn}]\n")
   appendTextWithTag("#{$kingdomNameMap[selection]}\n\n", TEXT_TAG_TITLE)
   showPopsOfKingdom(selection, targetTurn)
   appendText("\n\n")
   showEmissaryInfoFor(selection)
   appendText("\n\n")
   showGroupInfoFor(selection)
end

def setInfoLabel
  $myGameInfoText.value = "#{$kingdomNameMap[$myKingdom]}          ##{$gameNumber}"
end

def createFilterLists(frame)
    hlab=TkLabel.new(frame) {
             text 'H I G H L I G H T'
             foreground FILTER_LABEL_COLOR
             pack('side'=>'top')
    }
    kFrame = TkFrame.new(frame)
    eFrame = TkFrame.new(frame)
    #aFrame = TkFrame.new(frame)
    aFrame = kFrame
    klab=TkLabel.new(kFrame) {
             text 'Kingdom: '
             foreground FILTER_LABEL_COLOR
             pack('side'=>'left')
    }
    $klb = TkListbox.new(kFrame) {
             selectmode 'single'
             width 3
             height 5 
             pack('side'=>'left')
    }
    $klb.bind('Double-1', proc { chooseKingdom $klb } )
    klbs=TkScrollbar.new(kFrame) {
       command proc { |*args|
          $klb.yview(*args)
       }
       pack('side' => 'left', 'fill' => 'y', 'expand' => 0)
    }
    $klb.yscrollcommand(proc { |first,last|
                             klbs.set(first,last) })

    elab=TkLabel.new(eFrame) {
             text 'Emissary: '
             foreground FILTER_LABEL_COLOR
             pack('side'=>'left')
    }
    $elb = TkListbox.new(eFrame) {
             selectmode 'single'
             width 20
             height 9 
             pack('side'=>'left')
    }
    $elb.bind('Double-1', proc { chooseEmissary $elb } )
    elbs = TkScrollbar.new(eFrame) {
       command proc { |*args|
          $elb.yview(*args)
       }
       pack('side' => 'left', 'fill' => 'y', 'expand' => 0)
    }
    $elb.yscrollcommand(proc { |first,last|
                             elbs.set(first,last) })

    alab=TkLabel.new(aFrame) {
             text 'Army: '
             foreground FILTER_LABEL_COLOR
             pack('side'=>'left')
    }
    $alb = TkListbox.new(aFrame) {
             selectmode 'single'
             width 5
             height 5 
             pack('side'=>'left')
    }
    $alb.bind('Double-1', proc { chooseArmy $alb } )
    albs=TkScrollbar.new(aFrame) {
       command proc { |*args|
          $alb.yview(*args)
       }
       pack('side' => 'left', 'fill' => 'y', 'expand' => 0)
    }
    $alb.yscrollcommand(proc { |first,last|
                             albs.set(first,last) })


   kFrame.pack( 'side' => 'top')
   eFrame.pack( 'side' => 'top')
   aFrame.pack( 'side' => 'top')
end

def createHistoryRadio(frame)
   $history.value = HISTORY_LATEST

   hlab=TkLabel.new(frame) {
             text 'H I S T O R Y'
             foreground FILTER_LABEL_COLOR
             pack('side'=>'top')
   }
   TkRadioButton.new(frame) {
     text 'Show current turn info'
     variable $history
     value HISTORY_CURRENT
     anchor 'w'
     pack('side' => 'top', 'fill' => 'x')
   }
   TkRadioButton.new(frame) {
     text 'Show last known info'
     variable $history
     value HISTORY_LATEST
     anchor 'w'
     pack('side' => 'top', 'fill' => 'x')
   }
   TkRadioButton.new(frame) {
     text 'Show all history'
     variable $history
     value HISTORY_ALL
     anchor 'w'
     pack('side' => 'top', 'fill' => 'x')
   }
end

def createSearchButtons(frame)
# content removed
end # end createSearchButtons

def createSearchParts(frame)
   t = TkLabel.new(frame) do
      text 'F I L T E R S  &  H I G H L I G H T S'
      pack { side 'top' }
   end
   rbFrame = TkFrame.new(frame) do
      relief 'sunken'
      borderwidth 3
   end
   radioFrame = TkFrame.new(rbFrame) do
      relief 'sunken'
      borderwidth 3
   end
   createHistoryRadio(radioFrame)

   buttonFrame = TkFrame.new(rbFrame) do
      relief 'sunken'
      borderwidth 3
   end
   #createSearchButtons(buttonFrame)


   filterFrame = TkFrame.new(frame) do
      relief 'sunken'
      borderwidth 3
   end
   createFilterLists(filterFrame)

   radioFrame.pack('side'=>'left')
   buttonFrame.pack('side'=>'left')
   rbFrame.pack('side'=>'top')
   filterFrame.pack('side'=>'top')
end

def tagText(textBox,pattern,tag)
   start="1.0"
   textBox.mark_set("matchStart",start)
   textBox.mark_set("matchEnd",start)
   textBox.mark_set("searchLimit",'end')
   done = false
   while done == false
      index = textBox.search(pattern, "matchEnd", "searchLimit")
      return  if index == ""
      textBox.mark_set("matchStart", index)
      textBox.mark_set("matchEnd", "#{index} wordend")
      textBox.tag_add(tag,"matchStart", "matchEnd")
   end
end

def hideExplored
  return if $toggles[:explored] == false
  $canvas.delete('NoPC')
  $canvas.delete('NoUS')
  $canvas.delete('AllClear')
  $canvas.delete('Temp')
  $toggles[:explored] = false
  $canvas.raise($currentTopTag)
end

def showExplored
   return if $toggles[:explored] == true
   $exploredAreas.each do |area|
      addMapMarker(area,EXPLORED_MARKER_NOPC)
   end
   $noUSAreas.each do |area|
      addMapMarker(area,EXPLORED_MARKER_NOUS)
   end
   $allClearAreas.each do |area|
      addMapMarker(area,EXPLORED_MARKER_ALLCLEAR)
   end
   $toggles[:explored] = true
   $canvas.raise($currentTopTag)
end

def toggleExplored
   unHighlight
   if $toggles[:explored] == true
      hideExplored
   else
      showExplored
   end
end

def showGroups
   return if $toggles[:groups] == true
   toggleGroups
end

def showBattles
   return if $toggles[:battles] == true
   toggleBattles
end

def hideGroups
   return if $toggles[:groups] == false
   toggleGroups
end

def hideBattles
   return if $toggles[:battles] == false
   toggleBattles
end

def toggleGroups
   unHighlight
   if $toggles[:groups] == true
      $canvas.delete('ARMY')
      $toggles[:groups] = false
   else
      $groupList.showAllGroups(false)
      $toggles[:groups] = true
   end
   $canvas.raise($currentTopTag)
end

def toggleBattles
   unHighlight
   if $toggles[:battles] == true
      $canvas.delete('BATTLE')
      $toggles[:battles] = false
   else
      $battleList.showAllBattles(false)
      $toggles[:battles] = true
   end
   $canvas.raise($currentTopTag)
end

def startManualEntryDialog
   dialog=ManualEntry.new()
   dialog.createDialog
end

def startGroupMovementPlotter
   $gm=GroupMovementPlotter.new()
   $gm.createDialog
end


def fixRegions(quiet=false)
   clearText unless quiet
   $regionList.readRegionBorderFile 
   $popCenterList.fixRegions(quiet)
end

def createTextWindow
   #return if $textWindow != nil and $textWindow.exists
   return if TkWinfo.exist?($textWindow)
   $textWindow = TkToplevel.new($root) do
      title "Text Output (v#{VERSION})"
   end
   frame = TkFrame.new($textWindow) do
      relief 'sunken'
      borderwidth 3
      background 'darkgrey'
      padx 10
      pady 10
   end
   createTextBox(frame)
   frame.pack('fill' => 'both', 'expand' => 1)
end

def createTextBox(frame)

   #textFont = TkFont.new( "weight" => "bold")

   textFont = TkFont.new( 'family' => 'consolas',
                          'weight' => 'normal',
                          'size' => 10)

   scroll = nil
   tb = TkText.new(frame) {
      height   '10'
      width   '60'
      font   textFont
      background 'lightgrey'
      pack('side' => 'left', 'fill' => 'both', 'expand' => 1)
   }
   scroll = TkScrollbar.new(frame) {
      troughcolor 'yellow'
      command proc { |*args|
         tb.yview(*args)
      }
      pack('side' => 'left', 'fill' => 'y', 'expand' => 0)
   }
   tb.yscrollcommand(proc { |first,last|
                             scroll.set(first,last) } )
   $textBox = tb
   $textBox.tag_add(TEXT_TAG_TITLE,'end')
   $textBox.tag_add(TEXT_TAG_HEADING,'end')
   $textBox.tag_add(TEXT_TAG_NORMAL,'end')
   $textBox.tag_add(TEXT_TAG_STALE,'end')
   $textBox.tag_add(TEXT_TAG_GOOD,'end')
   $textBox.tag_add(TEXT_TAG_WARNING,'end')
   $textBox.tag_add(TEXT_TAG_DANGER,'end')
#  $textBox.tag_add('good')
#  $textBox.tag_add('danger')
#  $textBox.tag_add('warning')
   $textBox.tag_configure(TEXT_TAG_TITLE, :background=>'darkgrey', :font=>'helvetica 14 bold', :relief=>'raised')
   $textBox.tag_configure(TEXT_TAG_HEADING, :background=>'darkgrey',:font=>'consolas 10 bold', :relief=>'raised' )
   $textBox.tag_configure(TEXT_TAG_NORMAL, :background=>'lightgrey', :font=>textFont, :relief => 'flat' )
   $textBox.tag_configure(TEXT_TAG_GOOD, :foreground=>'#156f08' )
   #$textBox.tag_configure(TEXT_TAG_WARNING, :background=>'darkgrey', :foreground=>'#dd8d12' )
   $textBox.tag_configure(TEXT_TAG_WARNING, :background=>'darkgrey', :foreground=>'black' )
   $textBox.tag_configure(TEXT_TAG_WARNING2, :foreground=>'orange' )
   $textBox.tag_configure(TEXT_TAG_DANGER, :foreground=>'red' )
   $textBox.tag_configure(TEXT_TAG_STALE, :foreground=>'#77acae')

   # Setup a 
   $kingdomColors.keys.each do |banner|
      $textBox.tag_add(banner,'end')
      if banner == 'BL'
         $textBox.tag_configure(banner, :foreground=>'white', :background=> $kingdomColors[banner] )
      else
         $textBox.tag_configure(banner, :foreground=>'black', :background=> $kingdomColors[banner] )
      end
   end
end

def shrinkImage(image,subsample)
   w = image.width
   h = image.height
   #puts "w=#{w} h=#{h}"

   newImage = TkPhotoImage.new
   newImage.copy(image,
                 :from => [0, 0, w, h],
                 :subsample => [subsample,subsample])
   w = newImage.width
   h = newImage.height
   puts "w=#{w} h=#{h}"
   return newImage
end

def setupImage
   $bigImage = TkPhotoImage.new
   $bigImage.file = "#{$runRoot}/graphics/alamaze-resurgent.gif"
   $bigW = $bigImage.width
   $bigH = $bigImage.height
   #$bigImage.file = "/users/jgibbs/Documents/GitHub/AlamazeTurnParser/graphics/alamaze-resurgent.gif"

   $medImage = shrinkImage($bigImage,2)
   $medW = $medImage.width
   $medH = $medImage.height

   $smallImage = shrinkImage($bigImage,3)
   $smallW = $smallImage.width
   $smallH = $smallImage.height
end

def setupBM(banner,type,color)
   bigBM = TkBitmapImage.new('file'=>"#{$runRoot}/graphics/#{type}Big.xbm", 'foreground' => color)
   smallBM = TkBitmapImage.new('file'=>"#{$runRoot}/graphics/#{type}Small.xbm", 'foreground' => color)
   $kingdomBitmaps = Hash.new if $kingdomBitmaps == nil
   $kingdomBitmaps[banner] = Hash.new if $kingdomBitmaps[banner] == nil
   $kingdomBitmaps[banner][type] = Hash.new if $kingdomBitmaps[banner][type] == nil
   $kingdomBitmaps[banner][type][:big]=bigBM
   $kingdomBitmaps[banner][type][:medium]=bigBM
   $kingdomBitmaps[banner][type][:small]=smallBM
end

def setupKingdomBitmaps
   $kingdomColors.keys.each do |banner|
      ["C"].each do |markerType|
         setupBM(banner, markerType, $kingdomColors[banner])
      end
   end
end


def zoomInBig
   $canvas.configure(
               :width => $medW,
               :height => $medH,
               :scrollregion => [0,0,$bigW,$bigH])
   $currentTopTag = 'big'
   $canvas.raise($currentTopTag)
end

def zoomInMedium
   $canvas.configure(
               :width => $medW,
               :height => $medH,
               :scrollregion => [0,0,$medW,$medH])
   $currentTopTag = 'medium'
   $canvas.raise($currentTopTag)
end

def zoomOut
   w = $smallImage.width
   h = $smallImage.height
   $canvas.configure(
               :width => $smallW,
               :height => $smallH,
               :scrollregion => [0,0,$smallW,$smallH])
   $currentTopTag = 'small'
   $canvas.raise($currentTopTag)
   $canvas.xview('scroll', 0, 'units')
   $canvas.yview('scroll', 0, 'units')
end

def createCanvas(frame)

   hframe = TkFrame.new(frame)

   $canvas = canvas =TkCanvas.new(hframe) do
         border 0
         width $smallW
         height $smallH
        xscrollincrement 1
        yscrollincrement 1
   end

   xscroll = TkScrollbar.new(frame) do
      background 'green'
      command do |*args|
         canvas.xview *args
      end
      orient 'horiz'
   end

   yscroll = TkScrollbar.new(hframe) do
      background 'red'
      command do |*args|
         canvas.yview *args
      end
      orient 'vertical'
   end

   addMapImages

   hframe.pack(:expand => 'yes', :fill => 'both')
   #hframe.pack(:side => 'bottom', :expand => 'yes', :fill => 'both')
#  frame.pack(:expand => 'no', :fill => 'x')
   $canvas.pack( :side => 'left', :expand => 'no', :fill => 'none')
   xscroll.pack( :side => 'bottom', :expand => 'no', :fill => 'x')
   yscroll.pack( :side => 'right', :expand => 'no', :fill => 'y')

      canvas.xscrollcommand do |first, last|
        xscroll.set(first, last)
      end
      canvas.yscrollcommand do |first, last|
        yscroll.set(first, last)
      end

      $root.bind "Key-Right" do
        canvas.xview "scroll", 10, "units"
      end

      $root.bind "Key-Left" do
        canvas.xview "scroll", -10, "units"
      end

      $root.bind "Key-Down" do
        canvas.yview "scroll", 10, "units"
      end

      $root.bind "Key-Up" do
        canvas.yview "scroll", -10, "units"
      end

      $root.bind "Control-Up" do
        zoomInMedium
      end

      $root.bind "Control-Down" do
        zoomOut
      end

      $root.bind "c" do
        closeFile
      end

      $root.bind "o" do
        openDocument
      end

      $root.bind "p" do
        parseTurn
      end

      $root.bind "s" do
        saveData
      end

      $root.bind "Control-s" do
        saveData
      end

      $root.bind "Control-S" do
        saveAsData
      end

      $root.bind "g" do
        toggleGroups
      end

      $root.bind "b" do
        toggleBattles
      end

      $root.bind "e" do
        toggleExplored
      end
      $root.bind "x" do
        toggleExplored
      end
end # end create canvas

def initOffsets
   $offsets = Hash.new
   $offsets[:big] = Hash.new
   $offsets[:big][:frameX]=53
   $offsets[:big][:frameY]=40
   $offsets[:big][:boxX]=80.5
   $offsets[:big][:boxY]=60.45
   $offsets[:big][:tag]='big'
   $offsets[:big][:font]= TkFont.new( "size" => '30', "weight" => "bold")
   $offsets[:big][:thickLine]=12 
   $offsets[:big][:thinLine]=7 

   $offsets[:medium] = Hash.new
   $offsets[:medium][:frameX]=26
   $offsets[:medium][:frameY]=20
   $offsets[:medium][:boxX]=40.30
   $offsets[:medium][:boxY]=30.15
   $offsets[:medium][:tag]='medium'
   $offsets[:medium][:font]= TkFont.new( "size" => '15', "weight" => "bold")
   $offsets[:medium][:thickLine]=12 * 2.0/3.0
   $offsets[:medium][:thinLine]=7 * 2.0/3.0

   $offsets[:small] = Hash.new
   $offsets[:small][:frameX]=17
   $offsets[:small][:frameY]=14
   $offsets[:small][:boxX]=26.8
   $offsets[:small][:boxY]=20.1
   $offsets[:small][:tag]='small'
   #$offsets[:small][:font]= TkFont.new( "size" => '17', "weight" => "bold")
   $offsets[:small][:font]= TkFont.new( "size" => '10' )
   $offsets[:small][:thickLine]=7
   $offsets[:small][:thinLine]=3
end

def drawAnArmy(size,x,y,id,color)
   p = TkcPolygon.new($canvas,
                      x +  $offsets[size][:boxX]/2.0, y +  $offsets[size][:boxY]/2.2,
                      x -  $offsets[size][:boxX]/4.0, y +  $offsets[size][:boxY]/3.5,
                      x -  $offsets[size][:boxX]/2.0, y,
                      x -  $offsets[size][:boxX]/4.0, y -  $offsets[size][:boxY]/3.5,
                      x +  $offsets[size][:boxX]/2.0, y -  $offsets[size][:boxY]/2.2,
                      x -  $offsets[size][:boxX]/4.0, y,
                      :smooth => 'true',
                      :fill => color, :outline => 'black',
                      :tags =>  ['ARMY','Marker', $offsets[size][:tag] ])
  textColor='black'
  textColor='white' if color == 'black'
  txt  = TkcText.new($canvas,  x -  $offsets[size][:boxX]/5.0, y, 
                     'text' => id, 'tags' => ['ARMY','Marker', $offsets[size][:tag] ],
                     'fill' => textColor, 'font' => $offsets[size][:font] )
  return [p,txt]
end

def drawAVillage(size,x,y,region,color)
  x1 = x - ($offsets[size][:boxX]*0.33)
  y1 = y - ($offsets[size][:boxX]*0.33)
  x2 = x + ($offsets[size][:boxX]*0.33)
  y2 = y + ($offsets[size][:boxX]*0.33)
  oval = TkcOval.new($canvas, [x1,y1], [x2,y2] , 
                         :fill => color, :outline => 'black',  'tags' => ['VILLAGE','Marker', $offsets[size][:tag] ])
  textColor='black'
  textColor='white' if color == 'black'
  txt  = TkcText.new($canvas, x, y, 'text' => region, 'tags' => ['VILLAGE','Marker', $offsets[size][:tag] ],
                              'fill' => textColor, 'font' => $offsets[size][:font] )
  return [oval,txt]
end

def drawATown(size,x,y,region,color)
  box = TkcRectangle.new($canvas, x - ($offsets[size][:boxX]*0.33),
                                  y - ($offsets[size][:boxY]*0.33),
                                  x + ($offsets[size][:boxX]*0.33),
                                  y + ($offsets[size][:boxY]*0.33),
                                  :fill => color, :outline => 'black', :tags=>['TOWN','Marker',$offsets[size][:tag] ])
  textColor='black'
  textColor='white' if color == 'black'
  txt = TkcText.new($canvas, x, y, 'text' => region, 'tags' => ['TOWN','Marker', $offsets[size][:tag] ],
                      'fill' => textColor, 'font' => $offsets[size][:font] )
  return [box,txt]
end

def drawABlock(size,x,y)
  box = TkcRectangle.new($canvas, $offsets[size][:frameX] + ($offsets[size][:boxX]*x),
                                  $offsets[size][:frameY] + ($offsets[size][:boxY]*y),
                                  $offsets[size][:frameX] + ($offsets[size][:boxX]*(x+1)),
                                  $offsets[size][:frameY] + ($offsets[size][:boxY]*(y+1)),
                                  :outline => BOX_OUTLINE_NORMAL, 
                                  :state => 'hidden', 
                                  :tags=>[I_AM_A_BOX,  $offsets[size][:tag] ])
  return box
end

# loc is in AA-ZZ
def addRedBlock(loc)
   x = loc[0].ord - 'A'.ord
   y = loc[1].ord - 'A'.ord
   box=drawABlock(:big, x, y)
   box.configure('fill' => 'red')
   box=drawABlock(:medium, x, y)
   box.configure('fill' => 'red')
   drawABlock(:small, x, y)
   box.configure('fill' => 'red')
end



def createMainDisplay(root)
   setupMenus(root)

   # Main fraim other than root
   bFrame = TkFrame.new(root) do
      relief 'raised'
      background 'black'
      borderwidth 3
      padx 10
      pady 10
   end

   # Create Canvas frame
   csFrame = TkFrame.new(bFrame) 

   # Create Canvas frame
   tFrame = TkFrame.new(bFrame) do
      relief 'sunken'
      borderwidth 3
      background 'darkgrey'
      padx 10
      pady 10
   end

   cFrame = TkFrame.new(csFrame) do
      relief 'raised'
      background 'green'
      borderwidth 5
   end

   sFrame = TkFrame.new(csFrame) do
      #background 'orange'
      background '#f6b177'
      borderwidth 5
   end

   $offsets=0
   initOffsets
   setupImage

   TkLabel.new(cFrame) {
             textvariable $myGameInfoText
             foreground 'black'
             background 'green'
             font       $boldFont      
             pack('side'=>'top')
   }

   createCanvas(cFrame)
   fillGrid
   #zoomOut
   zoomInMedium
   #createTextBox(tFrame)
   createSearchParts(sFrame)

 
   $canvas.pack
   cFrame.pack('side' => 'left' )
   sFrame.pack('side' => 'right', 'fill' => 'both', 'expand' => 1 )
   csFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 1 )
   tFrame.pack('side' => 'top' , 'fill' => 'both' , 'expand' => 1)


   bFrame.pack('side' => 'top' , 'fill' => 'both' , 'expand' => 1)

   return bFrame
end

def closeFile
   $canvas.delete('all')
   initVars
   addMapImages
   fillGrid
   #zoomOut
   zoomInMedium
   clearText
   $currentOpenFile = nil
end

def addMapImages
   TkcImage.new($canvas,$bigW/2,$bigH/2, 'image' => $bigImage, :tags => 'big')
   TkcImage.new($canvas,$medW/2,$medH/2, 'image' => $medImage, :tags => 'medium')
   TkcImage.new($canvas,$smallW/2,$smallH/2, 'image' => $smallImage, :tags => 'small')
end

def initVars
   $areaList = AreaList.new
   $emissaryList = EmissaryList.new
   $popCenterList= PopCenterList.new
   $groupList= GroupList.new
   $artifactList = ArtifactList.new
   $regionList = RegionList.new
   $kingdoms = Hash.new
   $emissaries = Hash.new
   $armies = Hash.new
   $turns = Hash.new
   $highCouncilList = HighCouncilIssueList.new
   $battleList = BattleList.new
   $passThroughRecords = Array.new 
   $currentTurn = 0
   $gameNumber = nil
   $myKingdom = nil
   $infoData = Array.new
   $influence = Array.new
   $myGameInfoText.value = "A L A M A Z E"
   $currentOpenFile=nil
   $exploredAreas = Array.new
   $noUSAreas = Array.new
   $allClearAreas = Array.new
   $exploreDialog = nil
   $menuDialog = nil
   $emmyDialog.destroy if TkWinfo.exist?($emmyDialog)
   $emmyDialog = nil
   $gmPlotter = nil
   $manualEntry.destroy if TkWinfo.exist?($manualEntry)
   $manualEntry = nil
   $unusualSightings = UnSightingInfo.new
   $toggles = Hash.new
   $toggles[:explored]=true
   $toggles[:groups]=true
   setupImage
end

#===============================================================================
#===============================================================================
#===============================================================================
begin 

   initVars
   programName="Alamaze Turn Parser GUI (v#{VERSION})"
   $root = TkRoot.new { title programName }
   bFrame=createMainDisplay($root)
   TkLabel.new(bFrame) do
      textvariable $cursorLoc
      pack { side 'left' }
   end
   setupKingdomBitmaps
   
   appendTextWithTag("#{programName}\n", TEXT_TAG_TITLE)

   if defined? ENV['OCRA_EXECUTABLE']
      appendText("OCRA_EXECUTABLE=[#{ENV['OCRA_EXECUTABLE']}]\n")
   end
   appendText("$0=[#{$0}]\n")
   appendText("pdfReaderLoaded=#{$pdfReaderLoaded}\n")
   
   tweakVolume

   #addRedBlock('AA')
   #addRedBlock('BB')
   #addRedBlock('ZZ')

   if not defined?(Ocra) 
      Tk.mainloop
   else
      puts "Detected that ocra is building script. Skipping Tk.mainloop"
   end

rescue Exception => e
   File.open("parserGuiError.txt","w+") do |f|
      f.puts "Caught Exception."
      f.puts e.inspect
      f.puts "\nBacktrace:\n"
      f.puts e.backtrace
      f.puts "\nCurrent Directory=[#{Dir.getwd}]\n"
   end
end

exit 0
