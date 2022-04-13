require "./spec_helper"

describe CPU do
  it "multiplies" do
    prog = File.read("./examples/multiply.asm")
    cpu = CPU.new(prog)
    cpu.run
    cpu.reg_o.should eq(12u8)
  end

  it "Adds immediate" do
    n1 = rand(0..0xF)
    n2 = rand(0..0xF)

    prog = <<-ASM
      ldi #{n1.to_s(16)}
      adi #{n2.to_s(16)}
      out
      hlt
    ASM

    cpu = CPU.new(prog)
    cpu.run
    cpu.reg_o.should eq(n1 + n2)
  end
end
