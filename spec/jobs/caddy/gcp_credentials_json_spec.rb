# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'caddy job — config/gcp_credentials.json.erb' do
  let(:release)  { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../../..')) }
  let(:job)      { release.job('caddy') }
  let(:template) { job.template('config/gcp_credentials.json') }

  let(:valid_sa_json) do
    <<~JSON
      {
        "type": "service_account",
        "project_id": "my-gcp-project",
        "private_key_id": "key-123",
        "client_email": "caddy@my-gcp-project.iam.gserviceaccount.com"
      }
    JSON
  end

  context 'when env.GOOGLE_APPLICATION_CREDENTIALS is set' do
    let(:properties) do
      {
        'caddyfile' => 'localhost',
        'env' => { 'GOOGLE_APPLICATION_CREDENTIALS' => valid_sa_json }
      }
    end

    it 'renders the credentials JSON to the file' do
      result = template.render(properties)
      expect(result.strip).to eq(valid_sa_json.strip)
    end

    it 'includes the service_account type field' do
      result = template.render(properties)
      expect(result).to include('service_account')
    end

    it 'includes the project_id' do
      result = template.render(properties)
      expect(result).to include('my-gcp-project')
    end
  end

  context 'when env.GOOGLE_APPLICATION_CREDENTIALS is not set' do
    let(:properties) { { 'caddyfile' => 'localhost' } }

    it 'renders an empty file (no credentials block is written)' do
      result = template.render(properties)
      expect(result.strip).to be_empty
    end
  end

  context 'when env is set but GOOGLE_APPLICATION_CREDENTIALS is absent' do
    let(:properties) do
      {
        'caddyfile' => 'localhost',
        'env' => { 'GCP_PROJECT' => 'my-project' }
      }
    end

    it 'renders an empty file' do
      result = template.render(properties)
      expect(result.strip).to be_empty
    end
  end

  context 'when env.GOOGLE_APPLICATION_CREDENTIALS is nil' do
    let(:properties) do
      {
        'caddyfile' => 'localhost',
        'env' => { 'GOOGLE_APPLICATION_CREDENTIALS' => nil }
      }
    end

    # if_p does not yield when the value is nil, so the file is empty.
    # In practice, operators should not set this property to nil; they
    # should either omit it or provide a valid JSON string.
    it 'renders an empty file when the value is nil' do
      result = template.render(properties)
      expect(result.strip).to be_empty
    end
  end
end
