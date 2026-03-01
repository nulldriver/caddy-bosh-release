# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'caddy job — config/Caddyfile.erb' do
  let(:release)  { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../../..')) }
  let(:job)      { release.job('caddy') }
  let(:template) { job.template('config/Caddyfile') }

  context 'with a simple single-site Caddyfile' do
    let(:caddyfile_content) do
      <<~CADDYFILE
        localhost {
          respond "Hello!"
        }
      CADDYFILE
    end
    let(:properties) { { 'caddyfile' => caddyfile_content } }

    it 'renders the caddyfile property verbatim' do
      expect(template.render(properties)).to eq(caddyfile_content)
    end
  end

  context 'with a multi-site Caddyfile using TLS and GCP DNS' do
    let(:caddyfile_content) do
      <<~CADDYFILE
        {
          email admin@example.com
        }

        example.com {
          tls {
            dns googleclouddns {
              gcp_project {env.GCP_PROJECT}
            }
          }
          respond "Hello from Caddy BOSH Release!"
        }
      CADDYFILE
    end
    let(:properties) { { 'caddyfile' => caddyfile_content } }

    it 'passes through the multi-line Caddyfile exactly' do
      expect(template.render(properties)).to eq(caddyfile_content)
    end
  end

  context 'when caddyfile property contains curly brace syntax (Caddyfile blocks)' do
    let(:caddyfile_content) { "{env.GCP_PROJECT}" }
    let(:properties) { { 'caddyfile' => caddyfile_content } }

    it 'passes through curly brace content unchanged' do
      expect(template.render(properties)).to eq(caddyfile_content)
    end
  end

  context 'when caddyfile property is not provided' do
    it 'raises an error because the property is required' do
      expect {
        template.render({})
      }.to raise_error(Bosh::Template::UnknownProperty, /caddyfile/)
    end
  end
end
