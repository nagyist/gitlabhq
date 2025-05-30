# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Entry::Include, feature_category: :pipeline_composition do
  subject(:include_entry) { described_class.new(config) }

  describe 'validations' do
    before do
      include_entry.compose!
    end

    context 'when value is a string' do
      let(:config) { 'test.yml' }

      it { is_expected.to be_valid }
    end

    context 'when value is hash' do
      context 'when using not allowed keys' do
        let(:config) do
          { not_allowed: 'key' }
        end

        it { is_expected.not_to be_valid }
      end

      context 'when using "local"' do
        let(:config) { { local: 'test.yml' } }

        it { is_expected.to be_valid }
      end

      context 'when using "file"' do
        let(:config) { { file: 'test.yml' } }

        it { is_expected.to be_valid }
      end

      context 'when using "template"' do
        let(:config) { { template: 'test.yml' } }

        it { is_expected.to be_valid }
      end

      context 'when using "component"' do
        let(:config) { { component: 'path/to/component@1.0' } }

        it { is_expected.to be_valid }
      end

      context 'when using "artifact"' do
        context 'and specifying "job"' do
          let(:config) { { artifact: 'test.yml', job: 'generator' } }

          it { is_expected.to be_valid }
        end

        context 'without "job"' do
          let(:config) { { artifact: 'test.yml' } }

          it { is_expected.not_to be_valid }

          it 'has specific error' do
            expect(include_entry.errors)
              .to include('include config must specify the job where to fetch the artifact from')
          end
        end
      end

      context 'when using "project"' do
        context 'and specifying "ref" and "file"' do
          let(:config) { { project: 'my-group/my-pipeline-library', ref: 'master', file: 'test.yml' } }

          it { is_expected.to be_valid }
        end

        context 'without "ref"' do
          let(:config) { { project: 'my-group/my-pipeline-library', file: 'test.yml' } }

          it { is_expected.to be_valid }
        end

        context 'without "file"' do
          let(:config) { { project: 'my-group/my-pipeline-library' } }

          it { is_expected.not_to be_valid }

          it 'has specific error' do
            expect(include_entry.errors)
              .to include('include config must specify the file where to fetch the config from')
          end
        end
      end

      context 'when using with "rules"' do
        let(:config) { { local: 'test.yml', rules: [{ if: '$VARIABLE' }] } }

        it { is_expected.to be_valid }

        context 'when also using "inputs"' do
          let(:config) { { local: 'test.yml', inputs: { stage: 'test' }, rules: [{ if: '$VARIABLE' }] } }

          it { is_expected.to be_valid }
        end

        context 'when rules is not an array of hashes' do
          let(:config) { { local: 'test.yml', rules: ['$VARIABLE'] } }

          it { is_expected.not_to be_valid }

          it 'has specific error' do
            expect(include_entry.errors).to include('include rules should be an array of hashes')
          end
        end
      end

      context 'when using "remote" with integrity' do
        let(:config) do
          {
            remote: 'https://example.com/file.yml',
            integrity: 'sha256-abc123def456'
          }
        end

        it { is_expected.to be_valid }

        context 'when integrity has invalid format' do
          ['invalid-hash', 123].each do |invalid_integrity|
            context "when integrity is #{invalid_integrity}" do
              let(:config) do
                {
                  remote: 'https://example.com/file.yml',
                  integrity: invalid_integrity
                }
              end

              it { is_expected.not_to be_valid }

              it 'has specific error' do
                expect(include_entry.errors)
                  .to include('include config integrity hash must start with \'sha256-\'')
              end
            end
          end
        end

        context 'when integrity is not base64 encoded' do
          let(:config) do
            {
              remote: 'https://example.com/file.yml',
              integrity: 'sha256-not!valid@base64'
            }
          end

          it { is_expected.not_to be_valid }

          it 'has specific error' do
            expect(include_entry.errors)
              .to include('include config integrity hash must be base64 encoded')
          end
        end

        context 'when integrity is used without remote' do
          let(:config) do
            {
              local: 'test.yml',
              integrity: 'sha256-abc123def456'
            }
          end

          it { is_expected.not_to be_valid }

          it 'has specific error' do
            expect(include_entry.errors)
              .to include('include config integrity can only be specified for remote includes')
          end
        end
      end
    end

    context 'when value is something else' do
      let(:config) { 123 }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#value' do
    subject(:value) { include_entry.value }

    context 'when config is a string' do
      let(:config) { 'test.yml' }

      it { is_expected.to eq('test.yml') }
    end

    context 'when config is a hash' do
      let(:config) { { local: 'test.yml' } }

      it { is_expected.to eq(local: 'test.yml') }
    end

    context 'when config has "rules"' do
      let(:config) { { local: 'test.yml', rules: [{ if: '$VARIABLE' }] } }

      it { is_expected.to eq(local: 'test.yml', rules: [{ if: '$VARIABLE' }]) }
    end
  end
end
