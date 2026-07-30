{% raise <<-TXT unless flag?(:win32)
your system is propably not Windows.
TXT
%}
HEADER_SIZE = 76
LINK_CLSID_A = 0x00021401

ZEROS_2 = Bytes.new(2, 0)
ZEROS_4 = Bytes.new(4, 0)
ZEROS_8 = Bytes.new(8, 0)

@[Link(dll: "Windows.Storage.dll")]
lib LibShell32
  fun sh_parse_display_name =
    SHParseDisplayName(
      p_szName : UInt16*,
      p_bc :  Void*,
      p_pidl : Void**,
      sfgaoIn : UInt16,
      p_sfgaoOut : UInt16*
  ) : UInt16
end

path = Dir.current+"\\text.txttxttxt"
# raise File::NotFoundError.new("file \"#{path}\" was not found", file: path) unless File.exists?(path)
unless File.exists?(path)
  print "file \"#{path}\" was not found."
  exit
end
file = File.open(path)

pidl = Pointer(Void).null

LibShell32.sh_parse_display_name(
  path.to_utf16,
  Pointer(Void).null,
  pointerof(pidl),
  0_u16,
  Pointer(UInt16).null
)

def pidl_total_byteSize(pidl : Pointer(Void))
  u8_pidl = pidl.as(UInt8*) 
  total = 2 # terminalID分をあらかじめ入れとくよ
  loop do
    section_size = u8_pidl.as(UInt16*).value # UInt16として2bytes取る
    total += section_size
    break if section_size == 0
    u8_pidl += section_size # アドレスを進めるかんじ 加算元がUint16*だと2*section_sizeになってしまう
  end
  total
end
# aaaaaa = pidl.as(UInt16*)
# pidl_total_size = 0
# offset = 0
# loop do
#   section_size = aaaaaa.value
#   # printf "%#02X\n", section_size
#   # puts section_size.class
#   pidl_total_size += section_size
#   if section_size == 0_u16
#     printf "terminal: %#02X\n", section_size
#     pidl_total_size += 2
#     break  
#   end
#   section_size.times do |i|
#     bbbbbb = aaaaaa[i]
#     printf ":%x\n", bbbbbb
#   end
#   aaaaaa += section_size
#   offset += section_size
# end
# printf "%#02X\n", pidl_total_size

# link_flags = 0x9B_00_08_00_u32
# link_flags = 0x00_08_00_9B_u32
# printf("%x", link_flags)
link_flags : UInt32

# -------- LinkFlags
has_link_target_idList = true
has_link_Info = true
has_name = false
has_relative_path = true
has_workingDir    = true
has_arguments     = false
has_iconLocation  = false
is_unicode        = true

force_no_linkInfo = false # I
has_expString     = false
run_in_separateProcess = false
# Unused1
has_darwin_id = false # M
run_as_user   = false
has_expIcon   = false
no_pid_alias  = false

# Unused2 # Q
run_with_ShimLayer     = false # R
force_no_linkTrack     = false
enable_target_metadata = true

disable_link_pathTracking = false     # U
disable_known_folder_tracking = false # V
disable_known_folder_allias = false   # W
allow_link_to_link = false            # X
unalias_on_save = false               # Y
prefer_environment_path = false       # Z
keep_localIdListForUNCTarget = false  # AA
# --------

struct Bool
end

