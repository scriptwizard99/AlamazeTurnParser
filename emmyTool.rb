#!/usr/bin/ruby
=begin
    Alamaze Emissary Module - This module contains classes that can
    be used to compute an emissaries chances of operating on a
    population center.

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

class EmmyTool

   POP_VILLAGE=1.3
   POP_TOWN=2.6
   POP_CITY=6.5

   REACT_FRIENDLY=1
   REACT_TOLERANT=2
   REACT_SUSPICIOUS=3
   REACT_HOSTILE=4

   RANK_PRINCE=0.8
   RANK_DUKE=0.7
   RANK_COUNT=0.6
   RANK_BARON=0.5
   RANK_GOVERNOR=0.3
   RANK_AMBASSADOR=0.2
   RANK_ENVOY=0.1

   $popMap = {
      'V' => POP_VILLAGE,
      'T' => POP_TOWN,
      'C' => POP_CITY
   }

   $reactionMap = {
      'F' => REACT_FRIENDLY,
      'T' => REACT_TOLERANT,
      'S' => REACT_SUSPICIOUS,
      'H' => REACT_HOSTILE
   }

   $rankMap = {
      'PRI' => RANK_PRINCE,
      'DUK' => RANK_DUKE,
      'DUT' => RANK_DUKE,
      'BAR' => RANK_BARON,
      'PRO' => RANK_GOVERNOR,
      'GOV' => RANK_GOVERNOR,
      'AMB' => RANK_AMBASSADOR,
      'ENV' => RANK_ENVOY
   }

   def initialize(popType, influence, regionalReaction, 
                  popLoc=nil, popName=nil, regionName=nil)
      #puts "pt=#{popType} i=#{influence} rr=#{regionalReaction}"
      if popType == nil or popType.empty?
         @popType = 0
      else
         @popType = $popMap[popType[0]]
      end
      if regionalReaction == nil
         @regReact = 0
      else
         @regReact = $reactionMap[regionalReaction[0]]
      end
      @influence = influence
      @popLoc = popLoc
      @popName = popName
      @regionName = regionName
      @neutralScore = @popType.to_f * @regReact.to_f
   end
   
   def getNeutralScore
      return @neutralScore
   end

   def getInfo
      info=sprintf("")
   end
   
end # class EmmyTool
