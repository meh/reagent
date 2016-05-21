defmodule Reagent.Mixfile do
  use Mix.Project

  def project do
    [ app:     :reagent,
      version: "0.1.9",
      deps:    deps,
      package: package,
      description: "You need more reagents to conjure this server" ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:exts, :socket] ]
  end

  defp deps do
    [ { :socket, "~> 0.3" },
      { :exts,   "~> 0.3" } ]
  end

  defp package do
    [ maintainers: ["meh"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/meh/reagent"} ]
  end
end
