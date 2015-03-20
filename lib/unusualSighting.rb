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
      @graphicsFile="graphics/unusualSighting.gif"
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

end # class UnSightingInfo


class UnusualSighting
   def initialize(loc, difficulty=nil)
       @loc = loc
       @difficulty=difficulty
   end
end # class UnusualSighting
