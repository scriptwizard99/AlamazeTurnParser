#!/usr/bin/env rubyw

require 'tk'

$canvas = nil

#$boldFont = TkFont.new( "weight" => "bold")
$boldFont = TkFont.new( "size" => '30', "weight" => "bold")


def shrinkImage(image)
   w = image.width
   h = image.height
   puts "w=#{w} h=#{h}"

   newImage = TkPhotoImage.new
   newImage.copy(image, 
                 :from => [0, 0, w, h],
                 :subsample => [3,3])
   w = newImage.width
   h = newImage.height
   puts "w=#{w} h=#{h}"
   return newImage
end

def setupBM
   $bigBM = TkBitmapImage.new('file'=>"./ABig.xbm", 'foreground' => 'red')
   $smallBM = TkBitmapImage.new('file'=>"./ASmall.xbm", 'foreground' => 'red')
   #$bigBM.file = "./city.xbm"
end

def setupImage
   $bigImage = TkPhotoImage.new
   $bigImage.file = "./alamaze-resurgent.gif"
   $bigW = $bigImage.width
   $bigH = $bigImage.height

   $smallImage = shrinkImage($bigImage)
   $smallW = $smallImage.width
   $smallH = $smallImage.height
end

def zoomIn
   #$canvas.scale('box', 0, 0, '0.5', '0.5' )
   #$mapImage.zoom(2,2)
   $canvas.configure(:scrollregion => [0,0,$bigW,$bigH])
   $canvas.raise('big')
end

def zoomOut
   w = $smallImage.width
   h = $smallImage.height
   $canvas.configure(:scrollregion => [0,0,$smallW,$smallH])
   $canvas.raise('small')
   $canvas.xview('scroll', 0, 'units')
   $canvas.yview('scroll', 0, 'units')
end



def createCanvas(frame)

   hframe = TkFrame.new(frame)

   $canvas = canvas =TkCanvas.new(hframe) do
         border 0
         width $smallW
         height $smallH
        xscrollincrement 1
        yscrollincrement 1
   end

   xscroll = TkScrollbar.new(frame) do
      background 'green'
      command do |*args|
         canvas.xview *args
      end
      orient 'horiz'
   end
   
   yscroll = TkScrollbar.new(hframe) do
      background 'red'
      command do |*args|
         canvas.yview *args
      end
      orient 'vertical'
   end
   

   TkcImage.new($canvas,$smallW/2,$smallH/2, 'image' => $smallImage, :tags => 'small')
   TkcImage.new($canvas,$bigW/2,$bigH/2, 'image' => $bigImage, :tags => 'big')
   $canvas.raise('big')
   canvas.configure(:scrollregion => [0,0,$bigW,$bigH])

   hframe.pack(:expand => 'yes', :fill => 'both')
#  frame.pack(:expand => 'no', :fill => 'x')
   $canvas.pack( :side => 'left', :expand => 'no', :fill => 'none')
   xscroll.pack( :side => 'bottom', :expand => 'no', :fill => 'x')
   yscroll.pack( :side => 'right', :expand => 'no', :fill => 'y')

      canvas.xscrollcommand do |first, last|
        xscroll.set(first, last)
      end
      canvas.yscrollcommand do |first, last|
        yscroll.set(first, last)
      end

      $root.bind "Key-Right" do
        canvas.xview "scroll", 10, "units"
      end

      $root.bind "Key-Left" do
        canvas.xview "scroll", -10, "units"
      end

      $root.bind "Key-Down" do
        canvas.yview "scroll", 10, "units"
      end

      $root.bind "Key-Up" do
        canvas.yview "scroll", -10, "units"
      end

      $root.bind "Control-Up" do
        zoomIn
      end

      $root.bind "Control-Down" do
        zoomOut
      end

  bigFrameX=53
  bigFrameY=40
  bigBoxX=80.5
  bigBoxY=60.45

  sFrameX=17
  sFrameY=14
  sBoxX=26.8
  sBoxY=20.1

  addRedBlock('AA')
  addRedBlock('AZ')
  addRedBlock('FF')
  addRedBlock('KH')
  addRedBlock('QT')
  addRedBlock('AM')
  addRedBlock('YY')
  addRedBlock('ZA')
  addRedBlock('ZZ')
  addMapMarkers('BA',"T")
  addMapMarkers('BB',"T")
  addMapMarkers('BC',"T")
  addMapMarkers('KB',"T")
  addMapMarkers('DD',"3TR")
  addMapMarkers('DD',"1AN")
