# frozen_string_literal: true

class FinalizeBackfillPackagesConanFileMetadataProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesConanFileMetadataProjectId',
      table_name: :packages_conan_file_metadata,
      column_name: :id,
      job_arguments: [:project_id, :packages_package_files, :project_id, :package_file_id],
      finalize: true
    )
  end

  def down; end
end
