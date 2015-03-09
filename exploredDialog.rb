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


def markExploredFromLB(lb)
   unHighlight
   areaList = lb.get(0,'end')
   areaList.each do |area|
      $exploredAreas.push area.strip
      addColoredMapMarker(area,EXPLORED_MARKER,EXPLORED_COLOR)
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

   TkButton.new(bottomFrame) do
      text "Make it so!"
      command (proc{markExploredFromLB(rightListBox)})
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

def drawNoUS(size,x,y)
  x1 = x - ($offsets[size][:boxX]*0.10)
  y1 = y - ($offsets[size][:boxX]*0.10)
  x2 = x + ($offsets[size][:boxX]*0.10)
  y2 = y + ($offsets[size][:boxX]*0.10)
  oval = TkcOval.new($canvas, [x1,y1], [x2,y2] ,
                         :fill => 'red', :outline => 'yellow',  'tags' => ['NoUS','Marker', $offsets[size][:tag] ])
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

