# frozen_string_literal: true

class FinalizeBackfillTerraformModulesMetadataWithSemver < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.3'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillTerraformModulesMetadataWithSemver',
      table_name: :packages_packages,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
