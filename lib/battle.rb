#!/usr/bin/ruby
=begin
    Alamaze Battle Module - This module contains classes that 
    pertain to battles that happen

    Copyright (C) 2015  Joseph V. Gibbs III

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

class BattleList


   def initialize()
      @list=Array.new
      @graphicsFile="#{$runRoot}/graphics/battleIcon.gif"
      setupImages
   end

   def setupImages
      @images=Hash.new
      bigImage = TkPhotoImage.new
      bigImage.file = @graphicsFile
      @images[:big] =  bigImage
      medImage = shrinkImage(bigImage,2)
      @images[:medium] =  medImage
      @images[:small] = shrinkImage(bigImage,3)
   end

   def addBattle(line)
      (turn,junk,area,attacker,defender)=line.strip.split(',')
      @list.push BattleInfo.new(turn,area,attacker,defender)
      return @list.last
   end

 
   def drawBattle(size,x,y,loc)
     img = TkcImage.new($canvas,x,y, 'image' => @images[size], :tags => ['BATTLE', 'Marker', $offsets[size][:tag] ])
     return img
   end

   def showBattleHeader
      appendTextWithTag("Trn Area              Attacker                                       Defender   \n",TEXT_TAG_HEADING)
      appendTextWithTag("--- ---- ----------------------------------------   ----------------------------------------\n",TEXT_TAG_HEADING)
   end

   def showAllBattles(printReport=true)
      unHighlight
      if printReport
         clearText
         appendTextWithTag("History of All Known Battles\n\n",TEXT_TAG_TITLE)
         showBattleHeader
      end
      @list.each do |battle|
         turn = battle.getTurn
         line = battle.toString
         if turn == $currentTurn
            appendText(line) if printReport
            addMapMarker( battle.getLocation, "B")
         else
            appendTextWithTag(line, TEXT_TAG_STALE) if printReport
         end
      end
      $canvas.raise($currentTopTag)
   end

   def showBattles(area)
      @list.each do |battle|
         next if battle.getLocation != area
         turn = battle.getTurn
         line = battle.toString
         if turn == $currentTurn
            appendText(line) 
         else
            appendTextWithTag(line, TEXT_TAG_STALE) unless $history.value.to_i == HISTORY_CURRENT
         end
      end
   end


end # class BattleList


class BattleInfo
   def initialize(turn, loc, attacker, defender)
       @turn = turn
       @loc = loc
       @attacker=attacker
       @defender=defender
   end

   def getTurn
      return @turn
   end

   def getLocation
      return @loc
   end

   def getAttacker
      return @attacker
   end

   def getDefender
      return @defender
   end

   def toString
      return sprintf("%3s %3s   %-40s   %-40s\n",@turn, @loc, @attacker, @defender)
   end

end # class BattleInfo
