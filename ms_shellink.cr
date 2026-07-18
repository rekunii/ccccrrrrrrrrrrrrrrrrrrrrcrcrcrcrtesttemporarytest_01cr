HEADER_SIZE = 76
LINK_CLSID_A = 0x00021401

ZEROS_2 = Bytes.new(2, 0)
ZEROS_4 = Bytes.new(4, 0)
ZEROS_8 = Bytes.new(8, 0)

file = File.open("text.txttxttxt")

# link_flags = 0x9B_00_08_00_u32
# link_flags = 0x00_08_00_9B_u32
# printf("%x", link_flags)
link_flags : UInt32

# # -------- LinkFlags (ビット位置は合ってるか不明…)
# has_link_target_idList =
# has_link_Info =
# has_name =
# has_relative_path =
has_workingDir    = true  # 0x10  <-これらはリトル
has_arguments     = false # 0x20    エンディアンとして
has_iconLocation  = false # 0x40    の表記
is_unicode        = true  # 0x80
# force_no_linkInfo = true  # 0x01
# has_expString     = true  # 0x02
# run_in_separateProcess = false #0x04
# # undefined1 0x08

# has_darwin_id = false          # 0x00_10
# run_as_user   = false          # 0x00_20
# has_expIcon   = false          # 0x00_40
# no_pid_alias  = false          # 0x00_80
# # unused2                      # 0x00_01
# run_with_ShimLayer     = false # 0x00_02
# force_no_linkTrack     = false # 0x00_04
# enable_target_metadata = false # 0x00_08

# disable_link_pathTracking = false       # 0x00_00_10
# disable_known_folder_tracking = false   # 0x00_00_20
# disable_known_folder_allias = false   # 0x00_00_40
# allow_link_to_link = false            # 0x00_00_80
# unalias_os_save = false               # 0x00_00_01
# prefer_environment_path = false       # 0x00_00_02
# keep_localIdListForUNCTarget = false  # 0x00_00_04
# # --------

link_flags = (
  (if has_workingDir;0x10 else 0 end) |
  (if has_arguments;0x20 else 0 end) |
  (if has_iconLocation; 0x40 else 0 end) |
  (if is_unicode;0x80 else 0 end) |
  # (if ;0x040000 else 0 end) | ファイル追跡無効
  0
).to_u32
# printf("0x%04x", link_flags)

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
  lnk.write_bytes(link_flags)
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
  printf("%#x\n", lnk.pos)
  #  
end
