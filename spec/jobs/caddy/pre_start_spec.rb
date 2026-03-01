# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'caddy job — bin/pre-start.erb' do
  let(:release)  { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../../..')) }
  let(:job)      { release.job('caddy') }
  let(:template) { job.template('bin/pre-start') }

  let(:properties) { { 'caddyfile' => 'localhost' } }
  let(:rendered)    { template.render(properties) }

  it 'starts with a bash shebang' do
    expect(rendered.lines.first.chomp).to eq('#!/bin/bash')
  end

  it 'enables strict error handling with set -eu' do
    expect(rendered).to include('set -eu')
  end

  it 'runs caddy validate before startup' do
    expect(rendered).to include('caddy validate')
  end

  it 'points caddy validate at the correct binary path' do
    expect(rendered).to include('/var/vcap/packages/caddy/bin/caddy validate')
  end

  it 'passes the Caddyfile path to caddy validate' do
    expect(rendered).to include('--config /var/vcap/jobs/caddy/config/Caddyfile')
  end

  it 'specifies the caddyfile adapter' do
    expect(rendered).to include('--adapter caddyfile')
  end

  it 'exits non-zero on validation failure' do
    expect(rendered).to include('exit 1')
  end

  it 'prints a meaningful error message on failure' do
    expect(rendered).to include('ERROR: Caddyfile validation failed')
  end
end
