#!/usr/bin/ruby
=begin
    Alamaze High Council Module - This module contains classes that 
    pertain to issues that cone before the high council.

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

class HighCouncilIssueList


   def initialize()
      @list=Array.new
   end

   def addIssue(line)
      (turn,junk,who,status,issue,votes)=line.split(',',6)
      return unless @list[turn.to_i].nil?
      @list[turn.to_i]=HighCouncilIssue.new(turn,who,status,issue,votes)
      return @list[turn.to_i]
   end

   def getIssue(turn)
      return @list[turn.to_i]
   end

   def printRecords
      appendTextWithTag("History of High Council Issues\n\n", TEXT_TAG_TITLE)
      printHeader
      @list.each do |issue|
         next if issue.nil?
         line=issue.toString
         appendText(line)
      end

      tagText($textBox,"PASSED",TEXT_TAG_GOOD)
      tagText($textBox,"COMMEND",TEXT_TAG_GOOD)
      tagText($textBox,"ENDORSEMENT",TEXT_TAG_GOOD)
      tagText($textBox,"UP",TEXT_TAG_GOOD)
      tagText($textBox,"YEA",TEXT_TAG_GOOD)
      tagText($textBox,"SECRET",TEXT_TAG_WARNING2)
      tagText($textBox,"FAILED",TEXT_TAG_DANGER)
      tagText($textBox,"NAY",TEXT_TAG_DANGER)
      tagText($textBox,"DOWN",TEXT_TAG_DANGER)
      tagText($textBox,"EXPELLED",TEXT_TAG_DANGER)
      tagText($textBox,"CONDEMNED",TEXT_TAG_DANGER)
      tagText($textBox,"SANSCTIONS",TEXT_TAG_DANGER)
   end 

   def printHeader
      appendTextWithTag("Trn Who Status                       Issue                                                        Votes\n",TEXT_TAG_HEADING)
      appendTextWithTag("--- --- ------ -------------------------------------------------------------- ----------------------------------------\n",TEXT_TAG_HEADING)
   end

 
   def saveDataToFile(ofile)
      @list.each do |issue|
         next if issue.nil?
         issue.saveDataToFile(ofile)
      end
   end


end # class HighCouncilInfo


class HighCouncilIssue
   def initialize(turn,who,status,issue,votes)
       @turn = turn
       @who = who
       @status=status
       @issue=issue
       @votes=votes.strip
   end

   def toString
      line=sprintf("%3s %-3s %-6s %-60s %s\n",
                   @turn,
                   @who,
                   @status,
                   @issue,
                   @votes)
      return line
    end



   def saveDataToFile(ofile)
      record=[@turn,"H",@who,@status,@issue,@votes].join(',')
      ofile.puts record
   end

end # class HighCouncilIssue
