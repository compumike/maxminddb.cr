class MaxMindDB::Buffer
  getter size : Int32

  @fp : File
  @is_tempfile : Bool = false

  def position
    @fp.pos
  end

  def position=(idx : Int64) : Nil
    @fp.seek(idx)
  end

  def initialize(bytes : Bytes)
    @is_tempfile = true
    @fp = File.tempfile("maxminddb.buffer")
    @fp.write(bytes)
    @fp.seek(0)

    @size = @fp.size.to_i32
  end

  def finalize
    @fp.close

    if @is_tempfile
      @fp.delete
    end
  end

  def initialize(path : String)
    @is_tempfile = false
    @fp = File.open(path, "rb")
    @size = @fp.size.to_i32
  end

  # Reads *size* bytes from this bytes buffer.
  # Returns empty `Bytes` if and only if there is no
  # more data to read.
  def read(size : Int32) : Bytes
    slice = Bytes.new(size)

    begin
      @fp.read_fully(slice)
    rescue IO::EOFError
      return Bytes.new(0)
    end

    slice
  end

  # Read one byte from bytes buffer
  # Returns 0 if and only if there is no
  # more data to read.
  def read_byte : UInt8
    value = @fp.read_byte

    if value.nil?
      0u8
    else
      value.not_nil!
    end
  end

  # Returns the index of the _last_ appearance of *search*
  # in the bytes buffer
  #
  # ```
  # Buffer.new(Bytes[1, 2, 3, 4, 5]).rindex(Bytes[3, 4]) # => 2
  # ```
  def rindex(search : Bytes) : Int32?
    (@size - search.size - 1).downto(0) do |i|
      return i if self[i, search.size] == search
    end
  end

  def [](idx : Int) : UInt8
    raise IndexError.new if idx >= @size

    old_pos = @fp.pos
    @fp.seek(idx)
    value = @fp.read_byte.not_nil!
    @fp.seek(old_pos)

    value
  end


  def [](start : Int, count : Int) : Bytes
    slice = Bytes.new(count)

    old_pos = @fp.pos
    @fp.seek(start)
    @fp.read_fully(slice)
    @fp.seek(old_pos)

    slice
  end

  #macro method_missing(call)
  #  @bytes.{{call.name}}({{*call.args}})
  #end
end
