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

EXPLORED_MARKER_NOPC='X'
EXPLORED_MARKER_NOUS='@'
EXPLORED_MARKER_ALLCLEAR='!'
EXPLORED_MARKER_TEMP=4
EXPLORED_MARKER_US='U'

$explorationMarkerMap = {
   "NoPC"     => EXPLORED_MARKER_NOPC,
   "NoUS"     => EXPLORED_MARKER_NOUS,
   "AllClear" => EXPLORED_MARKER_ALLCLEAR,
   "US"       => EXPLORED_MARKER_US,
   "Temp"     => EXPLORED_MARKER_TEMP
}


def markExploredFromLB(lb, typeLB)
   unHighlight

   # Get Marker Type
   mt = typeLB.get( typeLB.curselection )
   appendText("Adding marker type [#{mt}]\n")
   marker = $explorationMarkerMap[mt]

   # Add Markers
   areaList = lb.get(0,'end')
   areaList.each do |area|
      case marker
      when EXPLORED_MARKER_NOPC
         $exploredAreas.push area.strip
      when EXPLORED_MARKER_NOUS
         $noUSAreas.push area.strip
      when EXPLORED_MARKER_ALLCLEAR
         $allClearAreas.push area.strip
      when EXPLORED_MARKER_US
         $unusualSightings.markUS(area)
      end
      addMapMarker(area,marker)
   end
   lb.delete(0,'end')
   $exploreDialog.destroy
end # markExploredFromLB

def enterAreas(entry,rightListBox)
   entryText = entry.get
   areaList = entryText.upcase.split(/\W/)
   areaList.each do |area|
      #next if area.size != 2
      rightListBox.insert('end',area)
      highlightTag("box-#{area}", false)
   end
   entry.delete(0,'end')
end # enterAreas

def createAddExploredDialog
   unHighlight
   $exploreDialog.destroy if TkWinfo.exist?($exploreDialog)
   $exploreDialog = TkToplevel.new($root) do
      title 'Where I Have Gone Before'
   end
   frame = TkFrame.new($exploreDialog) do
      relief 'sunken'
      borderwidth 3
      background 'darkgrey'
      padx 10
      pady 10
   end
   topFrame = TkFrame.new(frame)
   middleFrame = TkFrame.new(frame)
   bottomFrame = TkFrame.new(frame)
   leftLbFrame = TkFrame.new(middleFrame)
   rightLbFrame = TkFrame.new(middleFrame)
   buttonFrame = TkFrame.new(middleFrame)

   leftListBox = createScrollableListbox(leftLbFrame)
   rightListBox = createScrollableListbox(rightLbFrame)

   TkLabel.new(topFrame) do
      text 'Enter explored areas: '
      pack('side'=>'left')
   end

   entry = TkEntry.new(topFrame) do
      width '10'
      pack('side'=>'left', 'fill' =>'x', 'expand' => 0)
   end
   entry.bind('Return', proc { enterAreas(entry,rightListBox) } )




   TkButton.new(buttonFrame) do
      text "<-"
      command (proc{shiftValues(rightListBox,leftListBox,false)})
      pack('side' => 'top', 'fill' => 'both', 'expand' => 1)
   end
   TkButton.new(buttonFrame) do
      text "->"
      command (proc{shiftValues(leftListBox,rightListBox,true)})
      pack('side' => 'top', 'fill' => 'both', 'expand' => 1)
   end

   markerTypeBox = createExplorationMarkerTypeBox(buttonFrame)

   TkButton.new(bottomFrame) do
      text "Make it so!"
      command (proc{markExploredFromLB(rightListBox,markerTypeBox)})
      pack('side' => 'top', 'fill' => 'x', 'expand' => 1)
   end

   leftListBox.pack('side' => 'left')
   leftLbFrame.pack('side' => 'left')
   buttonFrame.pack('side' => 'left', 'fill' => 'both', 'expand' => 1)
   rightListBox.pack('side' => 'left')
   rightLbFrame.pack('side' => 'left')
   topFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 0)
   middleFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 1)
   bottomFrame.pack('side' => 'top', 'fill' => 'both', 'expand' => 0)
   frame.pack('fill' => 'both', 'expand' => 1)
