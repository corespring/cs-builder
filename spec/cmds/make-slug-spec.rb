require 'cs-builder/cmds/make-slug'

include CsBuilder::Commands

describe MakeSlug do

  def add_template(dir, template_name)

    formula = File.join(dir, "templates", "formulas", "#{template_name}.formula")
    FileUtils.mkdir_p(File.dirname(formula))
    File.open(formula, 'w') do |f|
      content= <<-EOF
      #!/usr/bin/env bash
      # The first param ($1) is the path to the build templates folder
      DIR=$1
      echo "Template" >> template.txt
      tar czvf ./#{template_name}.tgz template.txt
      ls -la
      ls -la ..
        echo "Move to $1/#{template_name}.tgz"
      mv #{template_name}.tgz $1/#{template_name}.tgz
      rm template.txt
      echo "Done - #{template_name}"
      exit 0
      EOF
      f.write(content)
    end

  end

  def mk_binary
    `echo "binary" >> spec/tmp/binary.txt`
    `tar czvf spec/tmp/binary.tgz -C spec/tmp binary.txt`
    FileUtils.rm_rf "spec/tmp/binary.txt"
    "spec/tmp/binary.tgz" 
  end

  it "should make a slug" do

    config_dir = "spec/tmp/make-slug"
    FileUtils.rm_rf(config_dir)
    FileUtils.mkdir_p(config_dir)

    add_template(config_dir, "test-template")

    binary = mk_binary
    cmd = MakeSlug.new("DEBUG", File.expand_path(config_dir))
    out = cmd.run({
                    :binary => File.expand_path(binary),
                    :template => "test-template",
                    :output => "#{config_dir}/slugs/org/repo/branch/build-1.tgz"
    })

    out.should eql("#{config_dir}/slugs/org/repo/branch/build-1.tgz")

    extracted = File.dirname(out)
    puts "-> #{out}"
    `tar -ztvf #{out}`
    `tar xvf #{out} -C #{extracted}`
    IO.read(File.join(extracted, "app", "template.txt")).should eql "Template\n"
    IO.read(File.join(extracted, "app", "binary.txt")).should eql "binary\n"
    FileUtils.rm_rf("spec/mock/build-from-file")
  end

end
