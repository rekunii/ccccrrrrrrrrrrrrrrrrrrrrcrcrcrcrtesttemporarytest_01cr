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
    @flag.bit(3)
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
puts aaa.a
puts aaa.flag_zero