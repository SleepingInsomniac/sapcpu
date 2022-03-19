require "./spec_helper"

describe CPU do
  it "multiplies" do
    prog = File.read("./examples/multiply.asm")
    cpu = CPU.new(prog)
    cpu.run
    cpu.reg_o.should eq(12u8)
  end
end
