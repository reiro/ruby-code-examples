defmodule Stats.Repo.Migrations.AddCustomReportsTrigger do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION current_reports_update() returns trigger as $$
    declare
      category varchar(20);
    begin
      category := CONCAT(new.category, 's');
      UPDATE current_reports SET data = data || CONCAT('{"', category, '":', COALESCE(data->>category,'0')::int + 1, '}')::jsonb
      WHERE current_reports.ad_id = new.ad_id;
      RETURN NEW;
    end
    $$ language plpgsql;
    """

    execute """
    create trigger current_reports_update
    after insert on events
    for each row
      execute procedure current_reports_update();
    """

    execute """
    CREATE OR REPLACE FUNCTION ad_unit_current_reports_update() returns trigger as $$
    declare
      category varchar(20);
      category_number integer;
    begin
      category_number := new.category;
      CASE category_number
        WHEN 0 THEN category := 'impressions';
        WHEN 1 THEN category := 'clicks';
        WHEN 2 THEN category := 'swipes';
        WHEN 3 THEN category := '5s_views';
        WHEN 4 THEN category := '50%_views';
        WHEN 5 THEN category := '100%_views';
      END CASE;
      UPDATE ad_unit_current_reports SET data = data || CONCAT('{"', category, '":', COALESCE(data->>category,'0')::int + 1, '}')::jsonb
      WHERE ad_unit_current_reports.ad_unit_id = new.ad_unit_id AND
        ad_unit_current_reports.content_type = new.content_type AND
        ad_unit_current_reports.size = new.size;
      RETURN NEW;
    end
    $$ language plpgsql;
    """

    execute """
    create trigger ad_unit_current_reports_update
    after insert on ad_unit_events
    for each row
      execute procedure ad_unit_current_reports_update();
    """
  end

  def down do
    execute "DROP FUNCTION IF EXISTS current_reports_update() CASCADE;"
    execute "DROP FUNCTION IF EXISTS ad_unit_current_reports_update() CASCADE;"
  end
end
