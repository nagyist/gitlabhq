# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ImportCsvService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user, username: 'csv_author') }
  let(:file) { fixture_file_upload('spec/fixtures/work_items_valid_types.csv') }
  let(:service) do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    described_class.new(user, project, uploader)
  end

  let_it_be(:issue_type) { ::WorkItems::Type.default_issue_type }

  let(:work_items) { ::WorkItems::WorkItemsFinder.new(user, project: project).execute }
  let(:email_method) { :import_work_items_csv_email }

  subject { service.execute }

  describe '#execute', :aggregate_failures do
    context 'when user has permission' do
      before do
        project.add_reporter(user)
      end

      it_behaves_like 'importer with email notification'

      it_behaves_like 'performs a spam check', true

      context 'when file format is valid' do
        context 'when work item types are available' do
          it 'creates the expected number of work items' do
            expect { subject }.to change { work_items.count }.by 2
          end

          it 'sets work item attributes' do
            result = subject

            expect(work_items.reload).to contain_exactly(
              have_attributes(
                title: 'Valid issue',
                work_item_type_id: issue_type.id
              ),
              have_attributes(
                title: 'Valid issue with alternate case',
                work_item_type_id: issue_type.id
              )
            )

            expect(result[:success]).to eq(2)
            expect(result[:error_lines]).to eq([])
            expect(result[:type_errors]).to be_nil
            expect(result[:parse_error]).to eq(false)
          end
        end

        context 'when csv contains work item types that are not available' do
          let(:file) { fixture_file_upload('spec/fixtures/work_items_invalid_types.csv') }

          it 'creates no work items' do
            expect { subject }.not_to change { work_items.count }
          end

          it 'returns the correct result' do
            result = subject

            expect(result[:success]).to eq(0)
            expect(result[:error_lines]).to be_empty # there are problematic lines detailed below
            expect(result[:parse_error]).to eq(false)
            expect(result[:type_errors]).to match({
              blank: [],
              disallowed: { "epic" => [5] }, # tested in the EE version
              missing: {
                "isssue" => [2],
                "issue!!" => [3]
              }
            })
          end
        end

        context 'when csv contains work item types that are missing' do
          let(:file) { fixture_file_upload('spec/fixtures/work_items_no_type.csv') }

          it 'defaults the work item type to issue' do
            result = nil

            issue_wit = WorkItems::Type.find_by(name: "Issue")
            expect { result = subject }.to change { WorkItem.where(work_item_type: issue_wit).count }.by(2)

            expect(result[:success]).to eq(2)
            expect(result[:error_lines]).to be_empty
            expect(result[:parse_error]).to eq(false)
            expect(result[:type_errors]).to be_nil
          end
        end

        context 'with quick actions in the description field' do
          let(:file) { fixture_file_upload('spec/fixtures/csv_complex.csv') }
          let(:assignee) { create(:user, username: 'csv_assignee') }
          let!(:test_milestone) { create(:milestone, project: project, title: '15.10') }

          it 'sets all work item attributes and executes quick actions' do
            project.add_developer(user)
            project.add_developer(assignee)

            expect { subject }.to change { project.issues.count }.by 3

            # Assignees and time_estimate are set through the quick action in the CSV description field
            wi_attrs = [:title, :description, :time_estimate, :due_date, :milestone_id]
            expect(project.issues.pluck(*wi_attrs)).to include(
              ['Title with quote"', 'Description', 3600, Date.new(2022, 6, 28), test_milestone.id]
            )

            expect(WorkItem.find_by(title: 'Title with quote"').assignees).to contain_exactly(assignee)
          end
        end

        context 'when user is an admin' do
          before do
            allow(user).to receive(:can_admin_all_resources?).and_return(true)
          end

          it_behaves_like 'performs a spam check', false
        end
      end

      context 'when file is missing necessary headers' do
        let(:file) { fixture_file_upload('spec/fixtures/work_items_missing_header.csv') }

        it 'creates no records' do
          result = subject

          expect(result[:success]).to eq(0)
          expect(result[:error_lines]).to eq([1])
          expect(result[:type_errors]).to be_nil
          expect(result[:parse_error]).to eq(true)
        end

        it 'creates no work items' do
          expect { subject }.not_to change { work_items.count }
        end
      end

      context 'when work_items_project_issues_list feature flag is off' do
        before do
          stub_feature_flags(work_items_project_issues_list: false)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(/This feature is currently behind a feature flag and it is not available./)
        end
      end
    end

    context 'when user does not have permission' do
      before do
        project.add_guest(user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(/You do not have permission to import work items in this project/)
      end
    end
  end
end
