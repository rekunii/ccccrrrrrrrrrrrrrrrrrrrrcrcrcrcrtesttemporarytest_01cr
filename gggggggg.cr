# ## Credits
# [How to Emulate a Game Boy - rylev](https://rylev.github.io/DMG-01/public/book/introduction.html)
# https://gbdev.io/gb-opcodes/optables/

# require "bit_array"
VRAM_BEGIN = 0x8000_u16
VRAM_END = 0x97FF_u16
VRAM_SIZE = 0x1800_u16

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
  def bc : UInt16
    @b.to_u16 << 8 | @c
  end
  def bc=(value : UInt16)
    @b = (value >> 8).to_u8
    @c = (value & 0xff).to_u8
  end
  def hl : UInt16
    @h.to_u16 << 8 | @l
  end
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

class PUSH < Instructions
  getter target
  def initialize(target : StackTarget)
    @target = target
  end
end

class POP < Instructions
  getter target
  def initialize(target : StackTarget)
    @target = target
  end
end

class CALL < Instructions
end

class RET < Instructions
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

enum TilePixelValue
  Zero; One; Two; Three
end

struct LoadType
  getter target : LoadByteTarget
  getter source : LoadByteSource
  def initialize(target : LoadByteTarget, source : LoadByteSource)
    @target = target
    @source = source
  end
end

alias Tile = Array(Array(TilePixelValue))

def empty_tile : Tile
  Array.new(8, Array.new(8, TilePixelValue::Zero))
end

struct GPU
  @vram = Array(UInt8).new(VRAM_SIZE)
  @tile_set = Array(Tile).new(384)
  def read_vram(addr : UInt16) : UInt8
    @vram[addr]
  end
  def write_vram(index : UInt8, vallue : UInt8)
    normalized_index = index & 0xFFFE
    byte1 = @vram[normalized_index];
    byte2 = @vram[normalized_index+1];
    
  end
end

struct MemoryBus
  @memory = Bytes.new(0x10000, 0_u8)
  def memory
    @memory
  end
  def fetch(addr : UInt16) : UInt8
    @memory.fetch(addr) {raise "範囲外のbusアクセスが発生"}
  end
  
  def read_byte(addr : UInt16) : UInt8
    case addr
    when VRAM_BEGIN..VRAM_END
      @gpu.read_vram(addr - VRAM_BEGIN)
    else
      raise "TODO: Support other areas of memory"
    end
  end

  def write_byte(addr : UInt16) : UInt8
    case addr
    when VRAM_BEGIN..VRAM_END
      raise "TODO: Support other areas of memory"
    end
  end
end

enum JumpTest
  NotZero; Zero; NotCarry; Carry; Always
end

enum StackTarget
  BC
end

class Cpu
  getter reg
  @reg = Registers.new
  getter bus
  @bus = MemoryBus.new

  @pc = 0_u16
  @sp = 0_u16

  def step
    # puts "pc: #{@reg.pc}"
    instruction_byte = bus.fetch(@reg.pc)
    prefixed = instruction_byte == 0xCB
    @reg.pc += prefixed.asNum
    instruction_byte = bus.fetch(@reg.pc) 

    next_pc : UInt16 = if inst = from_byte(instruction_byte, prefixed)
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
      source_value : UInt8 = 
      case instruction.load_type.source
      when LoadByteSource::A
        @reg.a
      when LoadByteSource::B
        @reg.b
      when LoadByteSource::D8
        0_u8 # read_next_byte
      when LoadByteSource::HLI
        @bus.fetch(@reg.hl)
      else
        0_u8
      end
      case instruction.load_type.target
      when LoadByteTarget::A
        @reg.a = source_value
      when LoadByteTarget::HLI
        @bus.memory[@reg.hl] = source_value
      end
      return 1+(instruction.load_type.source === LoadByteSource::D8).asNum

    when JP
      test = instruction.test
      jump_condition = 
      case test
      when JumpTest::NotZero
        !@reg.flag_zero
      when JumpTest::NotCarry
        !@reg.flag_carry
      when JumpTest::Zero
        @reg.flag_zero
      when JumpTest::Carry
        @reg.flag_carry
      when JumpTest::Always
        true
      else 
        false
      end
      @reg.pc = jump(jump_condition)
    # end

    when PUSH
      value : UInt16 =  
      case instruction.target
      when StackTarget::BC
        @reg.bc
      else
        0_u16
      end
      push(value)
      return @reg.pc &+ 1
    # end

    when POP
      result : UInt16 = pop
      case instruction.target
      when StackTarget::BC
        @reg.bc = result
      end
      return @reg.pc &+ 1
    when CALL
      jump_condition = true
      # case instruction.test
      # when JumpTest::NotZero
      call(jump_condition)
    when RET
      jump_condition = true
      return_(jump_condition)
    end
    # next_pcの値がreturnされない場合には0_u16を返す
    0_u16
  end

  def add(value : UInt8) : UInt8
    @reg.flag_zero = @reg.a &+ value == 0
    @reg.flag_subtract = false
    @reg.flag_half_carry = (@reg.a&0xf) + (value&0xf) > 0xf
    @reg.flag_carry = value > UInt8::MAX-@reg.a
    @reg.a &+ value
  end

  def jump(should_jump : Bool) : UInt16
    puts should_jump
    if should_jump
      # 下位ビット
      least_significant_byte = @bus.fetch(@reg.pc+1)
      # 上位ビット
      most_significant_byte = @bus.fetch(@reg.pc+2).to_u16
      
      return (most_significant_byte << 8) | least_significant_byte
    else
      @reg.pc &+ 3
    end
  end

  def push(value : UInt16)
    @sp &-= 1
    @bus.memory[@sp] = ((value & 0xFF00) >> 8).to_u8

    @sp &-= 1
    @bus.memory[@sp] = (value & 0xFF).to_u8
  end

  def pop : UInt16
    lsb = @bus.memory[@sp]
    @sp &+= 1
    msb = @bus.memory[@sp].to_u16
    @sp &+= 1
    (msb << 8) | lsb
  end

  def call(should_jump : Bool) : UInt16
    next_pc : UInt16 = @reg.pc &+ 3
    if should_jump
      push next_pc
      jump true
    else
      next_pc
    end
  end

  def return_(should_jump : Bool) : UInt16
    should_jump ? pop : @reg.pc&+1
  end

end



# inst = Add.new(ArithmeticTarget::A, 10_u8)
cpu = Cpu.new
cpu.reg.c = 0x10
opcodes = [0x81, 0x87, 0x81]
opcodes.size.times do |count|
  cpu.bus.memory[count] = opcodes[count].to_u8
  puts "------------#{count+1}回目の実行"
  cpu.step
  printf("register a = 0x%02X\nregister c = 0x%02X\nregister f = %04s\npc = 0x%04X\n",
  cpu.reg.a,
  cpu.reg.c,
  cpu.reg.f.to_s(2, precision: 8)[..-5],
  cpu.reg.pc)
end

puts "------------"
cpu.bus.memory[4] = 0xff_u8
cpu.bus.memory[5] = 0x12_u8
jump = JP.new(JumpTest::Always) # たぶん0xC3
cpu.execute(jump)
printf("0x%04X\n", cpu.reg.pc)
