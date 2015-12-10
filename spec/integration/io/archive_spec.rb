require 'cs-builder/io/archive'
require 'cs-builder/log/logger'
require 'tmpdir'
require_relative '../helpers/dir'

describe CsBuilder::IO::Archive do  

  CsBuilder::Log.set_config({
    "shell" => "DEBUG",
    "spec" => "DEBUG",
    "archive" => "DEBUG"
    })
 
  before(:all) do 
    @log = CsBuilder::Log.get_logger("spec")
  end
 
  def write_to_file(dir, name, contents)
    File.open(File.join(dir, name), 'w') { |file| file.write(contents) }
  end 
  describe "create" do 

    it "creates the archive" do 
      dir = Dir.mktmpdir("spec_")
      destination_dir = Dir.mktmpdir("destination_")
      destination = File.join(destination_dir, "out.tgz")
      write_to_file(dir, "one.txt", "one")
      write_to_file(dir,"two.txt", "two")
      out_path = CsBuilder::IO::Archive.create(dir, destination, ["one.txt"])
      out_path.should eql(destination)
      contents = `tar -ztf #{out_path}`.chomp
      @log.debug("content: #{contents}")
      expected = <<-EOF
./
./one.txt
EOF
      contents.should eql(expected.chomp)
    end

    it "creates the parent directory of the out path if it doesn't exist" do 
      dir = Dir.mktmpdir("spec_")
      write_to_file(dir, "one.txt", "one")
      write_to_file(dir,"two.txt", "two")
      destination_dir = Dir.mktmpdir("destination_")
      destination = File.join(destination_dir, "some", "dir", "out.tgz")
      File.exists?(destination).should eql(false)
      File.exists?(File.dirname(destination)).should eql(false)
      CsBuilder::IO::Archive.create(dir, destination, ["one.txt"])
      File.exists?(destination).should eql(true)
      File.exists?(File.dirname(destination)).should eql(true)
    end
  end

  describe "merge" do 

    before(:all) do 
      @one = create_archive("one.txt")
      @two = create_archive("two.txt")
      @three = create_archive("three.txt")
    end
    
    def create_archive(name)
      dir = Dir.mktmpdir("tmp_dir")
      write_to_file(dir, name, name)
      @log.debug("files in dir: #{Dir["#{dir}/**"]}")
      `tar czvf #{dir}.tgz -C #{dir} .`
      @log.debug("files in tgz: #{`tar -ztvf #{dir}.tgz`}")
      "#{dir}.tgz"
    end

    it "merges archives together" do 
      out = Dir.mktmpdir("output_")
      merged = CsBuilder::IO::Archive.merge(out, {:force => false}, @one, @two, @three)
      File.exists?(merged).should eql(true)
      expanded_dir = Dir.mktmpdir("expanded_")
      `tar xzvf #{merged} -C #{expanded_dir}`
      Helpers::Dir.entries(expanded_dir).should eql(["one.txt", "two.txt", "three.txt"]) 
    end

    it "puts the contents in the root_dir" do 
      out = Dir.mktmpdir("output_")
      merged = CsBuilder::IO::Archive.merge(out, {:root_dir => "app", :force => false}, @one, @two, @three)
      File.exists?(merged).should eql(true)
      expanded_dir = Dir.mktmpdir("expanded_")
      `tar xzvf #{merged} -C #{expanded_dir}`
      Helpers::Dir.entries(expanded_dir).should eql(["app"])
      Helpers::Dir.entries("#{expanded_dir}/app").should eql(["one.txt", "two.txt", "three.txt"]) 
    end
  end
end