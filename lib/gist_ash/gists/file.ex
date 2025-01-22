defmodule GistAsh.Gists.File do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: GistAsh.Gists

  postgres do
    table "gist_files"
    repo GistAsh.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :filename, :string, allow_nil?: false
    attribute :content, :string, allow_nil?: false
    timestamps()
  end

  relationships do
    belongs_to :gist, GistAsh.Gists.Gist
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:filename, :content, :gist_id]
    end

    update :update do
      primary? true
      accept [:filename, :content]
    end
  end
end
