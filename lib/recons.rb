#!/usr/bin/ruby
=begin
    Alamaze Agent Module - This module contains classes that 
    pertain to agent activities

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

AGENT_EVENT_TYPE_RECON="recon"

class AgentEventList


   def initialize()
      @list=Array.new
   end

   def addAgentEvent(line)
      (turn,junk,type,banner,name,agentLoc,eventLoc)=line.strip.split(',')
      @list.push AgentEventInfo.new(turn,type,banner,name,agentLoc,eventLoc)
      return @list.last
   end

   def showAgentEventHeader
      appendTextWithTag("Trn King              Attacker                                       Defender   \n",TEXT_TAG_HEADING)
      appendTextWithTag("--- ---- ----------------------------------------   ----------------------------------------\n",TEXT_TAG_HEADING)
   end

   def showAllAgentEvents(printReport=true)
      unHighlight
      if printReport
         clearText
         appendTextWithTag("History of All Known Agent Events\n\n",TEXT_TAG_TITLE)
         showAgentEventHeader
      end
      @list.each do |agentEvent|
         turn = agentEvent.getTurn
         line = agentEvent.toString
         if turn == $currentTurn
            appendText(line) if printReport
#           addMapMarker( agentEvent.getLocation, "B")
         else
            appendTextWithTag(line, TEXT_TAG_STALE) if printReport
         end
      end
#     $canvas.raise($currentTopTag)
   end

   def showAgentEvents(area)
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


end # class AgentEventList


class AgentEventInfo
   def initialize(turn, type, banner, name, agentLoc, eventLoc)
       @turn = turn
       @type = type
       @banner=banner
       @name=name
       @agentLoc=agentLoc
       @eventLoc=eventLoc
   end

   def getTurn
      return @turn
   end

   def getType
      return @type
   end

   def getAgentLoc
      return @agentLoc
   end

   def getEventLoc
      return @eventLoc
   end

   def getBanner
      return @banner
   end

   def getName
      return @name
   end

   def toString
      return sprintf("%3s %3s   %-40s   %-40s\n",@turn, @loc, @attacker, @defender)
   end

end # class AgentEventInfo
