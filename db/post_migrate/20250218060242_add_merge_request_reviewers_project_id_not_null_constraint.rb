# frozen_string_literal: true

class AddMergeRequestReviewersProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :merge_request_reviewers, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :merge_request_reviewers, :project_id
  end
end
