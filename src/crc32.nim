from strutils import toHex

type
  TCrc32* = uint32


proc `$`*(crc: TCrc32): string =
  result = crc.int64.toHex(8)


const InitCrc32* = TCrc32(0)


func createCrcTable(): array[0..255, TCrc32] {.inline.} =
  for i in 0..255:
    var rem = TCrc32(i)
    for j in 0..7:
      if (rem and 1) > 0'u32: rem = (rem shr 1) xor TCrc32(0xedb88320)
      else: rem = rem shr 1
    result[i] = rem


const crc32table = createCrcTable()

func updateCrc32(c: char, crc: var TCrc32) {.inline.} =
  crc = (crc shr 8) xor crc32table[(crc and 0xff) xor uint32(ord(c))]

func crc32*(s: string): TCrc32 =
  result = InitCrc32
  for c in s:
    updateCrc32(c, result)
  result = not result

proc crc32FromFile*(filename: string): TCrc32 =
  const bufSize = 8192
  var bin: File
  result = InitCrc32

  if not open(bin, filename):
    return

  var buf {.noinit.}: array[bufSize, char]

  while true:
    var readBytes = bin.readChars(buf, 0, bufSize)
    for i in countup(0, readBytes - 1):
      updateCrc32(buf[i], result)
    if readBytes != bufSize:
      break

  close(bin)
  result = not result


when is_main_module:
  echo crc32("The quick brown fox jumps over the lazy dog.")
