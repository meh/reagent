defmodule Reagent.Mixfile do
  use Mix.Project

  def project do
    [ app:     :reagent,
      version: "0.1.0",
      elixir:  "~> 0.13.0",
      deps:    deps,
      package: package,
      description: "You need more reagents to conjure this server." ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:socket] ]
  end

  defp deps do
    [ { :socket, "~> 0.2.0" },
      { :exts,   "~> 0.1.0" } ]
  end

  defp package do
    [ contributors: ["meh"],
      licenses: ["WTFPL"],
      links: [ { "GitHub", "https://github.com/meh/reagent" } ] ]
  end
end
