require 'debug'

def get_16_bit(data, index)
  data[index] | data[index + 1] << 8
end

def get_24_bit(data, index)
  get_16_bit(data, index) | data[index + 2] << 16
end

def get_32_bit(data, index)
  get_24_bit(data, index) | data[index + 3] << 24
end

img_bytes = File.binread('parrot.webp').bytes

container_format = img_bytes[0..3].pack('C*')
image_format = img_bytes[8..11].pack('C*')
compression_format = img_bytes[12..15].pack('C*')
# 16, 17, 18, 19 reserved

size = get_32_bit(img_bytes, 4)

width = nil
height = nil

if compression_format == 'VP8 '
  # Simple File Format (Lossy)
  # https://datatracker.ietf.org/doc/html/rfc6386#section-19.1
  width = get_16_bit(img_bytes, 26)
  height = get_16_bit(img_bytes, 28)
elsif compression_format == 'VP8X'
  # Extended File Format
  # https://developers.google.com/speed/webp/docs/riff_container#extended_file_format
  width = 1 + get_24_bit(img_bytes, 24)
  height = 1 + get_24_bit(img_bytes, 27)
elsif compression_format == 'VP8L'
  # Simple File Format (Lossless)
  # https://developers.google.com/speed/webp/docs/webp_lossless_bitstream_specification#3_riff_header
  first_bytes = get_16_bit(img_bytes, 21)
  width = 1 + (first_bytes & 0x3FFF)

  # The last 2 bits correspond to the first 2 bits of the height
  last_two_digits = (first_bytes & 0xC000) >> 14
  # Extract the remaining 12 bits and shift them to add space for the two digits
  height = 1 + (get_16_bit(data, 23) & 0xFFF << 2) | last_two_digits
end

puts "container_format: #{container_format}"
puts "image_format: #{image_format}"
puts "compression_format: #{compression_format}"

puts "#{width} x #{height}"
puts "#{(size / 1000.0).round}KB"
