defmodule Joker.Mixfile do
  use Mix.Project

  def project do
    [app: :joker,
     version: "0.1.0",
     elixir: "~> 1.2",
     description: description,
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Joker, []}]
  end

  defp description do
    """
    Socket acceptor pool for TCP protocol written in Elixir.
    """
  end

  defp package do
    [
      name: :joker,
      licenses: ["Mit License"],
      maintainers: ["0x00evil", "0x00evil@gmail.com"],
      links: %{"Github" => "https://github.com/0x00evil/joker"}
    ]
  end

  defp deps do
    []
  end
end
