puts "hello"

require "bit_array"

struct Bool
  def asNum : UInt8
    self.to_unsafe.to_u8
  end
end

def bool2num_(b : Bool) : UInt8
  b.to_unsafe.to_u8
end

struct Main
  def initialize(num_panel_h : UInt8, num_panel_w : UInt8)
    @num_panel_h = num_panel_h
    @num_panel_w = num_panel_w
  end

  @panel_board = BitArray.new(64)

  @separaters = " \n"

  @tate = 0_i8
  @yoko = 0_i8

  @io = IO::Memory.new

  def do_flip : Nil
    # return if tate < 0 || yoko < 0 || tate > num_panel_h || yoko num_panel_w
    shot_index = @tate*@num_panel_w + @yoko

    line = @tate - 1
    idx = shot_index - @num_panel_w - 1
    3.times do # たて
      3.times do # よこ
        if idx - (line*@num_panel_w) < 0
          puts "idxがマイナス"
          idx += 1
          next
        elsif idx - (line*@num_panel_w) > @num_panel_w-1
          puts "idxがオーバー"
          idx += 1
          next
        end
        @panel_board[idx] ^= true
        idx += 1
      end
      idx += @num_panel_w-3
      line += 1
    end
    puts "OK"
  end

  def run
    while true
      puts "入力待ち"
      in_str = gets.not_nil!
      if in_str == ""
        break
      elsif in_str == "p"
        @num_panel_h.times do |i|
          @io.clear
          @num_panel_w.times do |w|
            @io << @panel_board[i*@num_panel_w + w].asNum
            @io << @separaters[bool2num_(w == @num_panel_w - 1)]
          end
          print @io
        end
        next
      elsif /^[0-#{tate-1}][0-#{yoko-1}]$/.match(in_str)
        begin
          @tate = in_str[0].to_i8
          @yoko = in_str[1].to_i8
        rescue exception
          puts "よくないA"
          next
        end
        res = @tate*@num_panel_w + @yoko
        if res >= (@num_panel_h * @num_panel_w)
          puts "よくないB"
          puts res
          next
        end
        do_flip
      else
        puts "よくないC"
        next
      end
    end
  end
end

m = Main.new 4, 6

m.run
