defmodule Reagent.Mixfile do
  use Mix.Project

  def project do
    [ app: :reagent,
      version: "0.0.1",
      elixir: "~> 0.10.3-dev",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:socket, :derp] ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ { :socket, github: "meh/elixir-socket" },
      { :datastructures, github: "meh/elixir-datastructures" },
      { :exts, github: "meh/exts" },
      { :derp, github: "meh/derp" } ]
  end
end
