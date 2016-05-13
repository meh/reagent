defmodule Reagent.Mixfile do
  use Mix.Project

  def project do
    [ app:     :reagent,
      version: "0.1.5",
      elixir:  "~> 1.0.0-rc1 or ~> 1.1.0-rc.0 or ~> 1.2.0-rc.0",
      deps:    deps,
      package: package,
      description: "You need more reagents to conjure this server" ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:exts, :socket] ]
  end

  defp deps do
    [ { :socket, "~> 0.2.6" },
      { :exts,   "~> 0.2.0" } ]
  end

  defp package do
    [ contributors: ["meh"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/meh/reagent"} ]
  end
end
