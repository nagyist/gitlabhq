# frozen_string_literal: true

module Ci
  module JobTokenScope
    class AddProjectService < ::BaseService
      include EditScopeValidations

      def execute(target_project, policies: [], direction: :inbound)
        validate_source_project_and_target_project_access!(project, target_project, current_user)

        link = allowlist(direction)
          .add!(target_project, policies: policies, user: current_user)

        ServiceResponse.success(payload: { project_link: link })

      rescue ActiveRecord::RecordNotUnique
        ServiceResponse.error(message: "Target project is already in the job token scope")
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message)
      rescue EditScopeValidations::ValidationError => e
        ServiceResponse.error(message: e.message)
      end

      private

      def allowlist(direction)
        Ci::JobToken::Allowlist.new(project, direction: direction)
      end
    end
  end
end

Ci::JobTokenScope::AddProjectService.prepend_mod_with('Ci::JobTokenScope::AddProjectService')
