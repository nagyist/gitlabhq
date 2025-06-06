# frozen_string_literal: true

class AddProtectedBranchPushAccessLevelsProtectedBranchProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    install_sharding_key_assignment_trigger(
      table: :protected_branch_push_access_levels,
      sharding_key: :protected_branch_project_id,
      parent_table: :protected_branches,
      parent_sharding_key: :project_id,
      foreign_key: :protected_branch_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :protected_branch_push_access_levels,
      sharding_key: :protected_branch_project_id,
      parent_table: :protected_branches,
      parent_sharding_key: :project_id,
      foreign_key: :protected_branch_id
    )
  end
end
