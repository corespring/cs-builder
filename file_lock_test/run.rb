#!/usr/bin/env ruby

require 'timeout'
require 'fileutils'

#
# from: http://drawohara.com/post/5891548/ruby-checking-to-see-if-a-file-is-flocked
#
class File
  def flocked? &block
    status = flock LOCK_EX|LOCK_NB
    case status
      when false
        return true
      when 0
        begin
          block ? block.call : false
        ensure
          flock LOCK_UN
        end
      else
        raise SystemCallError, status
    end
  end
  alias_method "if_not_flocked", "flocked?"
end



f1 = File.open('foo', File::RDWR|File::CREAT, 0644)

f1.flock(File::LOCK_EX)

f2 = File.open('foo', File::RDWR|File::CREAT, 0644)

puts "locked: #{f2.flocked?}"

f1.flock(File::LOCK_UN)

puts "locked: #{f2.flocked?}"
