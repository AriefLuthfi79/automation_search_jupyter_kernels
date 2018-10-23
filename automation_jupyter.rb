require 'colorize'
require 'uri'
require 'net/http'
require 'fileutils'

URI_BASE = "https://raw.githubusercontent.com/moslog/logic-lomba-template-notebook/master/template.ipynb"
USER = `whoami`.strip.freeze
ENVIRONMENT = {
  java: "https://github.com/SpencerPark/IJava.git",
  php: "https://litipk.github.io/Jupyter-PHP-Installer/dist/jupyter-php-installer.phar",
  javascript: "sudo npm install -g ijavascript"
}.freeze

spinner = Enumerator.new do |e|
  loop do
    e.yield '|'.colorize(:red)
    e.yield '/'.colorize(:orange)
    e.yield '-'.colorize(:blue)
    e.yield '\\'.colorize(:green)
  end
end

def get_kernels(lang, env)
  return if lang.nil?

  if env.key?(lang) && lang.to_s.freeze == 'java'.freeze
    system "git clone #{env[:java]}" unless File.directory? 'IJava'
    FileUtils.cd 'IJava' do
      system 'chmod u+x gradlew && ./gradlew' 
    end
  elsif lang.to_s.freeze == "javascript"
    puts "Configuring system..."
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
  rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
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

def get_request_from_git(raw)
  uri = URI.parse(raw)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true if uri.scheme == "https"
  http.start do |h|
    response = h.request(Net::HTTP::Get.new(uri.request_uri))
    File.open("Untitled.json", 'a') { |f| f.puts response.body } 
  end
end

puts `clear`
puts "# " * 20
puts "  Optimization jupyter for Logic Pondok IT ".colorize(:blue)
puts "# " * 20


puts "\nChecking Anaconda directory...".colorize(:green)
sleep 1

FileUtils.cd "/home/#{USER}" do
  if File.directory? 'anaconda3'
    puts "Anaconda was found".colorize(:red)
    puts %{
         Choose your Programming Langguage:
            1. PHP
            2. Java
            3. Javascript
    }.colorize(:yellow)
    print "Your programming langguage is : ".colorize(:blue)
    lang = gets.chomp.to_sym
    get_kernels(lang, ENVIRONMENT) 
    puts "Generate file json"
    
    1.upto(100) do |i|
      progress = "=" * (i/5) unless i < 5
      printf("\rCombined: [%-20s] %d%% %s", progress, i, spinner.next)
      sleep(0.1)
    end
    get_request_from_git(URI_BASE)
  end
end

