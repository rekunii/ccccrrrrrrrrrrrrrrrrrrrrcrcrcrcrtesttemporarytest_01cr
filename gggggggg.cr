# ## Credits
# [How to Emulate a Game Boy - rylev](https://rylev.github.io/DMG-01/public/book/introduction.html)

# require "bit_array"

struct Bool
 def asNum : UInt8
  self.to_unsafe.to_u8
 end
end

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

def from_byte(byte : UInt8, prefixed : Bool) : Instructions | Nil
  if prefixed
    from_byte_prefixed(byte)
  else
    from_byte_not_prefixed(byte)
  end
end

def from_byte_prefixed(byte : UInt8)
  nil
end

def from_byte_not_prefixed(byte : UInt8)
    case byte
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

class LD < Instructions
  getter load_type : LoadType
  def initialize(load_type : LoadType)
    @load_type = load_type
  end
end

class JP < Instructions
  getter test : JumpTest
  def initialize(test : JumpTest)
    @test = test
  end
end

enum ArithmeticTarget
  A; B; C; D; E; H; L 
end

enum LoadByteTarget
  A; B; C; D; E; H; L; HLI
end

enum LoadByteSource
  A; B; C; D; E; H; L; D8; HLI
end

struct LoadType
  getter target : LoadByteTarget
  getter source : LoadByteSource
  def initialize(target : LoadByteTarget, source : LoadByteSource)
    @target = target
    @source = source
  end
end

struct MemoryBus
  @memory = Bytes.new(0xFFFF, 0_u8)
  def memory
    @memory
  end
end

enum JumpTest
  NotZero; Zero; NotCarry; Carry; Always
end

class Cpu
  getter reg
  @reg = Registers.new
  getter bus
  @bus = MemoryBus.new

  def step
    # puts "pc: #{@reg.pc}"
    instruction_byte = bus.memory.fetch(@reg.pc) {raise "えらー"}
    prefixed = instruction_byte == 0xCB
    if prefixed
      @reg.pc += prefixed.asNum
      instruction_byte = bus.memory.fetch(@reg.pc) {raise "えらー"}
    end

    next_pc = if inst = from_byte(instruction_byte, prefixed)
      execute(inst)
    else
      printf "\nunknown opcodes detected.\npc: 0x%04X\nopcode: 0x%02X\n", @reg.pc, instruction_byte
      exit 1
    end
    @reg.pc = next_pc
    # puts "next_pc: #{next_pc}"
  end
  
  def execute(instruction : Instructions)
    case instruction
    when Add
      case instruction.target
      when ArithmeticTarget::A
        @reg.a = add(@reg.a)
        return @reg.pc &+ 1
      when ArithmeticTarget::C
        @reg.a = add(@reg.c)
        return @reg.pc &+ 1
      end
    when LD
      source = 
      case instruction.load_type.source
      when LoadByteSource::A
        @reg.a
      when LoadByteSource::B
        @reg.b
      end
    when JP
      test = instruction.test
      jump_condition = 
      case test
      when JumpTest::NotZero
        !@reg.flag_zero
      when NotCarry
        !@reg.flag_carry
      when JumpTest::Zero
        @reg.flag_zero
      when JumpTest::Carry
        @reg.flag_carry
      when JumpTest::Always
        true
      end
      jump(jump_condition)
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

  def jump
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
