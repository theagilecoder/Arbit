defmodule Arbit.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {Phoenix.PubSub, name: Arbit.PubSub},
      Arbit.Repo,
      ArbitWeb.Endpoint,
      Arbit.Scheduler
    ]

    opts = [strategy: :one_for_one, name: Arbit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    ArbitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
