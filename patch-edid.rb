#!/usr/bin/ruby
# Create display override file to force macOS to use RGB mode for Display.
# Based on script from http://embdev.net/topic/284710

require 'base64'

data=`ioreg -l -w0 -d0 -r -c AppleDisplay`
edid_hex=data.match(/IODisplayEDID.*?<([a-z0-9]+)>/i)[1]
vendorid=data.match(/DisplayVendorID.*?([ 0-9]+)/i)[1].to_i
productid=data.match(/DisplayProductID.*?([ 0-9]+)/i)[1].to_i

puts "Found display: vendorid #{vendorid}, productid #{productid}"

bytes=edid_hex.scan(/../).map{|x|Integer("0x#{x}")}.flatten

# This is the "Magic": it sets the color support to RGB 4:4:4 only
bytes[24] &= ~(0b11000)
bytes[126] = 0
bytes[127] = (256 - bytes[0..126].reduce(:+) % 256) % 256

puts "New EDID Calculated. Creating override file..."

Dir.mkdir("DisplayVendorID-%x" % vendorid) rescue nil
f = File.open("DisplayVendorID-%x/DisplayProductID-%x" % [vendorid, productid], 'w')
f.write '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>DisplayProductName</key>
  <string>Forced RGB Mode (EDID Override)</string>
  <key>IODisplayEDID</key>
  <data>' + Base64.encode64(bytes.pack('C*')).gsub("\n", '') + '</data>
  <key>DisplayVendorID</key>
  <integer>' + vendorid.to_s + '</integer>
  <key>DisplayProductID</key>
  <integer>' + productid.to_s + '</integer>
</dict>
</plist>'
f.close
puts "Done! Folder 'DisplayVendorID-#{vendorid.to_s(16)}' created."
