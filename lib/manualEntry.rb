=begin
    Alamaze Data Miner - This is a GUI for displaying data parsed out
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


class ManualEntry

   ENTRY_TYPE_POPCENTER=0
   ENTRY_TYPE_EMISSARY=1
   ENTRY_TYPE_GROUP=2


   def initialize
      $manualEntryType = TkVariable.new
      @self = self
   end # initialize

   

   def createDialog
      $manualEntry.destroy if TkWinfo.exist?($manualEntry)
      $manualEntry = TkToplevel.new($root) do
         title 'Manual Entry'
      end
      frame = TkFrame.new($manualEntry) do
         relief 'sunken'
         borderwidth 3
         background 'darkgrey'
         padx 10
         pady 10
      end
      topFrame = TkFrame.new(frame) 
      midFrame = TkFrame.new(frame) 
      botFrame = TkFrame.new(frame) 


      #entryType radio buttons
      $manualEntryType.value = ENTRY_TYPE_POPCENTER
      etrFrame=TkFrame.new(midFrame)
      TkRadioButton.new(etrFrame) {
        text 'Pop Center'
        variable $manualEntryType
        value ENTRY_TYPE_POPCENTER
        anchor 'w'
        pack('side' => 'top', 'fill' => 'x')
      }
      TkRadioButton.new(etrFrame) {
        text 'Emissary'
        variable $manualEntryType
        value ENTRY_TYPE_EMISSARY
        anchor 'w'
        pack('side' => 'top', 'fill' => 'x')
      }
      TkRadioButton.new(etrFrame) {
        text 'Group'
        variable $manualEntryType
        value ENTRY_TYPE_GROUP
        anchor 'w'
        pack('side' => 'top', 'fill' => 'x')
      }
      etrFrame.pack('side'=>'left')

      # Location
      TkLabel.new(midFrame) do 
         text 'Area: '
         pack('side'=>'left')
      end
      @locEntry=TkEntry.new(midFrame) do
         width 3
         pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
      end

      # Banner
      TkLabel.new(midFrame) do 
         text 'Owner: '
         pack('side'=>'left')
      end
      @bannerEntry=TkEntry.new(midFrame) do
         width 3
         pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
      end


      # Type/Rank/Size
      TkLabel.new(midFrame) do 
         text "Type\nor\nRank : \nor\nSize"
         pack('side'=>'left')
      end
      @detailEntry=TkEntry.new(midFrame) do
         width 10
         pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
      end

      myself=@self

      TkButton.new(botFrame) do
         text "Apply"
         command (proc{myself.applyEntry})
         pack('side'=>'top', 'fill'=>'x', 'expand' => 1)
      end

      topFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 0)
      midFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 1)
      botFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 0)
      frame.pack('fill' => 'both', 'expand' => 1)
   end # createDialog

   def applyEntry
      type = $manualEntryType.value
      loc = @locEntry.get.strip.upcase
      banner = @bannerEntry.get.strip.upcase
      detail = @detailEntry.get.strip.upcase
      appendText("apply type=#{type} loc=#{loc} ban=#{banner} det=#{detail}\n")

      if Area.isLocValid(loc) != true
         appendText("#{loc} is not a valid map location. Entry ignored.\n")
         return
      end

      if $kingdomNameMap[banner].nil?
         appendText("#{banner} is not a valid kingdom abbreviation location. Entry ignored.\n")
         return
      end

      case type.to_i
      when ENTRY_TYPE_EMISSARY
         if Emisary.isValidRank(detail) != true
            appendText("#{detail} is not an acceptable emissary rank. Entry ignored.\n")
            return
         end
      when ENTRY_TYPE_POPCENTER
         addPopCenterEntry(type,loc,banner,detail)
      else
         appendText("Unknown entry type: #{type}\n")
      end
   end

   def addPopCenterEntry(type,loc,banner,detail)
      if PopCenter.isValidType(detail) != true
         appendText("#{detail} is not an acceptable population center type. Entry ignored.\n")
         return
      end

      pc=$popCenterList.getPopCenter(loc) 
      if pc != nil
         appendTextWithTag("Error, there is already a pop center at #{loc}\n",TEXT_TAG_DANGER)
         $popCenterList.printHeader
         line = pc.toString(nil)
         appendTextWithTag(line,TEXT_TAG_DANGER)
         return
      end

      line="#{$currentTurn},P,Manual,#{loc},#{banner},#{detail}-#{loc},,#{detail},,,,,na"
      appendText("Creating: #{line}\n")
      addPopCenter(line)
      addColoredMapMarker(loc, detail[0], banner, nil)
      fixRegions
      $canvas.raise($currentTopTag)
   end

end # class ManualEntry