end #createAddExploredDialog

def createScrollableListbox(inputFrame)
    frame = TkFrame.new(inputFrame)
    lb = TkListbox.new(frame) {
             selectmode 'multiple'
             width 5
             height 9
             pack('side'=>'left')
    }
    sb = TkScrollbar.new(frame) {
       command proc { |*args|
          lb.yview(*args)
       }
       pack('side' => 'left', 'fill' => 'y', 'expand' => 0)
    }
    lb.yscrollcommand(proc { |first,last|
                             sb.set(first,last) })
    frame.pack('fill' => 'both', 'expand' => 0)
    return lb
end

def createExplorationMarkerTypeBox(frame)

    lb = TkListbox.new(frame) {
             selectmode 'single'
             width 10
             height 5
             pack('side'=>'top')
    }

    %w(NoPC NoUS AllClear US Temp).each do |mtype|
       lb.insert('end', mtype)
    end

    lb.selection_set(0)

    return lb

end

def shiftValues(from,to,highlight)
   fromList = from.curselection
   while fromList.size > 0 do
      index = fromList.first
      area = from.get(index)
      to.insert('end', area)
      from.delete(index)
      fromList = from.curselection
      if highlight
         highlightTag("box-#{area}",false)
      else
         unHighlightTag("box-#{area}")
      end
   end
end

def drawNoUS(size,x,y,loc)
  x1 = x - ($offsets[size][:boxX]*0.10)
  y1 = y - ($offsets[size][:boxX]*0.10)
  x2 = x + ($offsets[size][:boxX]*0.10)
  y2 = y + ($offsets[size][:boxX]*0.10)
  uniqueTag="NoUS-#{loc}"
  oval = TkcOval.new($canvas, [x1,y1], [x2,y2] ,
                         :fill => 'orange', :outline => 'black',  'tags' => ['NoUS','Marker', $offsets[size][:tag], uniqueTag ])
  return oval
end

def drawNoPC(size,x,y,loc)
  x1 = x - ($offsets[size][:boxX]*0.10)
  y1 = y - ($offsets[size][:boxX]*0.10)
  x2 = x + ($offsets[size][:boxX]*0.10)
  y2 = y + ($offsets[size][:boxX]*0.10)
  uniqueTag="NoPC-#{loc}"
  oval = TkcOval.new($canvas, [x1,y1], [x2,y2] ,
                         :fill => 'red', :outline => 'black',  'tags' => ['NoPC','Marker', $offsets[size][:tag], uniqueTag ])
  return oval
end

def drawAllClear(size,x,y,loc)
  x1 = x - ($offsets[size][:boxX]*0.10)
  y1 = y - ($offsets[size][:boxX]*0.10)
  x2 = x + ($offsets[size][:boxX]*0.10)
  y2 = y + ($offsets[size][:boxX]*0.10)
  uniqueTag="AllClear-#{loc}"
  oval = TkcOval.new($canvas, [x1,y1], [x2,y2] ,
                         :fill => 'black', :outline => 'yellow',  'tags' => ['AllClear','Marker', $offsets[size][:tag], uniqueTag ])
  return oval
end

def drawTempMarker(size,x,y,loc)
  x1 = x - ($offsets[size][:boxX]*0.10)
  y1 = y - ($offsets[size][:boxX]*0.10)
  x2 = x + ($offsets[size][:boxX]*0.10)
  y2 = y + ($offsets[size][:boxX]*0.10)
  uniqueTag="Temp-#{loc}"
  oval = TkcOval.new($canvas, [x1,y1], [x2,y2] ,
                         :fill => 'purple', :outline => 'yellow',  'tags' => ['Temp','Marker', $offsets[size][:tag], uniqueTag ])
  return oval
end

