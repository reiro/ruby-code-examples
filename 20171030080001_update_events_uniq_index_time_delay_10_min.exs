defmodule Stats.Repo.Migrations.UpdateEventsUniqIndexTimeDelay10Min do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION round_time(TIMESTAMP)
    RETURNS TIMESTAMP AS $$
    SELECT date_trunc('hour', $1) + INTERVAL '5 min' * ROUND(date_part('minute', $1) / 5.0)
    $$ language SQL IMMUTABLE;
    """

    execute("DROP INDEX events_unique_index")
    execute("DROP INDEX ad_unit_events_unique_index")

    execute("CREATE UNIQUE INDEX events_unique_index ON events(category, ad_id, round_time(inserted_at),
      client_uid) WHERE client_uid IS NOT NULL")
    execute("CREATE UNIQUE INDEX ad_unit_events_unique_index ON ad_unit_events(category, ad_unit_id,
      size, content_type, round_time(inserted_at), client_uid) WHERE client_uid IS NOT NULL")
  end

  def down do
    execute("DROP INDEX events_unique_index")
    execute("DROP INDEX ad_unit_events_unique_index")

    execute("CREATE UNIQUE INDEX events_unique_index ON events(category, ad_id, date_trunc('minute', inserted_at),
      client_uid) WHERE client_uid IS NOT NULL")
    execute("CREATE UNIQUE INDEX ad_unit_events_unique_index ON ad_unit_events(category, ad_unit_id,
      size, content_type, ad_id, date_trunc('minute', inserted_at), client_uid) WHERE client_uid IS NOT NULL")
  end
end
