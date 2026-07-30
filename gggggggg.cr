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
  # def flag_zero=(flagval : Bool)
  # end
  def flag_subtract : Bool
    @f.bit(6) == 1
  end

  def flag_half_carry : Bool
    @f.bit(5) == 1
  end
  def flag_half_carry=(flagval : Bool)
    @f &= 0b11010000
    @f |= 1<<5 if flagval
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

# puts Registers.new.bc
# puts Registers.new.Flags.new.z
aaa = Registers.new
aaa.a=300
aaa.f = 0b10100000_u8
# puts aaa.a
# puts "0x%02X" % aaa.f
# puts aaa.flag_zero
# puts aaa.flag_subtract
# puts aaa.flag_half_carry
# puts aaa.flag_carry

# enum Instructions
#   ADD(ArithmeticTarget)
# end
abstract class Instructions
end

class Add < Instructions
  getter target : ArithmeticTarget
  getter value : UInt8
  def initialize(target : ArithmeticTarget, value : UInt8)
    @target = target
    @value = value
  end
end

enum ArithmeticTarget
  A; B; C; D; E; H; L 
end

class Cpu
  getter reg
  @reg = Registers.new
  def execute(instruction : Instructions)
    target = instruction.target
    case instruction
    when Add
      case target
      when ArithmeticTarget::A
        
        printf "(((BEFORE)))\nreg.a=0x%02X\nflags=%04s\n\n", @reg.a, @reg.f.to_s(2)[..-5]
        @reg.flag_half_carry = (@reg.a&0xf) + (instruction.value&0xf) > 0xf
        # puts (@reg.a&0xf) + (instruction.value&0xf) > 0xf
        @reg.a += instruction.value
        printf "(((AFTER)))\nreg.a=0x%02X\nflags=%04s\n\n", @reg.a, @reg.f.to_s(2)[..-5]
      end
    end
  end
end

inst = Add.new(ArithmeticTarget::A, 10_u8)
cpu = Cpu.new
3.times do |count|
  puts "------------#{count+1}回目の実行"
  cpu.execute(inst)
end
