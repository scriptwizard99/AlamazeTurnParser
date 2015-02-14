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

# TODO
# The relationship betwen this class, the TkToplevel, and some of
# the other functions in amap.rb are ugly. I should be using callbacks.
# TODO

class EmmyToolWindow


      $curPopType = TkVariable.new
      $curRegName = TkVariable.new

   def initialize(influence, area=nil)
      @influence=influence
      $curPopType.value = "N/A"
      $curRegName.value = "N/A"
      @curReaction=""
      createWindowParts
      setLocation(area)
   end # initialize

   def createWindowParts
      unHighlight
      #$emmyDialog.destroy if TkWinfo.exist?($emmyDialog)
      return if TkWinfo.exist?($emmyDialog)
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


      #----------------------------------
      # Upper frame only has influence
      #----------------------------------
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


      #----------------------------------
      # Middle frame has location, PC info, 
      # and region info
      #----------------------------------
      midLF = TkFrame.new(middleFrame)
      midMF = TkFrame.new(middleFrame)
      midRF = TkFrame.new(middleFrame)
      midMMF = TkFrame.new(midMF)
      TkLabel.new(midLF) do
         text 'Location : '
         pack('side'=>'left')
      end
      $emmyToolLocEntry = TkEntry.new(midLF) do
         width '4'
         pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
      end
      $emmyToolLocEntry.bind('Return', proc { self.setLocationFromEntry } )

      TkLabel.new(midMMF) do
         text 'Pop Type : '
         pack('side'=>'left')
      end
      TkLabel.new(midMMF) do
         textvariable $curPopType
         #text "blah"
         pack('side'=>'left')
      end

      TkLabel.new(midRF) do
         textvariable $curRegName
         pack('side'=>'left')
      end
      $emmyToolRegEntry = TkEntry.new(midRF) do
         width '12'
         pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
      end
      $emmyToolRegEntry.bind('Return', proc { self.setReactionFromEntry } )


      midLF.pack('side' => 'left', 'fill' => 'none', 'expand' => 0)
      midMF.pack('side' => 'left', 'fill' => 'x', 'expand' => 1)
      midRF.pack('side' => 'right', 'fill' => 'none', 'expand' => 0)
      midMMF.pack('side' => 'top', 'fill' => 'none', 'expand' => 1, 'anchor'=>'center')

      #----------------------------------
      # Bottom frame has text window
      #----------------------------------
      textFont = TkFont.new( 'family' => 'consolas',
                             'weight' => 'normal',
                             'size' => 10)

      scroll = nil
      tb = TkText.new(bottomFrame) {
         height   '15'
         width   '80'
         font   textFont
         background 'lightgrey'
         pack('side' => 'left', 'fill' => 'both', 'expand' => 1)
      }
      scroll = TkScrollbar.new(bottomFrame) {
         command proc { |*args|
            tb.yview(*args)
         }
         pack('side' => 'left', 'fill' => 'y', 'expand' => 0)
      }
      tb.yscrollcommand(proc { |first,last|
                                scroll.set(first,last) } )
      $emmyTextBox = tb
      $emmyTextBox.tag_add(TEXT_TAG_TITLE,'end')
      $emmyTextBox.tag_add(TEXT_TAG_HEADING,'end')
      $emmyTextBox.tag_add(TEXT_TAG_NORMAL,'end')
      $emmyTextBox.tag_add(TEXT_TAG_STALE,'end')
      $emmyTextBox.tag_add(TEXT_TAG_GOOD,'end')
      $emmyTextBox.tag_add(TEXT_TAG_WARNING,'end')
      $emmyTextBox.tag_add(TEXT_TAG_DANGER,'end')

      $emmyTextBox.tag_configure(TEXT_TAG_TITLE, :background=>'darkgrey', :font=>'helvetica 14 bold', :relief=>'raised')
      $emmyTextBox.tag_configure(TEXT_TAG_HEADING, :background=>'darkgrey',:font=>'consolas 10 bold', :relief=>'raised' )
      $emmyTextBox.tag_configure(TEXT_TAG_NORMAL, :background=>'lightgrey', :font=>textFont, :relief => 'flat' )
      $emmyTextBox.tag_configure(TEXT_TAG_GOOD, :foreground=>'#156f08' )
      $emmyTextBox.tag_configure(TEXT_TAG_WARNING, :foreground=>'orange' )
      $emmyTextBox.tag_configure(TEXT_TAG_DANGER, :foreground=>'red' )
      $emmyTextBox.tag_configure(TEXT_TAG_STALE, :foreground=>'#77acae')


      # Pack the frames
      upperFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 0)
      middleFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 0)
      bottomFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 1)

      mainEmmyFrame.pack('fill' => 'both','expand' => 1)

      $emmyTextBox.bind('1', proc { self.emmyClick } )

   end

   def emmyClick
         line = $emmyTextBox.get('current linestart', 'current lineend')
         loc = line.split[0]
         highlightTag("box-#{loc}",true)
         #appendText( "clicked in box\n", $emmyTextBox)
         #appendText( "line[#{line}]\n", $emmyTextBox)
   end

   def alterInfluence(entry)
      # TODO - find bug
      #influence=entry.get
      #@influence=influence if influence.to_i > 8.0
      #setLocationFromEntry
      # TODO - find bug
      entry.delete(0,'end')
      entry.insert('end',@influence)
   end
   
   def setReactionFromRegion(regNum)
      region = $regionList.getRegionByNum(regNum)
      if region.nil?
         $curRegName.value = "Region(???) : "
         setReaction("???")
      else
         $curRegName.value = "Region(#{region.getName}) : "
         setReaction(region.getLatestReaction)
      end
   end
   def setReactionFromEntry
      reaction = $emmyToolRegEntry.get.upcase.strip
      setReaction(reaction)
   end

   def setReaction(reaction)
      @curReaction = reaction
      $emmyToolRegEntry.delete(0,'end')
      $emmyToolRegEntry.insert('end', " #{reaction}")
   end
   
   def setLocationFromEntry
      loc = $emmyToolLocEntry.get.upcase.strip[0..1]
      setLocation(loc)
   end
   def setLocation(loc)
      etClear
      @area=loc
      $emmyToolLocEntry.delete(0,'end')
      $emmyToolLocEntry.insert('end', " #{@area}")
      popCenter = $popCenterList.getPopCenter(@area)
      if popCenter == nil
         $curPopType.value = "N/A"
         setReaction("N/A")
      else
         $curPopType.value = popCenter.getType
         setReactionFromRegion( popCenter.getRegion )
         tool=EmmyTool.new($curPopType.value,@influence,@curReaction )
         fillEmmyWindow(tool)
      end
   end

   def etClear
      clearText($emmyTextBox)
   end

   def getInRangeString(distance)
      if (distance == 0)
         return "HERE!"
      elsif (distance <= 10)
         return "yes"
      else
         return "no"
      end
   end

   def fillEmmyWindow(tool)

      appendTextWithTag(" LOC         Emissary Name         Emissary Rank      1Step  2Steps InRange\n", TEXT_TAG_HEADING, $emmyTextBox)
      appendTextWithTag("-----  ------------------------- -------------------- ------ ------ -------\n", TEXT_TAG_HEADING, $emmyTextBox)

      # get a list of emissary objects
      myEmissaries = $emissaryList.getEmissaryByKingdom($myKingdom)
      myEmissaries.each do | emmy |
         next if emmy.isPolitical == false
         lastTurn = emmy.getLastTurn
         next if lastTurn < $currentTurn
         #line = emmy.toString( lastTurn)
         rank = emmy.getRank(lastTurn)
         emLoc = emmy.getLocOnTurn(lastTurn)
         distance = $areaList.computeDistance(@area,emLoc)
         (oneStep,twoSteps) = tool.getChances(rank)
         line=sprintf(" %2.2s     %-25s %-20s %-5s  %-5s  %-5s\n",
                      emmy.getLocOnTurn(lastTurn),
                      emmy.getName, rank, oneStep, twoSteps, getInRangeString(distance.to_i))
         #line=sprintf("%-60s %-5s %-5s\n", line.chomp, oneStep, twoSteps)
         appendText( line, $emmyTextBox)
      end

      tagText($emmyTextBox, "yes",   TEXT_TAG_GOOD)
      tagText($emmyTextBox, "HERE!",   TEXT_TAG_GOOD)
      tagText($emmyTextBox, "maybe", TEXT_TAG_WARNING)
      tagText($emmyTextBox, "no",    TEXT_TAG_DANGER)
   end
   
end # class EmmyToolWindow

