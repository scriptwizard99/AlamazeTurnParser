=begin
    Alamaze Turn Parser - This is a GUI for displaying data parsed out
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


class GroupMovementPlotter

   def initialize
      @entry=nil
      @undoButton=nil
      @areaLabel=nil
      @areaList=Array.new
      @gname=nil
      @color='black'
   end

   def createDialog
      $gmPlotter.destroy if TkWinfo.exist?($gmPlotter)
      $gmPlotter = TkToplevel.new($root) do
         title 'Group Movement Plotter'
      end
      frame = TkFrame.new($gmPlotter) do
         relief 'sunken'
         borderwidth 3
         background 'darkgrey'
         padx 10
         pady 10
      end

      topFrame = TkFrame.new(frame) do
         relief 'raised'
         #borderwidth 1
         background 'black'
         padx 5
         pady 5
      end
      middleFrame = TkFrame.new(frame)
      bottomFrame = TkFrame.new(frame)

      TkLabel.new(topFrame) do
         text 'Enter Group Name :'
         #width 20
         pack('side' => 'left', 'anchor' => 'center' )
      end

      @entry = TkEntry.new(topFrame) do
         width '5'
         pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
      end
      @entry.bind('Return', proc { $gm.enterGroupName } )
      TkButton.new(topFrame) do
         text 'Apply'
         #width 10
         command( proc{$gm.enterGroupName})
         pack('side'=>'right', 'fill' => 'both', 'expand' => 1)
      end


      br1Frame = TkFrame.new(middleFrame)
      br2Frame = TkFrame.new(middleFrame)
      br3Frame = TkFrame.new(middleFrame)

      buttonHeight=3
      buttonWidth=8

      TkButton.new(br1Frame) do
         text 'NW'
         height buttonHeight
         width buttonWidth
         command( proc{$gm.addArea('NW')})
         pack('side'=>'left')
      end
      TkButton.new(br1Frame) do
         text 'N'
         height buttonHeight
         width buttonWidth
         command( proc{$gm.addArea('N')})
         pack('side'=>'left')
      end
      TkButton.new(br1Frame) do
         text 'NE'
         height buttonHeight
         width buttonWidth
         command( proc{$gm.addArea('NE')})
         pack('side'=>'left')
      end

      TkButton.new(br2Frame) do
         text 'W'
         height buttonHeight
         width buttonWidth
         command( proc{$gm.addArea('W')})
         pack('side'=>'left')
      end
      @undoButton = TkButton.new(br2Frame) do
         text 'UNDO'
         height buttonHeight
         width buttonWidth
         command( proc{$gm.undoLastArea()})
         pack('side'=>'left')
      end
      TkButton.new(br2Frame) do
         text 'E'
         height buttonHeight
         width buttonWidth
         command( proc{$gm.addArea('E')})
         pack('side'=>'left')
      end

      TkButton.new(br3Frame) do
         text 'SW'
         height buttonHeight
         width buttonWidth
         command( proc{$gm.addArea('SW')})
         pack('side'=>'left')
      end
      TkButton.new(br3Frame) do
         text 'S'
         height buttonHeight
         width buttonWidth
         command( proc{$gm.addArea('S')})
         pack('side'=>'left')
      end
      TkButton.new(br3Frame) do
         text 'SE'
         height buttonHeight
         width buttonWidth
         command( proc{$gm.addArea('SE')})
         pack('side'=>'left')
      end


      @areaLabel = TkLabel.new(bottomFrame) do
         text 'Areas :'
         #width 20
         #pack('side' => 'left', 'anchor' => 'w', 'fill'=>'x', 'expand'=>1 )
         pack('side' => 'left', 'anchor' => 'w')
      end

      topFrame.pack('side' => 'top')
      br1Frame.pack('side' => 'top', 'fill' => 'both', 'expand' => 1)
      br2Frame.pack('side' => 'top', 'fill' => 'both', 'expand' => 1)
      br3Frame.pack('side' => 'top', 'fill' => 'both', 'expand' => 1)
      middleFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 1)
      bottomFrame.pack('side' => 'top', 'fill'=>'x', 'expand'=>1 )
      frame.pack('fill' => 'both', 'expand' => 1)

      @areaList=Array.new

   end # end createDialog

   def enterGroupName()
      @gname = @entry.get.strip.upcase
      $gmPlotter.configure('title' => "Group Movement Plotter (#{@gname})")

      gid="#{@gname[1,2]}-#{@gname[0,3]}"
      group = $groupList.getGroupByID(gid)
      if group.nil? 
         appendText("Invalid group ID #{gid}\n")
         return
      end
      @color=$kingdomColors[@gname[1,2]];
      groupLoc = group.getLocOnTurn( $currentTurn )
      if groupLoc.nil?
         appendText("Invalid loc for #{@gname} on turn #{$currentTurn}\n")
         return
      end
      #$canvas.delete("GroupArrow")
      @areaList=[groupLoc]
      updateAreaListLabel
      highlightTag("box-#{groupLoc}", true)

   end

   def getAdjacentArea(loc,direction)
      area = loc[0,2]
      case direction
      when 'N'
         area[0] = ( area[0].ord() - 1).chr
      when 'S'
         area[0] = ( area[0].ord() + 1).chr
      when 'E'
         area[1] = ( area[1].ord() + 1).chr
      when 'W'
         area[1] = ( area[1].ord() - 1).chr
      when 'NE'
         area[0] = ( area[0].ord() - 1).chr
         area[1] = ( area[1].ord() + 1).chr
      when 'NW'
         area[0] = ( area[0].ord() - 1).chr
         area[1] = ( area[1].ord() - 1).chr
      when 'SE'
         area[0] = ( area[0].ord() + 1).chr
         area[1] = ( area[1].ord() + 1).chr
      when 'SW'
         area[0] = ( area[0].ord() + 1).chr
         area[1] = ( area[1].ord() - 1).chr
      end
      #appendText("moving #{direction} from #{loc} is #{area}\n")
      return area
   end

   def updateAreaListLabel()
      @areaLabel.configure('text' => "Areas : #{@areaList.join(', ')}")
   end

   def addArea(direction)
      return if @areaList.nil? or @areaList.empty?
      newArea = getAdjacentArea( @areaList.last, direction)
      @areaList.push(newArea)
      updateAreaListLabel
      drawCurvyLine("#{@gname}-Arrow", @areaList)
   end
  
   def undoLastArea()
      return if @areaList.nil? or @areaList.empty?
      @areaList.pop unless @areaList.size < 2
      updateAreaListLabel
      drawCurvyLine("#{@gname}-Arrow", @areaList)
   end


end # end class GroupMovementPlotter


# Draws both the big and small arrows
def drawCurvyLine(uniqueTag, areaList)
   $canvas.delete(uniqueTag)
   return if areaList.size < 2
   [:small,:medium, :big].each do |size|
      locList = Array.new
      areaList.each do |area|
         locList.push( getCenter(area,size))
      end
      TkcLine.new($canvas, locList, 
                   :width => $offsets[size][:thickLine],
                   :splinesteps => 100,
                   :arrow => 'last',
                   :fill =>  @color,
                   :smooth => true,
                   :tags => ['GroupArrow','Marker', uniqueTag, $offsets[size][:tag] ])
   end
   $canvas.raise($currentTopTag)
end
