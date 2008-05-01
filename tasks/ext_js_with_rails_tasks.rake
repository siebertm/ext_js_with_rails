require 'yaml'
require File.join(File.dirname(__FILE__), "../lib/ext_js_with_rails.rb")

namespace :js do 
  def config
    ExtJsWithRails::Config
  end
  
  
  desc "Builds the js library"
  task :dist do
    $:.unshift File.join(File.dirname(__FILE__), '../lib')
    require 'protodoc'
    require 'fileutils'
    require "active_support"
    FileUtils.mkdir_p config.app_dist_dir

    Dir.chdir(config.app_src_dir) do
      File.open(File.join(config.app_dist_dir, config.app_file_name), 'w+') do |dist|
        dist << Protodoc::Preprocessor.new(config.main_file)
      end
    end
  end
  
  def bindir
    File.expand_path(File.join(File.dirname(__FILE__), "..", "bin"))
  end
  
  def minify(orig, minified)
    cmd = [
      "java -jar",
      "#{bindir}/yuicompressor/build/yuicompressor-2.3.5.jar",
      "--preserve-semi",
      "--charset utf-8",
      "--line-break 8000",
      "-o #{minified}",
      "#{orig}"
    ]
    
    system(cmd.join(' '))
  end
  
  
  
  def jslint(*files)
    cmd = [
      "cd #{config.app_src_dir} && java -jar",
      "#{bindir}/yuicompressor/lib/rhino-1.6R7.jar",
      "#{bindir}/jslint-rhino.js",
      files
    ].flatten
    system(cmd.join(' '))
  end
  
  
  
  desc "minifies using yuicompressor (requires java)"
  task :minify do
    orig = "#{config.app_dist_dir}/#{config.app_file_name}"
    minified = "#{config.app_dist_dir}/#{config.app_min_file_name}"
    
    puts "minfiying..."
    minify(orig, minified)
  end
  
  
  
  desc "checks all javascript files with jslint (requires java)"
  task :lint do
    if ARGV.length < 2
      files = Dir.glob("#{config.app_src_dir}/**/*.js").map do |fn|
        fn.gsub(/^#{config.app_src_dir}\//, '')
      end
    else
      files = ARGV
      files.shift
      files = files.map do |fn|
        fn = File.expand_path(fn)
        fn.gsub(/^#{config.app_src_dir}\//, '')
      end
    end
    files.reject! { |f| f == config.main_file }
    
    jslint(files)
  end
  
  
  task :autobuild => [:dist, :lint] do
  end
  
  desc 'Setup extjs in your rails application'
  task :setup do
    script_dest = "#{RAILS_ROOT}/script/js_autobuild"
    script_src = File.dirname(__FILE__) + "/../script/js_autobuild"

    FileUtils.chmod 0774, script_src

    defaults = {
      :app_name => "app",
      :root_dir => "public/javascript",
      :src_dir => "src"
    }

    config_dest = "#{RAILS_ROOT}/config/ext_js_with_rails.yml"

    unless File.exists?(config_dest)
        puts "Copying ext_js_with_rails.yml config file to #{config_dest}"
        File.open(config_dest, 'w') { |f| f.write(YAML.dump(defaults)) }
    end

    unless File.exists?(script_dest)
        puts "Copying js_autobuild.yml script to #{script_dest}"
        FileUtils.cp_r(script_src, script_dest)
    end

    app_dest = File.join(RAILS_ROOT, config[:root_dir])
    unless File.exists?(app_dest)
      puts "Creating #{app_dest}"
      FileUtils.mkdir(app_dest)
    end

    src_dest = File.join(app_dest, config[:src_dir])
    unless File.exists?(src_dest)
      puts "Creating #{src_dest}"
      FileUtils.mkdir(src_dest)
    end
  end

  desc 'Remove extjs from your rails application'
  task :remove do
    script_src = "#{RAILS_ROOT}/script/js_autobuild"

    if File.exists?(script_src)
        puts "Removing #{script_src} ..."
        FileUtils.rm(script_src, :force => true)
    end
  end
  
end