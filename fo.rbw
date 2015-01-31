#!/usr/bin/env rubyw


require 'tk'

def openDocument
  filetypes = [["All Files", "*"], ["XML Documents", "*.xml"]]
  filename = Tk.getOpenFile('filetypes' => filetypes,
                            'parent' => self)
  if filename != ""
    #loadDocument(filename)
    puts filename
  end
end


root = TkRoot.new
button = TkButton.new(root) {
   text  "wtf"
#   command proc { puts "i said hello" }
   command proc { openDocument }
}
button.pack
Tk.mainloop


