# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ManifestController, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include ImportSpecHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, maintainers: user) }

  before do
    stub_application_setting(import_sources: ['manifest'])

    sign_in(user)
  end

  describe 'POST upload' do
    context 'with a valid manifest' do
      context 'when format is HTML' do
        it 'saves the manifest and redirects to the status page', :aggregate_failures do
          post :upload, params: {
            group_id: group.id,
            manifest: fixture_file_upload('spec/fixtures/aosp_manifest.xml')
          }

          metadata = Gitlab::ManifestImport::Metadata.new(user)

          expect(metadata.group_id).to eq(group.id)
          expect(metadata.repositories.size).to eq(660)
          expect(metadata.repositories.first).to include(name: 'platform/build', path: 'build/make')

          expect(response).to redirect_to(status_import_manifest_path)
        end
      end

      context 'when format is JSON' do
        it 'saves the manifest and responds with 200', :aggregate_failures do
          post :upload, format: :json, params: {
            group_id: group.id,
            manifest: fixture_file_upload('spec/fixtures/aosp_manifest.xml')
          }

          metadata = Gitlab::ManifestImport::Metadata.new(user)

          expect(metadata.group_id).to eq(group.id)
          expect(metadata.repositories.size).to eq(660)
          expect(metadata.repositories.first).to include(name: 'platform/build', path: 'build/make')

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq({ 'success' => true })
        end
      end
    end

    context 'with an invalid manifest' do
      context 'when format is HTML' do
        it 'displays an error' do
          post :upload, params: {
            group_id: group.id,
            manifest: fixture_file_upload('spec/fixtures/invalid_manifest.xml')
          }

          expect(assigns(:errors)).to be_present
        end
      end

      context 'when format is JSON' do
        it 'displays an error' do
          post :upload, format: :json, params: {
            group_id: group.id,
            manifest: fixture_file_upload('spec/fixtures/invalid_manifest.xml')
          }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(Gitlab::Json.parse(response.body)['errors']).to be_present
        end
      end
    end

    context 'with an oversized manifest' do
      before do
        stub_const("#{described_class}::MAX_MANIFEST_SIZE_IN_MB", 0)
      end

      context 'when format is HTML' do
        it 'displays an error' do
          post :upload, params: {
            group_id: group.id,
            manifest: fixture_file_upload('spec/fixtures/aosp_manifest.xml')
          }

          expect(assigns(:errors)).to include(
            format(
              s_("ManifestImport|Import manifest files cannot exceed %{size} MB"),
              size: described_class::MAX_MANIFEST_SIZE_IN_MB
            )
          )
        end
      end

      context 'when format is JSON' do
        it 'displays an error' do
          post :upload, format: :json, params: {
            group_id: group.id,
            manifest: fixture_file_upload('spec/fixtures/aosp_manifest.xml')
          }

          expect(Gitlab::Json.parse(response.body)['errors']).to include(
            format(
              s_("ManifestImport|Import manifest files cannot exceed %{size} MB"),
              size: described_class::MAX_MANIFEST_SIZE_IN_MB
            )
          )
        end
      end
    end

    context 'when the user cannot import projects in the group' do
      context 'when format is HTML' do
        it 'displays an error' do
          sign_in(create(:user))

          post :upload, params: {
            group_id: group.id,
            manifest: fixture_file_upload('spec/fixtures/aosp_manifest.xml')
          }

          expect(assigns(:errors)).to include(
            s_("ManifestImport|You don't have enough permissions to import projects in the selected group")
          )
        end
      end

      context 'when format is JSON' do
        it 'displays an error' do
          sign_in(create(:user))

          post :upload, format: :json, params: {
            group_id: group.id,
            manifest: fixture_file_upload('spec/fixtures/aosp_manifest.xml')
          }

          expect(Gitlab::Json.parse(response.body)['errors']).to include(
            s_("ManifestImport|You don't have enough permissions to import projects in the selected group")
          )
        end
      end
    end
  end

  describe 'GET status' do
    let(:repo1) { { id: 'test1', url: 'http://demo.host/test1' } }
    let(:repo2) { { id: 'test2', url: 'http://demo.host/test2' } }
    let(:repos) { [repo1, repo2] }

    shared_examples 'status action' do
      it "returns variables for json request" do
        project = create(:project, import_type: 'manifest', creator_id: user.id)

        get :status, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.dig("imported_projects", 0, "id")).to eq(project.id)
        expect(json_response.dig("provider_repos", 0, "id")).to eq(repo1[:id])
        expect(json_response.dig("provider_repos", 1, "id")).to eq(repo2[:id])
      end
    end

    context 'when the data is stored via Gitlab::ManifestImport::Metadata' do
      before do
        Gitlab::ManifestImport::Metadata.new(user).save(repos, group.id)
      end

      include_examples 'status action'
    end

    context 'when the data is stored in the user session' do
      before do
        session[:manifest_import_repositories] = repos
        session[:manifest_import_group_id] = group.id
      end

      include_examples 'status action'
    end
  end
end
