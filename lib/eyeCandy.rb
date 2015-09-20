#!/usr/bin/ruby
=begin
    Alamaze EyeCandy Module - This module contains classes that 
    pertain to eye candy icons that appear on the map to help
    make certain events easier to visualize.

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

CANDY_MARKER='K'

CANDY_TYPE_EYE='eye'
CANDY_TYPE_DAGGER='dagger'
CANDY_TYPE_CLOAK='cloak'

$eyeCandyTypes = [ CANDY_TYPE_EYE, CANDY_TYPE_DAGGER, CANDY_TYPE_CLOAK ]

class EyeCandyList


   def initialize()
      @iconList=Hash.new
      $eyeCandyTypes.each do |type|
         @iconList[type]=EyeCandyIcon.new(type)
      end
      @infoList=Array.new
   end


   def drawEyeCandy(size,x,y,loc,type)
      @iconList[type].drawEyeCandy(size,x,y,loc)
   end

   def addEyeCandy(turn,loc,type)
      @infoList.push EyeCandyInfo.new(turn,loc,type)
   end

   def showAllCandy
      @infoList.each do |candy|
         turn = candy.getTurn
         if turn == $currentTurn
            addMapMarker( candy.getLocation, CANDY_MARKER, candy.getType)
         end
      end
      $canvas.raise($currentTopTag)
   end

end # class EyeCandyList


class EyeCandyIcon
   def initialize(type)
      @type = type
      @graphicsFile="#{$runRoot}/graphics/#{type}.gif"
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

   def getType
      return @type
   end

   def drawEyeCandy(size,x,y,loc)
     img = TkcImage.new($canvas,x,y, 'image' => @images[size], :tags => ['EYECANDY', "EyeCandy-#{@type}", 'Marker', $offsets[size][:tag] ])
     return img
   end

end # class EyeCandyIcon

class EyeCandyInfo
   def initialize(turn, loc, type)
       @turn = turn
       @loc = loc
       @type=type
   end

   def getTurn
      return @turn
   end

   def getLocation
      return @loc
   end

   def getType
      return @type
   end
end