link_flags = (
  # (if has_workingDir;0x10 else 0 end) |
  # (if has_arguments;0x20 else 0 end) |
  # (if has_iconLocation; 0x40 else 0 end) |
  # (if is_unicode;0x80 else 0 end) |
  # (if ;0x040000 else 0 end) | ファイル追跡無効
  (has_link_target_idList.to_unsafe <<  0) |
  (has_link_Info.to_unsafe          <<  1) |
  (has_name.to_unsafe               <<  2) |
  (has_relative_path.to_unsafe      <<  3) |
  (has_workingDir.to_unsafe         <<  4) |
  (has_arguments.to_unsafe          <<  5) |
  (has_iconLocation.to_unsafe       <<  6) |
  (is_unicode.to_unsafe             <<  7) | # 0x000000_80
  (force_no_linkInfo.to_unsafe      <<  8) |
  (has_expString.to_unsafe          <<  9) |
  (run_in_separateProcess.to_unsafe << 10) |
  #Unused1
  (has_darwin_id.to_unsafe << 12) |
  (run_as_user.to_unsafe << 13) |
  (has_expIcon .to_unsafe << 14) |
  (no_pid_alias .to_unsafe << 15) |
  # Unused2
  (run_with_ShimLayer .to_unsafe << 17) |
  (force_no_linkTrack .to_unsafe << 18) |
  (enable_target_metadata.to_unsafe << 19) |
  (disable_link_pathTracking.to_unsafe << 20) |
  (disable_known_folder_tracking.to_unsafe << 21) |
  (disable_known_folder_allias.to_unsafe << 22) |
  (allow_link_to_link.to_unsafe << 23) |
  (unalias_on_save.to_unsafe << 24) |
  (prefer_environment_path.to_unsafe << 25) |
  (keep_localIdListForUNCTarget.to_unsafe << 26)
).to_u32
# printf("link flags = 0x%08X\n", link_flags)

# link_flags = 0x00_08_00_9B_u32 # Windows 11 日本語での初期リンクフラグ

begin
  lnk = File.new("text_lnk", "wb")
  lnk.close
rescue err : File::Error
  puts err.class
  exit 1
end

File.open("text_lnk", "wb") do |lnk|
  # 00-03 (4 bytes) HeaderSize
  lnk.write_bytes(HEADER_SIZE, IO::ByteFormat::LittleEndian)
  # 04-13 (16 bytes) LinkCLSID (よくわからん)
  lnk.write_bytes(LINK_CLSID_A, IO::ByteFormat::LittleEndian)
  lnk.write(Bytes[
    0x00, 0x00, 0x00, 0x00,
    0xC0, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x46
  ])
  # 14-17 (4 bytes) LinkFlags
  lnk.write_bytes(link_flags, IO::ByteFormat::LittleEndian)
  # 18-1b (4 bytes) FileAttributes
  lnk.write(Bytes[0x20, 0x00, 0x00, 0x00]) # FILE_ATTRIBUTE_NORMAL
  
  # CreationTime   (8 bytes) 1C-23
  lnk.write(ZEROS_8)
  # 24-2B (8 bytes) AccessTime
  lnk.write(ZEROS_8)
  # 2C-33 (8 bytes) WriteTime
  lnk.write(ZEROS_8)

  # 34-37 (4 bytes) FileSize
  lnk.write_bytes(file.size.to_u32, IO::ByteFormat::LittleEndian)
  # 38-3b (4 bytes) IconIndex 
  lnk.write(ZEROS_4)
  # 3C-3F (4 bytes) ShowCommand
  # ウィンドウの設定 1=通常 3=最大 7=最小
  lnk.write_bytes(0x01)
  # 40-41 (2 bytes) HotKey
  lnk.write(ZEROS_2)  
  # 42-4B (2-4-4 bytes)  ReServed 1-2-3composed of
  lnk.write(Bytes.new(10, 0))
  # 4C-4D (2 bytes) IDListSize
  # 4E-  (variable IDListSize-2 bytes) ItemIDList
  # (2 bytes) TerminalID
  size_IDList = pidl_total_byteSize(pidl)
  printf "IDList size = %#04x\n", size_IDList
  lnk.write(Bytes.new(pidl.as(UInt8*), size_IDList))
  # itemIDSize
  # itemID
  # (4 bytes) LinkInfoSize
  # (4 bytes) LinkInfoHeaderSize
  # (4 bytes) LinkInfoFlags
  # (4 bytes) VolumeIDOffset
  # (4 bytes) LocalBasePathOffset
  # (4 bytes) CommonNetWorkRelativeLinkOffset
  # ...

  printf("file written to %#x...\n", lnk.pos)
end
