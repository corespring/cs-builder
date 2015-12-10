require 'cs-builder/io/archive'
require 'cs-builder/log/logger'
require 'tmpdir'

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
  end

  describe "merge" do 

    def create_archive(name)
      dir = Dir.mktmpdir("tmp_dir")
      write_to_file(dir, name, name)
      @log.debug("files in dir: #{Dir["#{dir}/**"]}")
      `tar czvf #{dir}.tgz -C #{dir} .`
      @log.debug("files in tgz: #{`tar -ztvf #{dir}.tgz`}")
      "#{dir}.tgz"
    end

    it "merges archives together" do 
      one = create_archive("one.txt")
      two = create_archive("two.txt")
      three = create_archive("three.txt")
      out = Dir.mktmpdir("output_")
      merged = CsBuilder::IO::Archive.merge(out, {:force => false}, one, two, three)
      File.exists?(merged).should eql(true)
      expanded_dir = Dir.mktmpdir("expanded_")
      `tar xzvf #{merged} -C #{expanded_dir}`
      Dir.entries(expanded_dir).reject{|p| p == "." or p == ".."}.should eql(["one.txt", "two.txt", "three.txt"]) 
    end
  end
end