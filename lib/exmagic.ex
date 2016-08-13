defmodule ExMagic do
  # Specifies a function to run when the VM loads
  @on_load :init

  def init do
    # Load the NIF on the path to the library
    path = Application.app_dir(:exmagic, "priv/exmagic") |> String.to_char_list
    :ok = :erlang.load_nif(path, 0)
  end

  # Then we define a version of our nif function that will exit with
  # `:nif_not_loaded`.  This function will be replaced by the specified C
  # function when the nif is loaded, so if we hadn't loaded the nif this
  # function call would exit.
  def nif_from_buffer(_buf, _magic_path) do
    exit(:nif_not_loaded)
  end

  def from_buffer(buf) do
    {:ok, magic} = nif_from_buffer(
      buf,
      magic_path()
    )

    magic
  end

  defp magic_path do
    Application.app_dir(:exmagic, "priv/magic.mgc")
  end
end
