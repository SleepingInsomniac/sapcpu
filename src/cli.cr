require "option_parser"
require "./cpu"
require "./gui"

NAME = "sapcpu"

enum Command : UInt8
  None
  Build
  Run
  Disassemble
end

cpu_options : CPU::Options = CPU::Options::Output
options = {} of String => String | Bool
command = Command::None
delay_time = 0.0

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: #{NAME} [arguments]"
  parser.on("-v", "--verbose", "Run verbosely") { cpu_options |= CPU::Options::Verbose }

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
      cpu_options &= ~CPU::Options::Verbose # Disable verbose output
      cpu_options &= ~CPU::Options::Output  # Disable output to stdout
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
          CPU.new(File.read(input_path), cpu_options)
        else
          bytes = read_bytes(input_path)
          CPU.new(bytes, cpu_options)
        end

  if options["gui"]?
    gui = GUI.new(cpu)

    Signal::INT.trap do
      gui.show_cursor
      exit
    end

    gui.clear
    gui.clear_scroll
    gui.hide_cursor
    cpu.run do
      gui.show
      gui.set_cursor(0, 0)
      sleep delay_time
    end
    gui.set_cursor(0, 20)
    gui.show_cursor
  else
    cpu.run { sleep delay_time }
  end
when Command::Disassemble
  bytes = read_bytes(input_path)
  bytes.each_with_index do |byte, i|
    puts "%02x: %08b %s" % [i, byte, CPU.dasm(byte)]
  end
else
  # STDERR.puts "No options received\n"
  STDERR.puts parser
  exit(1)
end
