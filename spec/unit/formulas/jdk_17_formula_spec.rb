

describe "Jdk 1.7 Formula" do


  it "should build correctly" do

      root = Dir.pwd

      spec_dir = "spec/tmp/formula_1.7"

      expected_contents = {
        "./.profile.d/scala.sh" => "export PATH=\"/app/.jdk/bin:$PATH\"\n",
        "./system.properties" => "java.runtime.version=1.7\n"
      }

      FileUtils.rm_rf(spec_dir)
      FileUtils.mkdir_p(File.dirname(spec_dir))

      FileUtils.cp_r(".default-config", spec_dir)

      FileUtils.mkdir(File.join(spec_dir, "templates", "built"))
      Dir.chdir(File.join(spec_dir, "templates", "formulas"))

      `./jdk-1.7.formula ../built`

      Dir.chdir("../built")
      `mkdir out`
      `tar xvf jdk-1.7.tgz -C ./out`

      Dir.chdir("out")

      expected_contents.each do  |path, contents|
        IO.read(path).should eql(contents)
      end

      File.directory?(".jdk").should eql(true)

      Dir.chdir(root)

  end
end
