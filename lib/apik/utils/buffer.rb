# Copyright 2012-2014 Aerospike, Inc.
#
# Portions may be licensed to Aerospike, Inc. under one or more contributor
# license agreements.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

require 'apik/utils/pool'

module Apik

  # Buffer class to ease the work around
  class Buffer

    @bufPool = Pool.new
    @bufPool.create_block = Proc.new { Buffer.new }

    attr_accessor :buf

    INT16 = 's>'.freeze
    INT32 = 'l>'.freeze
    INT64 = 'q>'.freeze

    DEFAULT_BUFFER_SIZE = 16* 1024
    MAX_BUFFER_SIZE = 10 * 1024 * 1024
    NULL_BYTE = 0.chr

    def initialize(size=DEFAULT_BUFFER_SIZE)
      @buf = NULL_BYTE * size
      @buf.force_encoding('binary')

      @slice_end = @buf.bytesize
    end

    def self.get
      return @bufPool.poll
    end

    def self.put(buffer)
      @bufPool.offer(buffer)
    end

    def size
      @buf.bytesize
    end
    alias_method :length, :size

    def resize(length)
      if @buf.bytesize < length
        @buf << NULL_BYTE * (length - @buf.bytesize)
      end
      @slice_end = length
    end

    def write_byte(byte, offset)
      @buf[offset] = chr(byte)
      1
    end

    def write_binary(data, offset)
      if data.encoding != Encoding.find('binary')
        data = data.dup.force_encoding('binary')
      end
      @buf[offset, data.length] = data
      data.length
    end

    def write_array(array, offset)
      @buf[offset, array.length] = array.pack("C*")
      array.length
    end

    # def write_int(i, offset, bytes)
    #   pack_type = (bytes == 4) ? INT32 : INT64

    #   @buf[offset, bytes] = [i].pack(pack_type)
    # end

    def write_int16(i, offset)
      @buf[offset, 2] = [i].pack(INT16)
      2
    end

    def write_int32(i, offset)
      @buf[offset, 4] = [i].pack(INT32)
      4
    end

    def write_int64(i, offset)
      @buf[offset, 8] = [i].pack(INT64)
      8
    end

    def read(offset, len=nil)
      len ||= 1
      is_single_byte = (len == 1)
      validate_read(offset, len)
      start = offset

      if is_single_byte
        @buf[start]
      else
        @buf[start, len]#.unpack("C*")
      end
    end

    def read_int16(offset)
      validate_read(offset, 2)
      vals = @buf[offset..offset+1]
      vals.unpack(INT16)[0]
    end

    def read_int32(offset)
      validate_read(offset, 4)
      vals = @buf[offset..offset+3]
      vals.unpack(INT32)[0]
    end

    def read_int64(offset)
      validate_read(offset, 8)
      vals = @buf[offset..offset+7]
      vals.unpack(INT64)[0]
    end

    def to_a(format="C*")
      @buf.unpack(format)
    end

    def unpack(format="C*")
      to_a(format)
    end

    def to_s
      @buf[0..@slice_end-1]
    end

    def dump(from=nil, to=nil)
      from ||= 0
      to ||= @slice_end - 1

      @buf.bytes[from..to-1].each do |c|
        putc c
      end
    end

    private

    def chr(byte)
      # if byte.is_a?(FixedNum) && byte < 0
      #   [byte].pack('c')
      # else
        byte.chr
      # end
    end

    def validate_read(offset, len)
      raise "buffer overflow error" if offset + len > @buf.length
    end

  end # buffer

end # module