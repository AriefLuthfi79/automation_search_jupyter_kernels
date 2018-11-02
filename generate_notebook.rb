require 'uri'
require 'fileutils'
require 'net/http'
require 'colorize'
require 'linguist'
require 'ostruct'


USER = `whoami`.strip.freeze
URI_BASE = "https://raw.githubusercontent.com/moslog/logic-lomba-template-notebook/master/template.ipynb".freeze

class ConfigurationKernel
  attr_reader :kernel_name

  def initialize(lang)
    @kernel_name = lang[:lang]
  end

  def _kernel
    raise "Cannot found kernel file" if get_kernel.nil?
    JSON.parse(File.read(get_kernel), object_class: OpenStruct)
  end

  private 

  def get_kernel
    WorkingDir.new.found_kernel_file(kernel_name)
  end
end

class WorkingDir
  attr_reader :current_kernel_dir, :data_lang

  DEFAULT_PATH = "/home/#{`whoami`.strip}/.local/share/jupyter/kernels/*/"
  private_constant :DEFAULT_PATH

  def initialize
    @current_kernel_dir ||= find_kernel if find_it?
    @data_lang = hashing_kernel
  end

  def find_kernel
    Dir.glob(DEFAULT_PATH)
  end

  def found_kernel_file(kernel_name)
    looking_for_kernel_dir(kernel_name) { |list_dir| return find_json_file(list_dir) }
  end

  private

  def find_json_file(dir)
    Dir["#{dir}/*"].each { |file| return file if File.extname(file) == ".json" }
  end

  def hashing_kernel
    hashing_data = {php: "", java: "", javascript: ""}
    hashing_data.each do |key, val|
      current_kernel_dir.each { |kernel| hashing_data[key] = kernel if kernel.include? key.to_s }
    end
    return hashing_data
  end

  def looking_for_kernel_dir(kernel_name)
    data_lang.each do |key, value|
      if key.to_s == kernel_name
        block_given? ? yield(value) : value
      end
    end
  end

  def find_it?
    File.directory? DEFAULT_PATH.gsub("*", "")
  end
end

class ConfigureNotebook
  attr_reader :notebook, :note_obj

  def initialize(notebook)
    @notebook = notebook
  end

  def configure
    return if notebook.empty?
    @note_obj ||= read_file_to_obj(notebook) 
    yield
  end
  
  private

  def read_file_to_obj(json_file)
    JSON.parse(File.read(json_file), object_class: OpenStruct)
  end
end


def get_request_from_git(raw)
  begin
    uri = URI.parse(raw)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    http.start do |h|
      response = h.request(Net::HTTP::Get.new(uri.request_uri))
      File.open("Untitled.json", 'a') { |f| f.puts response.body } 
    end
  rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
    Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e 
    puts "Error #{e}"
  end
end

spinner = Enumerator.new do |y|
  loop do
    y.yield "|".colorize(:red)
    y.yield "/".colorize(:orange)
    y.yield "-".colorize(:blue)
    y.yield "\\".colorize(:green)
  end
end

FileUtils.cd("/home/#{USER}") do
  get_request_from_git(URI_BASE)
end

1.upto(100) do |i|
  progress = "=" * (i/5) unless i < 5
  printf("\rGenerating: [%-20s] %d%% %s", progress, i, spinner.next)
  sleep(0.1)
end

system("clear")
puts "# " * 28
puts "Insert your name and What Programming language you used".colorize(:blue)
puts "# " * 28 + "\n\n"

print "What your name : "
name = gets.chomp.capitalize
print "What programming language do you used?(Java, Python, PHP, or Javascript) : "
prog_lang = gets.chomp.downcase
FileUtils.cd("/home/#{USER}") do
  puts ConfigurationKernel.new(lang: "#{prog_lang}")
  ConfigureNotebook.new("Untitled.json").configure do
    note_obj.nbformat = 2
    puts note_obj
  end
end
