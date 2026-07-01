# ターミナルに出力する！
# 入力待ちをする！
# sleepする！

CLS = "\e[2J\e[H"

TEXT_PRINT_ANIMATION_STEP_SPAN_GLOBAL_TIMESPAN = {
  10.milliseconds,
  20.milliseconds,
}

SCENE_SIZE_W = 100
SCENE_SIZE_H = 26

DIALOG_SIZE_W = 60
DIALOG_SIZE_H = 5
DIALOG_POS_H = SCENE_SIZE_H-DIALOG_SIZE_H+1

FRAME_PART_A = "─"
FRAME_PART_B = "│"
FRAME_PART_C = "*"

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
  puts "\e[15;5H#{FRAME_PART_A*100}"
  10.times do |num|
    puts "\e[#{16+num};5H#{FRAME_PART_B}"
  end
  puts "\e[15;5H#{FRAME_PART_A*10}"
end

def make_game_play_dialog_animate
  print "\e[#{DIALOG_POS_H};H#{"A..."*25}" # 確認用(is dialog written on center)
  (DIALOG_SIZE_W//2).times do |num|
    print "\e[#{DIALOG_POS_H};#{100//2-num}H#{FRAME_PART_C+FRAME_PART_A*num*2+FRAME_PART_C}"
    1.upto(DIALOG_SIZE_H-1) do |n|
      print "\e[#{DIALOG_POS_H+n};#{100//2-num}H\e[K#{FRAME_PART_B}\e[#{num*2}C#{FRAME_PART_B}"
    end
    print "\e[#{SCENE_SIZE_H};#{100//2-num}H#{FRAME_PART_C+FRAME_PART_A*num*2+FRAME_PART_C}"
    sleep 6.milliseconds
  end
end

def make_game_play_dialog_solid
    puts "\e[#{DIALOG_POS_H};H#{(FRAME_PART_C+FRAME_PART_A*(29*2)+FRAME_PART_C).center(100, '.')}"
    1.upto(DIALOG_SIZE_H-1) do |n|
      puts "\e[#{DIALOG_POS_H+n};H#{(FRAME_PART_B+"."*(29*2)+FRAME_PART_B).center(100, '.')}"
    end
    puts "\e[#{SCENE_SIZE_H};H#{(FRAME_PART_C+FRAME_PART_A*(29*2)+FRAME_PART_C).center(100, '.')}"
end

def print_game_play_dialog_text
  # 1行に入る文字数は半角58字(30*2-2)
  pos = {{ (SCENE_SIZE_W-DIALOG_SIZE_W) // 2 + 2}}
  print "\e[#{DIALOG_POS_H+1};#{pos}Hこんにちは!ABCいろは"
  print "\e[#{DIALOG_POS_H+2};#{pos}H1234567890123456789012345678901234567890123456789012345678"
  print "\e[#{DIALOG_POS_H+3};#{pos}HPress any key to exit."

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
# make_game_play_dialog_animate

make_game_play_dialog_solid
# sleep 1.seconds

STDIN.raw do |io|
  sleep 100.milliseconds
  next if io.read_char == 'q'
end