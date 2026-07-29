# require "bit_array"
struct Registers
  def initialize
    @a = 0_u8
    @b = 0_u8
    @c = 0_u8
    @d = 0_u8
    @e = 0_u8
    @h = 0_u8
    @l = 0_u8
    @f = 0_u8
    @pc = 0_u16
    @sp = 0_u16
  end

  {% for name in %w(a b c d e h l f) %}
  def {{name.id}}; @{{name.id}}; end
  def {{name.id}}=(val)
    @{{name.id}}=(val&0xff).to_u8
  end
  {% end %}
  def pc; @pc; end
  def sp; @sp; end
  def flag_zero : Bool
    @f.bit(7) == 1
  end
  def flag_subtract : Bool
    @f.bit(6) == 1
  end
  def flag_half_carry : Bool
    @f.bit(5) == 1
  end
  def flag_carry : Bool
    @f.bit(4) == 1
  end

  # def a; @a; end
  # def a=(val); @a=val;end

  def bc : UInt16
    (@b.to_u16 << 8) | @c.to_u16
  end
end

puts Registers.new.bc
# puts Registers.new.Flags.new.z
aaa = Registers.new
aaa.a=300
aaa.f = 0b10100000_u8
puts aaa.a
puts "0x%02X" % aaa.f
puts aaa.flag_zero
puts aaa.flag_subtract
puts aaa.flag_half_carry
puts aaa.flag_carry

# enum Instructions
#   ADD(ArithmeticTarget)
# end
abstract class Instructions
end

class Add < Instructions
  getter target : ArithmeticTarget
  def initialize(target : ArithmeticTarget)
    @target = target
  end
end

enum ArithmeticTarget
  A; B; C; D; E; H; L 
end

class Cpu
  def execute(instructions : Instructions)
    puts "ok"
  end
end

inst = Add.new(ArithmeticTarget::A)
Cpu.new.execute(inst)
