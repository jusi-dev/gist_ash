defmodule GistAsh.Gists.Gist do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: GistAsh.Gists,
    authorizers: [Ash.Policy.Authorizer]

  alias GistAsh.Gists.Changes

  postgres do
    table "gists"
    repo GistAsh.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :description, :string
    attribute :public, :boolean, default: true
    attribute :user_id, :uuid
    timestamps()
  end

  relationships do
    belongs_to :user, GistAsh.Accounts.User
    has_many :files, GistAsh.Gists.File
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      argument :files, {:array, :map}, allow_nil?: false
      accept [:description, :public, :user_id]

      change manage_relationship(:files, type: :create)
      change {Changes.Notifier, attribute: :foo}
    end

    update :update do
      primary? true
      argument :files, {:array, :map}, allow_nil?: false
      accept [:description, :public, :user_id]
      require_atomic? false

      change manage_relationship(:files, type: :direct_control)
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if relates_to_actor_via(:user)
      authorize_if expr(public == true)
      # authorize_if always()
    end

    policy action_type([:create]) do
      authorize_if actor_present()
    end

    policy action_type([:update, :destroy]) do
      authorize_if relates_to_actor_via(:user)
    end
  end
end
