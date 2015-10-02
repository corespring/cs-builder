require 'cs-builder/cmds/core-command'
require 'cs-builder/cmds/clean-repos'
require 'cs-builder/io/safe-file-removal'
require 'fileutils'
require 'dotenv'

include CsBuilder::Commands
include CsBuilder::Io::SafeFileRemoval

Dotenv.load

describe "CleanRepos" do

  config_dir = "spec/tmp"
  tmp_path = File.join(config_dir, "repos/corespring/corespring-project")

  folder_old = "folder-old"
  folder_new = "folder-new"
  file_old = "file-old"
  file_new = "file-new"
  day = 5

  def create_dir(path)
    FileUtils::mkdir_p "#{path}"
  end

  def create_file(path)
    FileUtils.touch "#{path}"
  end

  def change_timestamp(path, day)
    day = 24 * 60 * 60 * (day + 1)
    FileUtils.touch "#{path}", :mtime => Time.now - day
  end

  def clean_up(debug, config_dir, day, slugs)
    cleaner = CleanRepos.new(debug, config_dir, day, slugs)
    cleaner.run(1)
  end

  it "creates old test folder" do
    create_dir(File.join(tmp_path, folder_old))
    expect(Dir.exists?(File.join(tmp_path, folder_old))).to be_truthy
  end

  it "checks old folder timestamp is old" do
    change_timestamp(File.join(tmp_path, folder_old), day)
    time_to_compare = Time.at(Time.now - day * 24 * 60 * 60)
    expect(File.mtime(File.join(tmp_path, folder_old)) < time_to_compare).to be_truthy
  end

  it "creates new test folder" do
    create_dir(File.join(tmp_path, folder_new))
    expect(Dir.exists?(File.join(tmp_path, folder_new))).to be_truthy
  end  

  it "creates new test file" do
    create_file(File.join(tmp_path, folder_new, file_new))
    expect(File.exists?(File.join(tmp_path, folder_new, file_new))).to be_truthy
  end

  it "creates old test file" do
    create_file(File.join(tmp_path, folder_old, file_old))
    expect(File.exists?(File.join(tmp_path, folder_old, file_old))).to be_truthy
  end

  it "checks old file timestamp is old" do
    change_timestamp(File.join(tmp_path, folder_old, file_old), day)
    time_to_compare = Time.at(Time.now - day * 24 * 60 * 60)
    expect(File.mtime(File.join(tmp_path, folder_old, file_old)) < time_to_compare).to be_truthy
  end

  it "checks for old folders and cleans their content" do
    clean_up("debug", config_dir, day, false)
    expect(Dir.exists?(File.join(tmp_path, folder_old))).to be_truthy
  end

  it "checks for old files and deletes them" do
    expect(File.exists?(File.join(tmp_path, folder_old, file_old))).to be_falsey
  end

end