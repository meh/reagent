defmodule Reagent.Mixfile do
  use Mix.Project

  def project do
    [ app:     :reagent,
      version: "0.0.3",
      elixir:  "~> 0.12.5",
      deps:    deps ]
  end

  def application do
    [ applications: [:datastructures, :exts, :socket] ]
  end

  defp deps do
    [ { :socket,         github: "meh/elixir-socket" },
      { :datastructures, github: "meh/elixir-datastructures" },
      { :exts,           github: "meh/exts" } ]
  end
end
