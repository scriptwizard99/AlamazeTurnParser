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

class EmmyToolWindow

   def initialize(influence, area=nil)
      @influence=influence
      $curPopType = TkVariable.new
      $curPopType.value = "N/A"
      $curRegName = TkVariable.new
      $curRegName.value = "N/A"
      @curReaction=""
      createWindowParts
      setLocation(area)
   end # initialize

   def createWindowParts
      unHighlight
      $emmyDialog.destroy if TkWinfo.exist?($emmyDialog)
      $emmyDialog = TkToplevel.new($root) do
         title "Emissary Tool"
      end
      mainEmmyFrame = TkFrame.new($emmyDialog) do
         relief 'sunken'
         borderwidth 3
         background 'darkgrey'
         padx 10
         pady 10
      end
      upperFrame = TkFrame.new(mainEmmyFrame)
      middleFrame = TkFrame.new(mainEmmyFrame)
      bottomFrame = TkFrame.new(mainEmmyFrame)


      # Upper frame only has influence
      TkLabel.new(upperFrame) do
         text 'King\'s Influence : '
         pack('side'=>'left')
      end
      infEntry = TkEntry.new(upperFrame) do
         width '10'
         pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
      end
      infEntry.insert('end', " #{@influence}")
      infEntry.bind('Return', proc { self.alterInfluence(infEntry) } )


      # Middle frame has location, PC info, and region info
      midLF = TkFrame.new(middleFrame)
      midMF = TkFrame.new(middleFrame)
      midRF = TkFrame.new(middleFrame)
      TkLabel.new(midLF) do
         text 'Location : '
         pack('side'=>'left')
      end
      @locEntry = TkEntry.new(midLF) do
         width '4'
         pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
      end
      @locEntry.bind('Return', proc { self.setLocationFromEntry } )

      TkLabel.new(midMF) do
         text 'Pop Type : '
         pack('side'=>'left')
      end
      TkLabel.new(midMF) do
         textvariable $curPopType
         #text "blah"
         pack('side'=>'left')
      end

      TkLabel.new(midRF) do
         textvariable $curRegName
         pack('side'=>'left')
      end
      @regEntry = TkEntry.new(midRF) do
         width '12'
         pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
      end
      @regEntry.bind('Return', proc { self.setReactionFromEntry } )


      midLF.pack('side' => 'left', 'fill' => 'none', 'expand' => 0)
      midMF.pack('side' => 'left', 'fill' => 'none', 'expand' => 0)
      midRF.pack('side' => 'left', 'fill' => 'none', 'expand' => 0)

      # Pack the frames
      upperFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 0)
      middleFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 0)
      bottomFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 1)

      mainEmmyFrame.pack('expand' => 1)
   end

   def alterInfluence(entry)
   end
   
   def setReactionFromRegion(regNum)
      region = $regionList.getRegionByNum(regNum)
      $curRegName.value = "Region(#{region.getName}) : "
      setReaction(region.getLatestReaction)
   end
   def setReactionFromEntry
      reaction = @regEntry.get.upcase.strip
      setReaction(reaction)
   end

   def setReaction(reaction)
      @curReaction = reaction
      @regEntry.delete(0,'end')
      @regEntry.insert('end', " #{reaction}")
   end
   
   def setLocationFromEntry
      loc = @locEntry.get.upcase.strip[0..1]
      setLocation(loc)
   end
   def setLocation(loc)
      @area=loc
      @locEntry.delete(0,'end')
      @locEntry.insert('end', " #{@area}")
      popCenter = $popCenterList.getPopCenter(@area)
      if popCenter == nil
         $curPopType.value = "N/A"
         setReaction("N/A")
      else
         $curPopType.value = popCenter.getType
         setReactionFromRegion( popCenter.getRegion )
      end
      appendText("looking at #{popCenter.getName} which is of type #{popCenter.getType}\n")
   end
   
end # class EmmyToolWindow

