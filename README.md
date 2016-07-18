# Joker

**Joker is a socket acceptor pool for TCP protocol.**

## Installation

  1. Add joker to your list of dependencies in `mix.exs`:

        def deps do
          [{:joker, "~> 0.1.0"}]
        end

  2. Ensure joker is started before your application:

        def application do
          [applications: [:joker]]
        end
