defmodule ExMagic.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exmagic,
      description: "Wrapper around libmagic",
      version: "0.0.2",
      package: package(),
      name: "ExMagic",
      source_url: "https://github.com/andrew-d/exmagic",
      homepage_url: "https://andrew-d.github.io/exmagic/",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      compilers: [:make, :elixir, :app],
      aliases: aliases(),
      deps: deps(),
    ]
  end

  defp aliases do
    # Execute the usual "mix clean", and also "make clean" in the general clean
    # task.
    [clean: ["clean", "clean.make"]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    []
  end

  defp package do
    [
      name: :exmagic,
      files: ["c_src", "lib", "mix.exs", "README*", "LICENSE*", ".file-version"],
      maintainers: ["Andrew Dunham"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/andrew-d/exmagic",
               "Docs" => "https://andrew-d.github.io/exmagic/"},
    ]
  end

  defp deps do
    version = File.read!(".file-version")
    |> ExMagic.Mixfile.trim
    |> String.replace(".", "_")

    [
      # This is a non-Elixir dependency that we have Mix fetch.  We use this to
      # compile libmagic into our NIF's shared object.
      {:libmagic, git: "https://github.com/file/file", tag: "FILE#{version}", app: false, compile: false},

      # Development / testing dependencies
      {:dialyxir, "~> 0.3.5", only: :test},
      {:ex_doc, "~> 0.12", only: :docs},
    ]
  end

  def trim(s) do
    if :erlang.function_exported(String, :trim, 1) do
      String.trim(s)
    else
      String.strip(s)
    end
  end
end


# Makefile tasks

defmodule Mix.Tasks.Compile.Make do
  @shortdoc "Compiles helper in c_src"

  def run(_) do
    if match? {:win32, _}, :os.type do
      exit(:not_supported)
    else
      {result, _error_code} = System.cmd("make", [], stderr_to_stdout: true)
      Mix.shell.info result
    end

    :ok
  end
end

defmodule Mix.Tasks.Clean.Make do
  @shortdoc "Cleans helper in c_src"

  def run(_) do
    {result, _error_code} = System.cmd("make", ['clean'], stderr_to_stdout: true)
    Mix.shell.info result

    :ok
  end
end
