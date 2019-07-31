#!/usr/bin/env ruby
#
# Reformats output of Pahole utility:
#   https://git.kernel.org/pub/scm/devel/pahole/pahole.git
#
# Change the following fields to reformat the output:
#   Field::CHARS_PER_BYTE
#   Structure::BYTES_PER_MARK
#   CStruct::BYTES_PER_LINE
#

class Field

  CHARS_PER_BYTE=4

  attr_accessor :type
  attr_accessor :name
  attr_accessor :offset
  attr_accessor :size

  def initialize (type, name, offset, size)
    @type, @name, @offset, @size = type, name, offset, size
  end

  def to_s
    if @name == "" then
      "#" * (@size * CHARS_PER_BYTE - 1)
    else
      @name + " : " + @type
    end
  end

  def to_lbl (width)
    lbl = to_s.center(width)
    lbl = @name[0..width-1].center(width) if lbl.size > width
    lbl
  end

end

class Structure

  BYTES_PER_MARK=4

  attr_accessor :name
  attr_accessor :fields

  def initialize (name)
    @name, @fields = name, []
  end

  def axis (bytes)
    line_offset = 0
    labels = ""
    marks = ""
    while (line_offset <= bytes)
      width = Field::CHARS_PER_BYTE * Structure::BYTES_PER_MARK
      labels += "%-#{width}d"%[line_offset]
      marks  += "%-#{width}s"%["|"]
      line_offset += Structure::BYTES_PER_MARK
    end
    labels.strip + "\n" + marks.strip
  end

end

class CStruct < Structure

  BYTES_PER_LINE=16

  def size
    @fields.map {|f| f.size}.inject(:+)
  end

  def to_s
    s = "struct #{@name}:\n\n"

    # generate axis/labels
    s += axis(size < BYTES_PER_LINE ? size : BYTES_PER_LINE) + "\n"

    # print initial top bar
    if size < BYTES_PER_LINE then
      s += "-" * size * Field::CHARS_PER_BYTE + "-\n"
    else
      s += "-" * BYTES_PER_LINE * Field::CHARS_PER_BYTE + "-\n"
    end

    # generate each field
    fidx = 0
    leftover_bytes = 0
    struct_offset = 0
    while fidx < @fields.size and struct_offset < size
      line_offset = 0


      # finish any leftover bytes from the previous field
      while leftover_bytes >= BYTES_PER_LINE
        s += "|%-#{BYTES_PER_LINE*Field::CHARS_PER_BYTE-1}s|\n"%[""]
        s += "-" * BYTES_PER_LINE * Field::CHARS_PER_BYTE + "-\n"
        leftover_bytes -= BYTES_PER_LINE
        struct_offset  += BYTES_PER_LINE
      end
      if leftover_bytes > 0 then
        s += "|%-#{leftover_bytes*Field::CHARS_PER_BYTE-1}s"%[""]
        line_offset   += leftover_bytes
        struct_offset += leftover_bytes
      end

      # add fields until we get to the end of the line
      while fidx < @fields.size and line_offset < BYTES_PER_LINE

        # add field
        f = @fields[fidx]
        if f.offset != struct_offset then
          puts "Error: offset mismatch at field #{f.name}!"
          exit
        end
        bytes_left = BYTES_PER_LINE - line_offset
        bytes_to_print = f.size < bytes_left ? f.size : bytes_left
        chars_to_print = bytes_to_print * Field::CHARS_PER_BYTE
        s += "|" + f.to_lbl(chars_to_print-1)

        # increment counters
        line_offset += bytes_to_print
        struct_offset += bytes_to_print
        leftover_bytes = f.size - bytes_to_print
        fidx += 1
      end
      s += "|\n"
      s += "-" * line_offset * Field::CHARS_PER_BYTE + "-\n"
    end
    s
  end

end

class CUnion < Structure

  def to_s
    s = "union #{@name}:\n\n"

    # generate axis/labels
    max_field_size = @fields.map {|f| f.size}.inject {|a,b| a > b ? a : b}
    s += axis(max_field_size) + "\n"

    # generate each field
    prev_size = 0
    @fields.each do |f|
      top_width = f.size > prev_size ? f.size : prev_size
      s += ("-" * top_width * Field::CHARS_PER_BYTE) + "-\n"
      s += "|#{f.to_lbl(f.size * Field::CHARS_PER_BYTE-1)}|\n"
      prev_size = f.size
    end
    s += ("-" * prev_size * Field::CHARS_PER_BYTE) + "-\n"
    s
  end

end


cur_data = nil

ARGF.each_line do |line|
  if line =~ /^(struct|class) (\w+) {/ then
    cur_data = CStruct.new($2)
  elsif line =~ /^union (\w+) {/ then
    cur_data = CUnion.new($1)
  elsif line =~ /^};/ then
    puts "#{cur_data.to_s}\n\n" unless cur_data.nil?
    cur_data = nil
  elsif line =~ /^(.*) ([\w\[\]]+); *\/\* *(\d+) *(\d+)/ then
    cur_data.fields << Field.new($1.strip, $2, $3.to_i, $4.to_i) unless cur_data.nil?
  elsif line =~ /XXX (\d+) bytes hole/ then
    cur_data.fields << Field.new("", "", cur_data.size, $1.to_i) unless cur_data.nil?
  end
end

