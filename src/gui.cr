require "colorize"

class GUI
  @cpu : CPU
  @io = STDOUT

  def initialize(@cpu)
  end

  def set_cursor(x : Int, y : Int)
    @io.print "\033[#{y};#{x}H"
  end

  def clear
    @io.print "\033[2J"
  end

  def clear_scroll
    @io.print "\033[3J"
  end

  def hide_cursor
    @io.print "\033[?25l"
  end

  def show_cursor
    @io.print "\033[?25h"
  end

  def draw_rect(x : Int, y : Int, w : Int, h : Int, color : Symbol = :dark_gray)
    {y, y + h}.each do |y|
      x.upto(x + w) { |x| disp x, y, '—'.colorize(color) }
    end

    {x, x + w}.each do |x|
      y.upto(y + h) { |y| disp x, y, '⎪'.colorize(color) }
    end

    { {x, y}, {x + w, y}, {x, y + h}, {x + w, y + h} }.each do |x, y|
      disp x, y, "◼︎".colorize(color)
    end
  end

  # Move cursor to line, column
  def disp(x : Int, y : Int, string : String | Colorize::Object(String | Char) | Char)
    set_cursor x, y
    @io.print string
  end

  def register(value : Int, length = 8u8, color = :red, symbol = '●')
    ("%0#{length}b" % value)
      .chars.map { |c| c == '0' ? symbol.colorize(:dark_gray).mode(:dim) : symbol.colorize(color) }.join
  end

  def bus_connection(x : Int, y : Int, on : Bool, direction : Bool = true)
    str =
      if on
        if direction
          " ⫦>>>>>>>⫣ ".colorize(:red)
        else
          " ⫦<<<<<<<⫣ ".colorize(:red)
        end
      else
        " ⫦-------⫣ ".colorize(:dark_gray).mode(:dim)
      end

    disp x, y, str
  end

  def show
    l = 2                # left
    rs = 8               # register size
    bc = 11              # bus connection size
    r = l + bc + rs + rs # right

    # draw_rect 0, 0, 30, 20
    disp l, 2, "Memory Address".colorize(:black).back(:dark_gray)
    disp l, 3, register(@cpu.address, 8, :yellow)
    bus_connection(l + rs, 3, @cpu.control.mi?, !@cpu.control.mi?)
    disp l, 4, ("$%02x" % @cpu.address)

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp l, 5, "Memory Contents".colorize(:black).back(:dark_gray)
    disp l, 6, register(@cpu.ram[@cpu.address % @cpu.ram.size])
    bus_connection(l + rs, 6, @cpu.control.ro? || @cpu.control.ri?, @cpu.control.ro?)
    disp l, 7, ("$%02x" % @cpu.ram[@cpu.address % @cpu.ram.size])

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp l, 8, "Instruction".colorize(:black).back(:dark_gray)
    disp l, 9, register((@cpu.reg_i >> 4) & 0xF, 4, :cyan)
    disp l + 4, 9, register(@cpu.reg_i & 0xF, 4, :yellow)
    bus_connection(l + 8, 9, @cpu.control.io? || @cpu.control.ii?, @cpu.control.io?)
    disp l, 10, CPU.dasm(@cpu.reg_i) + "   "

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp l, 11, "Flags".colorize(:black).back(:dark_gray)
    disp l, 12, register(@cpu.reg_f.value, 2, :green)
    disp l, 13, "ZC".colorize(:dark_gray).mode(:dim)

    disp l + 7, 11, "MC Step".colorize(:black).back(:dark_gray)
    disp l + 7, 12, register(@cpu.mc_step, 3, :green)

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp l + 19, 1, "Bus".colorize(:black).back(:dark_gray)
    disp l + 19, 2, register(@cpu.bus)
    3.upto(15) do |y|
      disp l + 19, y, register(@cpu.bus, 8, :red, '⎪')
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp r + bc, 2, "Prog Counter".colorize(:black).back(:dark_gray)
    disp r + bc, 3, register(@cpu.program_counter)
    bus_connection(r, 3, @cpu.control.co?, !@cpu.control.co?)
    disp r + bc, 4, "$%02x" % @cpu.program_counter

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp r + bc, 5, "A Register".colorize(:black).back(:dark_gray)
    disp r + bc, 6, register(@cpu.reg_a)
    bus_connection(r, 6, @cpu.control.ao? || @cpu.control.ai?, @cpu.control.ai?)
    disp r + bc, 7, "%03i" % @cpu.reg_a

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp r + bc, 8, "Sum Register".colorize(:black).back(:dark_gray)
    disp r + bc, 9, register(@cpu.reg_e)
    bus_connection(r, 9, @cpu.control.eo?, !@cpu.control.eo?)
    disp r + bc, 10, "%03i" % @cpu.reg_e

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp r + bc, 11, "B Register".colorize(:black).back(:dark_gray)
    disp r + bc, 12, register(@cpu.reg_b)
    bus_connection(r, 12, @cpu.control.bi?, true)
    disp r + bc, 13, "%03i" % @cpu.reg_b

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp r + bc, 14, "Output".colorize(:black).back(:dark_gray)
    disp r + bc, 15, register(@cpu.reg_o)
    bus_connection(r, 15, @cpu.control.oi?, true)
    disp r + bc, 16, "%03i" % @cpu.reg_o

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp l, 14, "Control Word".colorize(:black).back(:dark_gray)
    disp l, 15, register(@cpu.control.value, 18, :cyan)

    CPU::MC.names.each_with_index do |name, index|
      x = l + 17 - index
      name.chars.each_with_index do |c, y|
        disp x, 16 + y, c.colorize(:dark_gray).mode(:dim)
      end
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    disp r + 28, 2, "RAM".colorize(:black).back(:dark_gray)
    @cpu.ram.each_with_index do |byte, index|
      str = "   %02x: %08b  %s        " % [index, byte, CPU.dasm(byte)]

      str = str.colorize(:dark_gray).mode(:dim) unless @cpu.address == index

      disp r + 25, 3 + index, str

      if @cpu.program_counter == index
        disp r + 24, 3 + index, "㍶ ▶︎".colorize(:dark_gray).mode(:dim)
      end

      if @cpu.address == index
        if @cpu.control.ri?
          disp r + 25, 3 + index, " =>".colorize(:red)
        elsif @cpu.control.ro?
          disp r + 25, 3 + index, "<= ".colorize(:yellow)
        end
      end
    end
  end
end
