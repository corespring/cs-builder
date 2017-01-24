#!/usr/bin/env ruby

##
## One time slug template installer - once installed no need to run this again.
## Note - the jdk 1.8 installer via the heroku scripts was causing issues
##



out_dir = ARGV[0]
version = ARGV[1]


versions = {
  "1.8" => "http://heroku-jdk.s3.amazonaws.com/openjdk1.8.0_b107.tar.gz",
  "1.7" => "http://heroku-jdk.s3.amazonaws.com/openjdk1.7.0_45.tar.gz"
}

raise "Can't find jdk url for: #{version}, supported versions: #{versions.keys.join(", ")}" unless versions.has_key?(version)

archive_name = "jdk-#{version}.tgz"
out_path = "#{out_dir}/#{archive_name}"

puts "---------------------- Installing JDK from formula ---------------------"
puts "-- version: #{version}"
puts "-- will create template here: #{out_path}"
puts "------------------------------------------------------------------------"

`rm -fr tmp`
`mkdir tmp`
JDK_URL=versions[version]
jdk_tar_ball="tmp/jdk.tar.gz"
jdk_dir="tmp/.jdk"
`mkdir -p #{jdk_dir}`
`curl --location #{JDK_URL} --output #{jdk_tar_ball}`
`tar pxzf #{jdk_tar_ball} -C "#{jdk_dir}"`
`rm #{jdk_tar_ball}`
`echo "#{version}" > #{jdk_dir}/version`
`echo "java.runtime.version=#{version}" >> tmp/system.properties`
`mkdir tmp/.profile.d`

File.open("tmp/.profile.d/scala.sh", 'w') { |file|
  file.write "export PATH=\"/app/.jdk/bin:$PATH\""
}

File.open("tmp/.profile.d/jvmcommon.sh", 'w') { |file|
  # Patch for CVE-2013-1537
  file.write "export JAVA_TOOL_OPTIONS=\"$JAVA_TOOL_OPTIONS -Djava.rmi.server.useCodebaseOnly=true\""
}

`tar czvf #{archive_name} -C tmp .`
`mv #{archive_name} #{out_path}`
`rm -fr tmp`

puts "--------------------------- Done -------------------------------------"
