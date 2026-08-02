# ## Credits
# [How to Emulate a Game Boy - rylev](https://rylev.github.io/DMG-01/public/book/introduction.html)

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
  def pc=(val : UInt16) : Nil
    @pc = val
  end
  def sp; @sp; end

  # TODO
  # 効率化と可読性の向上を検討に検討を重ね検討することを検討する
  def flag_zero : Bool
    @f.bit(7) == 1
  end
  def flag_zero=(flagval : Bool) : Nil
    @f &= 0b01110000
    @f |= 1<<7 if flagval
  end

  def flag_subtract : Bool
    @f.bit(6) == 1
  end

  def flag_subtract=(flagval) : Nil
    @f &= 0b10110000
    @f |= 1<<6 if flagval
  end

  def flag_half_carry : Bool
    @f.bit(5) == 1
  end

  def flag_half_carry=(flagval : Bool) : Nil
    @f &= 0b11010000
    @f |= 1<<5 if flagval
  end

  def flag_carry : Bool
    @f.bit(4) == 1
  end
  def flag_carry=(flagval : Bool) : Nil
    @f &= 0b11100000
    @f |= 1<<4 if flagval
  end

  def bc : UInt16
    (@b.to_u16 << 8) | @c.to_u16
  end
end

def from_byte(val : UInt8) : Instructions | Nil
  case val
  when 0x81
    puts "ADD C"
    Add.new(ArithmeticTarget::C)
  when 0x87
    puts "ADD A"
    Add.new(ArithmeticTarget::A)
  else
    nil
  end
end

abstract class Instructions
end

class Add < Instructions
  getter target : ArithmeticTarget
  getter value : UInt8
  def initialize(target : ArithmeticTarget, value : UInt8 = 0)
    @target = target
    @value = value
  end
end

enum ArithmeticTarget
  A; B; C; D; E; H; L 
end

struct MemoryBus
  @memory = Bytes.new(0xFFFF, 0_u8)
  def memory
    @memory
  end
end

class Cpu
  getter reg
  @reg = Registers.new
  getter bus
  @bus = MemoryBus.new

  def step
    # puts "pc: #{@reg.pc}"
    instruction_byte = bus.memory.fetch(@reg.pc) {raise "えらー"}

    next_pc = if inst = from_byte(instruction_byte)
      execute(inst)
    else
      printf "\nunknown opcodes detected.\npc: 0x%04X\nopcode: 0x%02X\n", @reg.pc, instruction_byte
      exit 1
    end
    @reg.pc = next_pc
    # puts "next_pc: #{next_pc}"
  end
  
  def execute(instruction : Instructions)
    target = instruction.target
    case instruction
    when Add
      case target
      when ArithmeticTarget::A
        @reg.a = add(@reg.a)
        return @reg.pc &+ 1
      when ArithmeticTarget::C
        @reg.a = add(@reg.c)
        return @reg.pc &+ 1
      end
    end
    0_u16
  end

  def add(value : UInt8) : UInt8
    @reg.flag_zero = @reg.a &+ value == 0
    @reg.flag_subtract = false
    @reg.flag_half_carry = (@reg.a&0xf) + (value&0xf) > 0xf
    @reg.flag_carry = value > UInt8::MAX-@reg.a
    @reg.a &+ value
  end
end

# inst = Add.new(ArithmeticTarget::A, 10_u8)
cpu = Cpu.new
cpu.reg.c = 0x10
opcodes = [0x81, 0x87, 0x81, 0x3C]
4.times do |count|
  cpu.bus.memory[count] = opcodes[count].to_u8
  puts "------------#{count+1}回目の実行"
  cpu.step
  printf("register a = 0x%02X\nregister c = 0x%02X\nregister f = %04s\npc = 0x%04X\n",
  cpu.reg.a,
  cpu.reg.c,
  cpu.reg.f.to_s(2, precision: 8)[..-5],
  cpu.reg.pc)
end