end


def initOffsets
   $offsets = Hash.new
   $offsets[:big] = Hash.new
   $offsets[:big][:frameX]=53
   $offsets[:big][:frameY]=40
   $offsets[:big][:boxX]=80.5
   $offsets[:big][:boxY]=60.45
   $offsets[:big][:tag]='big'
   $offsets[:big][:bm]=$bigBM
   $offsets[:big][:font]= TkFont.new( "size" => '30', "weight" => "bold")
   $offsets[:small] = Hash.new
   $offsets[:small][:frameX]=17
   $offsets[:small][:frameY]=14
   $offsets[:small][:boxX]=26.8
   $offsets[:small][:boxY]=20.1
   $offsets[:small][:tag]='small'
   $offsets[:small][:bm]=$smallBM
   $offsets[:small][:font]= TkFont.new( "size" => '12', "weight" => "bold")
end

def drawABlock(size,x,y)
  box = TkcRectangle.new($canvas, $offsets[size][:frameX] + ($offsets[size][:boxX]*x), 
                                  $offsets[size][:frameY] + ($offsets[size][:boxY]*y),
                                  $offsets[size][:frameX] + ($offsets[size][:boxX]*(x+1)), 
                                  $offsets[size][:frameY] + ($offsets[size][:boxY]*(y+1)),
                                  :outline => 'black', :tags=>['box',  $offsets[size][:tag] ])
  return box
end

# loc is in AA-ZZ
def addRedBlock(loc)
   x = loc[0].ord - 'A'.ord
   y = loc[1].ord - 'A'.ord
   drawABlock(:big, x, y)
   drawABlock(:small, x, y)
end


def addMarker(size,x,y,marker)

   # Center
   x = $offsets[size][:frameX] + ($offsets[size][:boxX]*x) + $offsets[size][:boxX]/2.0
   y = $offsets[size][:frameY] + ($offsets[size][:boxY]*y) + $offsets[size][:boxY]/2.0

   t = TkcText.new($canvas, x, y, 'text' => marker, 'tags' => [marker,'Marker', $offsets[size][:tag] ],
                   'fill' => 'black', 'font' => $offsets[size][:font] )
   #t.bind('1', proc { boxClick loc } )

   TkcImage.new($canvas,x,y, 'image' => $offsets[size][:bm] , :tags => $offsets[size][:tag] )

   drawArmy(size,x,y)

end

def addMapMarkers(loc,marker)
   xPart = loc[0].ord - 'A'.ord
   yPart = loc[1].ord - 'A'.ord
   addMarker(:big, xPart, yPart, marker)
   addMarker(:small, xPart, yPart, marker)
end


def drawArmy(size,x,y)
   p = TkcPolygon.new($canvas, 
                      x +  $offsets[size][:boxX]/2.0, y +  $offsets[size][:boxY]/2.2,
                      x -  $offsets[size][:boxX]/4.0, y +  $offsets[size][:boxY]/3.5,
                      x -  $offsets[size][:boxX]/2.0, y,
                      x -  $offsets[size][:boxX]/4.0, y -  $offsets[size][:boxY]/3.5,
                      x +  $offsets[size][:boxX]/2.0, y -  $offsets[size][:boxY]/2.2,
                      x -  $offsets[size][:boxX]/4.0, y,
                      :smooth => 'true',
                      :fill => 'green', :outline => 'black', 
                      :tags => $offsets[size][:tag] )
end


#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------

programName="Alamaze Map Test"
$root = TkRoot.new { title programName }

$offsets=0
setupBM
initOffsets
frame = TkFrame.new($root)
setupImage
createCanvas(frame)
frame.pack(:expand => 'yes', :fill => 'both')
zoomOut

   TkcImage.new($canvas,40,40, 'image' => $bigBM, :tags => 'big')
   $bigBM.configure('foreground' => 'blue')
   TkcImage.new($canvas,80,80, 'image' => $bigBM, :tags => 'big')

Tk.mainloop
