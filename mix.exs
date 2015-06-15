defmodule Grog.Mixfile do
  use Mix.Project

  def project do
    [app: :grog,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps,
     escript: escript]
  end

  def application do
    [mod: {Grog.App, []},
     registered: [Grog.Client.Supervisor],
     applications: [:logger, :shotgun, :cowboy, :plug]]
  end

  defp deps do
    [{:cowboy, github: "ninenines/cowboy", tag: "1.0.1", override: true},
     {:plug, "~> 0.12.2"},
     {:shotgun, github: "inaka/shotgun", tag: "master"},
     {:eden, "~> 0.1.3"},
     # Override these two deps because they conflict between cowboy and gun.
     {:cowlib, "~> 1.0.0", override: true},
     {:ranch, "~> 1.0.0", override: true},

     {:exreloader, github: "jfacorro/exreloader", tag: "master", only: :dev},
     {:eep, github: "virtan/eep", tag: "v1.1", only: :dev},
     {:katana, github: "inaka/erlang-katana", tag: "0.2.5", only: :dev}
    ]
  end

  def escript do
    [main_module: Grog.CLI,
     path: "bin/grog"]
  end
end
