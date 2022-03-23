require "option_parser"
require "./cpu"
require "./gui"

NAME = "bemu"

enum Command : UInt8
  None
  Build
  Run
  Disassemble
end

options = {
  "verbose" => false,
} of String => String | Bool

command = Command::None
delay_time = 0.0

OptionParser.parse do |parser|
  parser.banner = "Usage: #{NAME} [arguments]"
  parser.on("-v", "--verbose", "Run verbosely") { options["verbose"] = true }

  parser.on("build", "assemble a file") do
    parser.banner = "Usage: #{NAME} build [arguments]"

    command = Command::Build

    parser.on("-o NAME", "Output file name") do |name|
      options["output"] = name
    end
  end

  parser.on("dasm", "dis-assemble a binary") do
    parser.banner = "Usage: #{NAME} dasm [arguments]"
    command = Command::Disassemble
  end

  parser.on("run", "run a program") do
    parser.banner = "Usage: #{NAME} run [arguments]"

    command = Command::Run

    parser.on("-a", "--asm", "Assemble before running") do
      options["asm"] = true
    end

    parser.on("-g", "--gui", "Run with a gui") do
      options["gui"] = true
    end

    parser.on("-d DELAY", "--delay DELAY", "Add a delay to each clock pulse (s)") do |delay|
      delay_time = delay.to_f
    end
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

# ~~~~~~~~~~~~~~~~~~~~~~~

# Read bytes from a file
def read_bytes(path)
  i = 0
  bytes = Bytes.new(File.size(path))
  File.open(path, "rb") do |file|
    while byte = file.read_byte
      bytes[i] = byte
      i += 1
    end
  end
  bytes
end

# Read input path from cli args
def input_path
  unless ARGV[0]?
    STDERR.puts "Did not receive input path"
    exit(1)
  end

  ARGV[0]
end

# =======================
# = Execute the command =
# =======================

case command
when Command::Build
  prog = File.read(input_path)
  assembly = CPU.assemble(prog)

  if out_path = options["output"]?
    File.open(out_path.as(String), "wb") do |f|
      assembly.each do |byte|
        f.write_byte(byte)
      end
    end
  else
    assembly.each_with_index do |val, i|
      puts "%02x: %08b" % [i, val]
    end
  end
when Command::Run
  cpu = if options["asm"]?
          CPU.new(File.read(input_path), options["verbose"].as(Bool))
        else
          bytes = read_bytes(input_path)
          CPU.new(bytes, options["verbose"].as(Bool))
        end

  if options["gui"]?
    gui = GUI.new(cpu)
    gui.clear
    gui.clear_scroll
    cpu.run do
      gui.show
      gui.set_cursor(0, 0)
      sleep delay_time
    end
    gui.set_cursor(0, 20)
  else
    cpu.run { sleep delay_time }
    puts cpu.reg_o
  end
when Command::Disassemble
  bytes = read_bytes(input_path)
  bytes.each_with_index do |byte, i|
    puts "%02x: %08b %s" % [i, byte, CPU.dasm(byte)]
  end
else
  STDERR.puts "No options received, run with -h for help"
  exit(1)
end
