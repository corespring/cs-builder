require 'cs-builder/io/file-lock'
require 'cs-builder/io/safe-file-removal'

include CsBuilder::Io

include SafeFileRemoval

describe SafeFileRemoval do 

  it "should not remove locked files" do 
    path ="spec/tmp/safe-file-1" 
    FileUtils.mkdir_p(File.dirname(path))
    f1 = File.new(path, 'w')
    f1.flock(File::LOCK_EX)
    safe_delete(path)
    File.exists?(path).should be(true)
    f1.flock(File::LOCK_UN)
    File.delete(f1)
  end

  it "should remove unlocked files" do 
    path ="spec/tmp/safe-file-2" 
    FileUtils.mkdir_p(File.dirname(path))
    File.new(path, 'w')
    safe_delete(path)
    File.exists?(path).should be(false)
  end

  it "should safely remove all files in dir - if all unlocked" do 

    path = "spec/tmp/safe-dir"

    FileUtils.rm_rf(path)
    FileUtils.mkdir_p(path)

    `echo "one" >> #{path}/one`
    `echo "two" >> #{path}/two`
    `echo "three" >> #{path}/three`
    safely_remove_all_except("#{path}/two")
    Dir["#{path}/*"].length.should eql(1)

  end

  it "should safely one file in dir - if all unlocked" do 

    path = "spec/tmp/safe-dir"

    FileUtils.rm_rf(path)
    FileUtils.mkdir_p(path)

    `echo "one" >> #{path}/one`
    `echo "two" >> #{path}/two`
    `echo "three" >> #{path}/three`

    three = File.new("#{path}/three")
    three.flock(File::LOCK_EX)
    safely_remove_all_except("#{path}/two")
    Dir["#{path}/*"].length.should eql(2)
    three.flock(File::LOCK_UN)

  end

end