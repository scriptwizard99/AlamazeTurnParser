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

   CHANCE_YES='yes'
   CHANCE_MAYBE='maybe'
   CHANCE_NO='no'
   CHANCE_NA='N/A'

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
      'COU' => RANK_COUNT,
      'BAR' => RANK_BARON,
      'PRO' => RANK_GOVERNOR,
      'GOV' => RANK_GOVERNOR,
      'AMB' => RANK_AMBASSADOR,
      'ENV' => RANK_ENVOY
   }

   def initialize(popType, influence, regionalReaction, 
                  popLoc=nil, popName=nil, regionName=nil)
      #puts "pt=#{popType} i=#{influence} rr=#{regionalReaction}"
      setPopType(popType)
      setRegionalReact(regionalReaction)
      @influence = influence
      @popLoc = popLoc
      @popName = popName
      @regionName = regionName
      @neutralScore = @popType.to_f * @regReact.to_f
   end

   def setPopType(popType)
      if popType == nil or popType.empty?
         @popType = 0
      else
         @popType = $popMap[popType[0]]
      end
   end

   def setRegionalReact(regionalReaction)
      if regionalReaction == nil
         @regReact = 0
      else
         @regReact = $reactionMap[regionalReaction[0]]
      end
   end
   
   def getNeutralScore
      return @neutralScore
   end

   def getChance(difficulty, powerMin, powerMax)
      return CHANCE_YES if powerMin.to_f > difficulty.to_f
      return CHANCE_NO if powerMax.to_f < difficulty.to_f
      return CHANCE_MAYBE
   end

   def getChances(rank)
      appendText("Computing chances for rank=#{rank}\n")
      return( [CHANCE_NA, CHANCE_NA]) if rank == nil
      rval =  $rankMap[rank[0..2]]
      if rval == nil 
         return( [CHANCE_NA, CHANCE_NA])
      end
      power = @influence.to_f * rval.to_f
      powerMin = power * 0.9
      powerMax = power * 1.1
      oneStep = getChance(@neutralScore.to_f, powerMin, powerMax)
      twoSteps = getChance(@neutralScore.to_f * 2.0, powerMin, powerMax)
      return([oneStep,twoSteps])
   end

   def getInfo
      info=sprintf("")
   end
   
end # class EmmyTool
