defmodule ExMagicTest do
  use ExUnit.Case
  doctest ExMagic

  test "from_binary works" do
    # Small (valid) transparent PNG
    png_str = "89504E470D0A1A0A0000000D4948445200000001000000010100000000376EF9240000001049444154789C626001000000FFFF03000006000557BFABD40000000049454E44AE426082"
    png = Base.decode16!(png_str)

    assert ExMagic.from_buffer(png) == {:ok, "image/png"}
  end

  test "from_binary invalid" do
    assert ExMagic.from_buffer("blah") == {:ok, "text/plain"}
  end

  test "from_binary blank" do
    assert ExMagic.from_buffer("") == {:ok, "application/x-empty"}
  end

  test "from_binary with char list" do
    assert ExMagic.from_buffer('foo') == {:ok, "text/plain"}
  end

  test "from_binary!" do
    assert ExMagic.from_buffer!("foo") == "text/plain"
  end

  test "from_file" do
    assert ExMagic.from_file("kitten.jpg") == {:ok, "image/jpeg"}
  end

  test "from_file!" do
    assert ExMagic.from_file!("kitten.jpg") == "image/jpeg"
  end

  test "from_file nonexistent file" do
    assert ExMagic.from_file("nonexistent.file") == {:error, :file_does_not_exist}
  end
end
