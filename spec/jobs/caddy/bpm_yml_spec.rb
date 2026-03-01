# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe 'caddy job — config/bpm.yml.erb' do
  let(:release)  { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../../..')) }
  let(:job)      { release.job('caddy') }
  let(:template) { job.template('config/bpm.yml') }

  let(:rendered) { YAML.safe_load(template.render(properties)) }
  let(:process)  { rendered['processes'].first }

  context 'with minimal properties (no env)' do
    let(:properties) { { 'caddyfile' => 'localhost' } }

    it 'renders valid YAML' do
      expect { YAML.safe_load(template.render(properties)) }.not_to raise_error
    end

    it 'names the process caddy' do
      expect(process['name']).to eq('caddy')
    end

    it 'points the executable at the packaged caddy binary' do
      expect(process['executable']).to eq('/var/vcap/packages/caddy/bin/caddy')
    end

    it 'passes the correct arguments to caddy' do
      expect(process['args']).to eq([
        'run',
        '--config', '/var/vcap/jobs/caddy/config/Caddyfile',
        '--adapter', 'caddyfile'
      ])
    end

    it 'sets XDG_DATA_HOME so caddy stores certs on persistent disk' do
      expect(process['env']['XDG_DATA_HOME']).to eq('/var/vcap/store')
    end

    it 'does not add extra environment variables when env property is absent' do
      expect(process['env'].keys).to contain_exactly('XDG_DATA_HOME')
    end

    it 'sets the workdir to the caddy job directory' do
      expect(process['workdir']).to eq('/var/vcap/jobs/caddy')
    end

    it 'enables ephemeral disk' do
      expect(process['ephemeral_disk']).to be true
    end

    it 'enables persistent disk for certificate storage' do
      expect(process['persistent_disk']).to be true
    end

    it 'grants NET_BIND_SERVICE capability so caddy can bind ports 80 and 443' do
      expect(process['capabilities']).to include('NET_BIND_SERVICE')
    end

    it 'uses the pre-start hook for config validation' do
      expect(process.dig('hooks', 'pre_start')).to eq('/var/vcap/jobs/caddy/bin/pre-start')
    end

    it 'shuts down gracefully via TERM signal' do
      expect(process['shutdown_signal']).to eq('TERM')
    end

    describe 'resource limits' do
      it 'sets memory limit to 2G' do
        expect(process.dig('limits', 'memory')).to eq('2G')
      end

      it 'sets open_files limit to 8192' do
        expect(process.dig('limits', 'open_files')).to eq(8192)
      end

      it 'sets processes limit to 100' do
        expect(process.dig('limits', 'processes')).to eq(100)
      end
    end
  end

  context 'with additional env vars (no GOOGLE_APPLICATION_CREDENTIALS)' do
    let(:properties) do
      {
        'caddyfile' => 'localhost',
        'env' => {
          'GCP_PROJECT' => 'my-project-123',
          'MY_CUSTOM_VAR' => 'some-value'
        }
      }
    end

    it 'passes extra env vars through verbatim' do
      expect(process['env']['GCP_PROJECT']).to eq('my-project-123')
      expect(process['env']['MY_CUSTOM_VAR']).to eq('some-value')
    end

    it 'still includes XDG_DATA_HOME' do
      expect(process['env']['XDG_DATA_HOME']).to eq('/var/vcap/store')
    end
  end

  context 'with GOOGLE_APPLICATION_CREDENTIALS in env' do
    let(:gcp_sa_json) { '{"type":"service_account","project_id":"my-project"}' }
    let(:properties) do
      {
        'caddyfile' => 'localhost',
        'env' => {
          'GOOGLE_APPLICATION_CREDENTIALS' => gcp_sa_json,
          'GCP_PROJECT' => 'my-project-123'
        }
      }
    end

    it 'replaces GOOGLE_APPLICATION_CREDENTIALS value with the credentials file path' do
      expect(process['env']['GOOGLE_APPLICATION_CREDENTIALS']).to eq(
        '/var/vcap/jobs/caddy/config/gcp_credentials.json'
      )
    end

    it 'does not leak the raw credentials JSON into bpm.yml' do
      expect(process['env']['GOOGLE_APPLICATION_CREDENTIALS']).not_to include('service_account')
    end

    it 'still passes other env vars through verbatim' do
      expect(process['env']['GCP_PROJECT']).to eq('my-project-123')
    end

    it 'still includes XDG_DATA_HOME' do
      expect(process['env']['XDG_DATA_HOME']).to eq('/var/vcap/store')
    end
  end

  context 'with GOOGLE_APPLICATION_CREDENTIALS as the only env var' do
    let(:properties) do
      {
        'caddyfile' => 'localhost',
        'env' => { 'GOOGLE_APPLICATION_CREDENTIALS' => '{"type":"service_account"}' }
      }
    end

    it 'sets the credentials file path and preserves XDG_DATA_HOME only' do
      expect(process['env'].keys).to contain_exactly(
        'XDG_DATA_HOME',
        'GOOGLE_APPLICATION_CREDENTIALS'
      )
    end
  end
end
