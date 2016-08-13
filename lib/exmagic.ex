defmodule ExMagic do
  @moduledoc """
  Binding to libmagic to gather information about a file.
  """

  # Run the given function when the VM loads.
  @on_load :init

  @doc false
  def init do
    # Load the NIF on the path to the library
    path = Application.app_dir(:exmagic, "priv/exmagic") |> String.to_char_list
    :ok = :erlang.load_nif(path, 0)
  end

  @doc """
  Retrieves magic information from the given buffer.


  ## Examples

    iex> ExMagic.from_buffer("foo")
    {:ok, "text/plain"}
  """
  @spec from_buffer(binary) :: {:ok, binary} | {:error, atom}
  @spec from_buffer(List.t) :: {:ok, binary} | {:error, atom}
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
  @spec from_buffer!(List.t) :: binary
  def from_buffer!(buf) do
    {:ok, magic} = from_buffer(buf)
    magic
  end

  ##################################################
  ## HELPER FUNCTIONS

  @spec magic_path() :: String.t
  defp magic_path do
    Application.app_dir(:exmagic, "priv/magic.mgc")
  end

  ##################################################
  ## PRIVATE NIF FUNCTIONS

  @doc false
  def nif_from_buffer(_buf, _magic_path) do
    exit(:nif_not_loaded)
  end
end
