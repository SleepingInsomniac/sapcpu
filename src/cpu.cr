class CPU
  # Flags register values
  @[Flags]
  enum Flags : UInt8
    Carry
    Zero
  end

  # Micro-code values
  @[Flags]
  enum MC : UInt32
    HLT # Halt
    MI  # Memory Address Register In
    RI  # Ram In
    RO  # Ram Out
    IO  # instruction out (last 4 bits)
    II  # instruction in
    AI  # A In
    AO  # A Out
    EO  # Sum Out
    SU  # Subtract
    BI  # B Register In
    OI  # Output Register In
    CE  # Memory Address Counter Enable (increment)
    CO  # Memory Address Counter Out
    J   # Jump
    FI  # Flags IN
    JC  # Jump Carry
    JZ  # Jump Zero
  end

  # Fetch instruction microcode
  F1 = MC::CO | MC::MI
  F2 = MC::RO | MC::II | MC::CE

  # Opcodes
  NOP = StaticArray[F1, F2, MC::None, MC::None, MC::None]                                        # No-op
  LDA = StaticArray[F1, F2, MC::IO | MC::MI, MC::RO | MC::AI, MC::None]                          # Load A
  ADD = StaticArray[F1, F2, MC::IO | MC::MI, MC::RO | MC::BI, MC::EO | MC::AI | MC::FI]          # Add A with memory
  SUB = StaticArray[F1, F2, MC::IO | MC::MI, MC::RO | MC::BI, MC::EO | MC::AI | MC::SU | MC::FI] # Subtract A with memory
  STA = StaticArray[F1, F2, MC::IO | MC::MI, MC::AO | MC::RI, MC::None]                          # Store A to memory
  LDI = StaticArray[F1, F2, MC::IO | MC::AI, MC::None, MC::None]                                 # Load Immediate to A
  JMP = StaticArray[F1, F2, MC::IO | MC::J, MC::None, MC::None]                                  # Jump to Immediate
  JC  = StaticArray[F1, F2, MC::IO | MC::JC, MC::None, MC::None]                                 # Jump on Carry
  JZ  = StaticArray[F1, F2, MC::IO | MC::JZ, MC::None, MC::None]                                 # Jump on Zero
  OUT = StaticArray[F1, F2, MC::AO | MC::OI, MC::None, MC::None]                                 # Output
  HLT = StaticArray[F1, F2, MC::HLT, MC::None, MC::None]                                         # Halt execution

  # Set opcodes in micro-code ROM
  ROM = Slice[
    NOP, # 0000
    LDA, # 0001
    ADD, # 0010
    SUB, # 0011
    STA, # 0100
    LDI, # 0101
    JMP, # 0110
    JC,  # 0111
    JZ,  # 1000
    NOP, # 1001
    NOP, # 1010
    NOP, # 1011
    NOP, # 1100
    NOP, # 1101
    OUT, # 1110
    HLT, # 1111
  ]

  # Disassemble instruction
  def self.dasm(instr : UInt8)
    case ROM[instr >> 4]
    when LDA then "LDA %0x" % (instr & 0xFu8)
    when ADD then "ADD %0x" % (instr & 0xFu8)
    when SUB then "SUB %0x" % (instr & 0xFu8)
    when STA then "STA %0x" % (instr & 0xFu8)
    when LDI then "LDI %0x" % (instr & 0xFu8)
    when JMP then "JMP %0x" % (instr & 0xFu8)
    when JC  then "JC %0x" % (instr & 0xFu8)
    when JZ  then "JZ %0x" % (instr & 0xFu8)
    when OUT then "OUT"
    when HLT then "HLT"
    else
      "NOP"
    end
  end

  LABEL_REGEX = /^(?<label>[a-z]+)\:/i
  SYM_REGEX   = /\:(?<label>[a-z]+)/i

  # Assemble a program
  def self.assemble(prog : String)
    labels = {} of String => Int32
    # Get rid of whitespace and comments
    lines = prog.lines.map(&.gsub(/\;.+/, "")).map(&.strip).reject(&.blank?)

    # Parse for labels
    lines = lines.map_with_index do |line, index|
      if parsed = line.match(LABEL_REGEX)
        labels[parsed["label"]] = index
      end
      line.gsub(LABEL_REGEX, "")
    end

    # Relpace labels with line numbers
    lines = lines.map do |line|
      if parsed = line.match(SYM_REGEX)
        index = labels[parsed["label"]]
        line.gsub(SYM_REGEX, index.to_s(16))
      else
        line
      end
    end

    ram = Slice(UInt8).new(lines.size)
    lines.each_with_index do |instr, line|
      machine_code = CPU.asm(instr)
      ram[line] = machine_code
    end
    ram
  end

  # Assemble instruction
  def self.asm(line : String)
    op = line.strip.split(' ')
    mnuemonic = op[0]

    oprand = if val = op[1]?
               val.to_u8(16)
             else
               0u8
             end

    opcode = case mnuemonic.upcase
             when "NOP" then NOP
             when "LDA" then LDA
             when "ADD" then ADD
             when "SUB" then SUB
             when "STA" then STA
             when "LDI" then LDI
             when "JMP" then JMP
             when "JC"  then JC
             when "JZ"  then JZ
             when "OUT" then OUT
             when "HLT" then HLT
             end

    if op_idx = ROM.index { |i| i == opcode }
      (((op_idx << 4) & 0b1111_0000_u8) | (oprand & 0b0000_1111_u8)).to_u8!
    else
      mnuemonic.to_u8(16)
    end
  end

  getter bus : UInt8 = 0u8
  getter program_counter : UInt8 = 0u8

  getter reg_a : UInt8 = 0u8         # A Register
  getter reg_b : UInt8 = 0u8         # B Register
  getter reg_o : UInt8 = 0u8         # Output Register
  getter reg_i : UInt8 = 0u8         # Instruction Register
  getter reg_f : Flags = Flags::None # Flags Register

  @control : MC = MC::None

  property address : UInt8 = 0u8 # Memory Address Register
  property ram : Slice(UInt8)

  property verbose : Bool = false

  # Initialize from un-assembled program
  def initialize(prog : String, verbose = false)
    initialize(CPU.assemble(prog), verbose)
  end

  # Initialize from assembled program
  def initialize(@ram, @verbose = false)
    if @verbose
      @ram.each_with_index do |instr, line|
        puts "%02x: %08b %s" % [line, instr, CPU.dasm(instr)]
      end
      puts
    end
  end

  # Get the current state of the flags
  # Note: this is latched to `@reg_f` on `MC::FI`
  def flags
    flags = Flags::None

    # Set zero flag if sum register is zero
    flags |= Flags::Zero if reg_e == 0u8

    # Check if the sum register has overflowed or underflowed
    if @control.su?
      flags |= Flags::Carry if @reg_a.to_i16 - @reg_b < 0
    else
      flags |= Flags::Carry if @reg_a.to_u16 + @reg_b > UInt8::MAX
    end

    flags
  end

  # Sum register
  def reg_e
    if @control.su?
      @reg_a &- @reg_b
    else
      @reg_a &+ @reg_b
    end
  end

  # The main loop
  def run
    until @control.hlt?
      5.times do |mc_step|
        # Set the control word from the micro-code step
        instruction = ROM[@reg_i >> 4] # Fetch instruction from rom
        @control = instruction[mc_step]

        @bus = @program_counter if @control.co?    # program counter on the bus
        @bus = @ram[@address] if @control.ro?      # Memory on the bus
        @bus = @reg_a if @control.ao?              # A on the bus
        @bus = @reg_i & 0b00001111 if @control.io? # Instruction on the bus (last 4 bits only)
        @bus = self.reg_e if @control.eo?          # Sum on the bus

        # Counter enable increments the program counter on clock tick
        @program_counter &+= 1 if @control.ce?

        @reg_f = self.flags if @control.fi?    # Latch flags
        @program_counter = @bus if @control.j? # Jump
        @program_counter = @bus if @control.jc? && @reg_f.carry?
        @program_counter = @bus if @control.jz? && @reg_f.zero?
        @address = @bus if @control.mi? # Memory address in
        @reg_i = @bus if @control.ii?   # Instruction register in
        @reg_a = @bus if @control.ai?   # Register A in
        @reg_b = @bus if @control.bi?   # Register B in
        @reg_o = @bus if @control.oi?   # Output register in
        puts @reg_o if @control.oi?
        @ram[@address] = @bus if @control.ri? # Ram in

        if @verbose
          print @control.to_s.ljust(20)
          print " > "
          print "pc: %08b " % @program_counter
          print "Bus: %08b " % @bus
          print "Ram: %08b => %08b " % [@address, @ram[@address]]
          print "a: %08b " % @reg_a
          print "b: %08b " % @reg_b
          print "sum: %08b " % self.reg_e
          print "out: %08b " % @reg_o
          print "flags: #{@reg_f}"
          print "\n"

          if mc_step == 1
            puts "#{" ".rjust(20)} > Instr: %04b %04b : %s" % [
              @reg_i >> 4, @reg_i & 0xFu8, CPU.dasm(@reg_i),
            ]
          end
        end

        break if @control.hlt?
      end
    end
  end
end
