# frozen_string_literal: true

class AddIncidentManagementTimelineEventTagLinksProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :incident_management_timeline_event_tag_links, :projects, column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :incident_management_timeline_event_tag_links, column: :project_id
    end
  end
end
