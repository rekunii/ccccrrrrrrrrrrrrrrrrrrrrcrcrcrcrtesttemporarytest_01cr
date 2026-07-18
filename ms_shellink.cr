HEADER_SIZE = 76
LINK_CLSID_A = 0x00021401





File.open("some_lnk", "wb") do |lnk|
  # HeaderSize 
  lnk.write_bytes(HEADER_SIZE, IO::ByteFormat::LittleEndian)
  # LinkCLSID (よくわからん)
  lnk.write_bytes(LINK_CLSID, IO::ByteFormat::LittleEndian)
  lnk.write(Bytes[
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0xC0, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x46
  ])
  # LinkFlags (4 bytes)

end
