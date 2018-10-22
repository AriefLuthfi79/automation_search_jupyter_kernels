require 'colorize'
require 'uri'
require 'net/http'
require 'fileutils'

USER = `whoami`.strip.freeze
ENVIRONMENT = {
  java: "https://github.com/SpencerPark/IJava.git",
  php: "https://litipk.github.io/Jupyter-PHP-Installer/dist/jupyter-php-installer.phar",
  javascript: "sudo npm install -g ijavascript"
}.freeze

def get_kernels(lang, env)
  return if lang.nil?

  if env.key?(lang) && lang.to_s.freeze == 'java'.freeze
    system "git clone #{env[:java]}"
    if File.directory? 'IJava'
      FileUtils.cd 'IJava' do
        system 'chmod u+x gradlew && ./gradlew' 
      end
    end
  elsif lang.to_s.freeze == "javascript"
    system env[lang] 
    system 'ijsinstall'
  else
    puts "Downloading binary file (phar)"
    sleep 1
    download_phar_php(env)
    puts "Download successfully"
    system 'chmod u+x jupyter-php-installer.phar && ./jupyter-php-installer.phar install -vvv' unless found_program('php').nil?
  end
  
end

def download_phar_php(env)
  begin
    uri = URI.parse("#{env[:php]}")
    response = Net::HTTP.get(uri)
    get_filename = env[:php].split("/") 
    username = `whoami`.strip
    File.write("/home/#{username}/#{get_filename[5]}", response)
  rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
         Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
    puts e
  end
end

def found_program(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  return nil
end

puts "# " * 20
puts "  Automasi jupyter for Logic Pondok IT ".colorize(:blue)
puts "# " * 20

puts "\nChecking Anaconda directory...".colorize(:green)
sleep 1

FileUtils.cd "/home/#{USER}" do
  if File.directory? 'anaconda3'
    puts "Anaconda was found"
    puts %{
         Choose your Programming Langguage:
            1. PHP
            2. Java
            3. Javascript
    }.colorize(:yellow)
    print "Your programming langguage is : ".colorize(:blue)
    lang = gets.chomp.to_sym
    get_kernels(lang, ENVIRONMENT) 
  end
end

