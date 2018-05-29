defmodule ExMagic do
  @moduledoc """
  Binding to libmagic to gather information about a file.
  """

  # Path to our directory containing the NIF shared object and magic database.
  @priv_dir Path.join(Path.expand("../", __DIR__), "priv")

  # Run the given function when the VM loads.
  @on_load :init

  @doc false
  def init do
    path = Path.join(@priv_dir, "exmagic") |> String.to_charlist()
    :ok = :erlang.load_nif(path, 0)
  end

  @doc """
  Retrieves magic information from the given buffer.


  ## Examples

      iex> ExMagic.from_buffer("foo")
      {:ok, "text/plain"}
  """
  @spec from_buffer(binary) :: {:ok, binary} | {:error, atom}
  @spec from_buffer(List.t()) :: {:ok, binary} | {:error, atom}
  def from_buffer(buf) when is_binary(buf) do
    nif_from_buffer(
      buf,
      magic_path()
    )
  end

  def from_buffer(buf) when is_list(buf) do
    nif_from_buffer(
      buf |> to_string,
      magic_path()
    )
  end

  @doc """
  Retrieves magic information from the given buffer.  Fails on an error.

  ## Examples

      iex> ExMagic.from_buffer!("foo")
      "text/plain"
  """
  @spec from_buffer!(binary) :: binary
  @spec from_buffer!(List.t()) :: binary
  def from_buffer!(buf) do
    {:ok, magic} = from_buffer(buf)
    magic
  end

  @doc """
  Retrieves magic information from the given file.
  """
  @spec from_file(String.t()) :: {:ok, binary} | {:error, atom}
  def from_file(path) do
    if File.exists?(path) do
      nif_from_file(
        path,
        magic_path()
      )
    else
      {:error, :file_does_not_exist}
    end
  end

  @doc """
  Retrieves magic information from the given file.  Fails on an error.
  """
  @spec from_file!(String.t()) :: binary
  def from_file!(path) do
    {:ok, magic} = from_file(path)
    magic
  end

  @doc """
  Returns the version of libmagic in use.

  ## Examples

      iex> ExMagic.version()
      529
  """
  @spec version() :: Integer.t()
  def version() do
    exit(:nif_not_loaded)
  end

  ##################################################
  ## HELPER FUNCTIONS

  @spec magic_path() :: String.t()
  defp magic_path do
    Path.join(@priv_dir, "magic.mgc")
  end

  ##################################################
  ## PRIVATE NIF FUNCTIONS

  @doc false
  def nif_from_buffer(_buf, _magic_path) do
    exit(:nif_not_loaded)
  end

  @doc false
  def nif_from_file(_file, _magic_path) do
    exit(:nif_not_loaded)
  end
end
