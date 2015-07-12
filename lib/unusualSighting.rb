#!/usr/bin/ruby
=begin
    Alamaze Unusual Sighting Module - This module contains classes that 
    pertain to unusual sightings.

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

class UnSightingInfo


   def initialize()
      @list=Hash.new
      @graphicsFile="#{$runRoot}/graphics/unusualSighting.gif"
      setupImages
   end

   def setupImages
      @images=Hash.new
      bigImage = TkPhotoImage.new
      bigImage.file = @graphicsFile
      @images[:big] =  bigImage
      @images[:small] = shrinkImage(bigImage)
   end

#  def addMapImages(canvas, loc)
#     commonTags=[ "UnusualS", "US-#{loc}" ]
#     TkcImage.new(canvas,@smallW/2,@smallH/2, 'image' => @smallImage, :tags => [commonTags, 'small'])
#     TkcImage.new(canvas,@bigW/2,@bigH/2, 'image' => @bigImage, :tags => [commonTags, 'big'])
#  end

   def addUS(line)
      (turn,junk,area,diff,desc)=line.split(',')
      @list[area]=UnusualSighting.new(area,diff,desc)
      return @list[area]
   end

   def getUniqueTag(area)
      return "US-#{area}"
   end

   def deleteUS(area)
      @list[area]=nil
      $canvas.delete( getUniqueTag(area) )
   end

   def markUS(area)
      @list[area]=UnusualSighting.new(area)
   end

   def getUS(area)
      return @list[area]
   end
 
   def drawUnusualSighting(size,x,y,loc)
     uniqueTag=getUniqueTag(loc)
     img = TkcImage.new($canvas,x,y, 'image' => @images[size], :tags => ['UnusualSighting', 'Marker', $offsets[size][:tag], uniqueTag ])
     return img
   end


   def drawEditDialog(area)
      us = getUS(area)
      if us == nil
         Tk::messageBox :message => "There is no unusual sighting at area  #{area}"
         return
      end

      $editUSDialog.destroy if TkWinfo.exist?($editUSDialog)
      $editUSDialog = TkToplevel.new($root) do
         title "Edit Unusual Sighting at #{area}"
      end

      frame = TkFrame.new($editUSDialog) do
         relief 'sunken'
         borderwidth 3
         background 'yellow'
         padx 10
         pady 10
      end
   
      difEntry  = addDialogRow(frame, "Difficulty", us.getDifficulty )
      descEntry = addDialogRow(frame, "Description", us.getDescription )

      TkButton.new(frame) do
         text "Apply"
         command (proc{ $unusualSightings.updateUS(area,difEntry,descEntry)})
         pack('fill' =>'both', 'expand' => 1)
      end

      frame.pack

   end

   def addDialogRow(frame, label, value)
      rowFrame = TkFrame.new(frame)

      TkLabel.new(rowFrame) do
         text "#{label} : "
         pack('side'=>'left')
      end
      entry = TkEntry.new(rowFrame) do
         width '30'
         pack('side'=>'left', 'fill' =>'x', 'expand' => 1)
      end
      entry.insert('end', value)
      rowFrame.pack('fill' =>'x', 'expand' => 1)
      return entry
   end


   def updateUS(area, difEntry, descEntry)
      difficulty = difEntry.get.strip.upcase.gsub(',','_')
      description = descEntry.get.gsub(',','_')
      appendText("entered #{difficulty} #{description} for US at #{area}\n")
      @list[area].update(difficulty,description)
      $editUSDialog.destroy if TkWinfo.exist?($editUSDialog)
   end

   def saveDataToFile(ofile)
      @list.keys.each do |key|
            @list[key].saveDataToFile(ofile)
      end
   end


end # class UnSightingInfo


class UnusualSighting
   def initialize(loc, difficulty=nil, description=nil)
       @loc = loc
       @difficulty=difficulty
       @description=description
   end

   def getLocation
      return @loc
   end

   def getDescription
      return @description
   end

   def getDifficulty
      return @difficulty
   end

   def update(difficulty, description)
       @difficulty=difficulty
       @description=description
   end

   def saveDataToFile(ofile)
      record=["0","U",@loc,@difficulty,@description].join(',')
      ofile.puts record
   end

end # class UnusualSighting
