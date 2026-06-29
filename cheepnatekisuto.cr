# ターミナルに出力する！
# 入力待ちをする！
# sleepする！

CLS = "\e[2J\e[H"

TEXT_PRINT_ANIMATION_STEP_SPAN_GLOBAL_TIMESPAN = {
  10.milliseconds,
  20.milliseconds,
}

def type_text(time_milli_sleep : UInt8, text : String)
  # mi = {10.milliseconds,20.milliseconds}
  text.each_char do |char|
    print "#{char}"
    if time_milli_sleep > 0
      sleep (time_milli_sleep*10).milliseconds
      # sleep TEXT_PRINT_ANIMATION_STEP_SPAN_GLOBAL_TIMESPAN[time_milli_sleep]
    end
  end
  puts
end


def make_game_opening_screen
  frame_part_A = "─"
  frame_part_B = "│"
  puts "\e[15;5H#{frame_part_A*100}"
  10.times do |num|
    puts "\e[#{16+num};5H#{frame_part_B}"
  end
  puts "\e[15;5H#{frame_part_A*10}"
end

def make_game_play_dialog_animate
  frame_part_A = "─"
  frame_part_B = "│"
  # puts "\e[40;5H#{frame_part_A*100}"
  # puts "\e[40;5H#{frame_part_A*100}"
  30.times do |num|
    puts "\e[15;H#{("*"+frame_part_A*(num*2)+"*").center(100, '.')}"
    puts "\e[16;H#{(frame_part_B+"."*(num*2)+frame_part_B).center(100, '.')}"
    puts "\e[17;H#{("*"+frame_part_A*(num*2)+"*").center(100, '.')}"
    # puts "\e[16;H#{(frame_part_B).ljust(num, '.')}"
    sleep 6.milliseconds
  end
end

# type_text 1, "こんにちは！\nコンソールをフォーカスしてえんたーをおしてね▼"
# gets

# type_text 1, "すばらしい！"
# sleep 1.second
# type_text 1, "あなたの好きな食べ物は何かな？▼"
# input = gets

# type_text 1, "なるほど、あなたは..."
# sleep 1.second
# type_text 1, "#{input} が好きなんだね！"
# sleep 100.milliseconds
# type_text 0, "さいなら！"
# make_game_opening_screen
make_game_play_dialog_animate
sleep 1.seconds