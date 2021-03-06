require 'spec_helper'

require 'cli'

describe Bosh::Cli::Command::Vms do
  let(:command) { described_class.new }
  let(:director) { double(Bosh::Cli::Director) }
  let(:deployment) { 'dep1' }
  let(:target) { 'http://example.org' }

  before(:each) do
    command.stub(:director).and_return(director)
    command.stub(:nl)
    command.stub(:logged_in? => true)
    command.options[:target] = target
  end

  describe '#list' do

    context 'with no arguments' do

      it 'lists vms in all deployments' do
        director.stub(:list_deployments) {
          [
              {'name' => 'dep1'},
              {'name' => 'dep2'},
          ]
        }

        command.should_receive(:show_deployment).with('dep1', target: target)
        command.should_receive(:show_deployment).with('dep2', target: target)

        command.list
      end
    end

    context 'with a deployment argument' do

      it 'lists vms in the deployment' do
        command.should_receive(:show_deployment).with('dep1', target: target)

        command.list('dep1')
      end

    end
  end

  describe '#show_deployment' do
    let(:vitals) { false }
    let(:details) { false }

    before(:each) do
      director.stub(:fetch_vm_state).with(deployment) {
        [
            {
                'job_name' => 'job1',
                'index' => 0,
                'ips' => %w{192.168.0.1},
                'vitals' => 'vitals',
                'job_state' => 'awesome',
                'resource_pool' => 'rp1',
                'vm_cid' => 'cid1',
                'agent_id' => 'agent1',
                'vitals' => {
                    'load' => [1, 2, 3],
                    'cpu' => {
                        'user' => 4,
                        'sys' => 5,
                        'wait' => 6,
                    },
                    'mem' => {
                        'percent' => 7,
                        'kb' => 8,
                    },
                    'swap' => {
                        'percent' => 9,
                        'kb' => 10,
                    },
                    'disk' => {
                        'system' => {'percent' => 11},
                        'ephemeral' => {'percent' => 12},
                        'persistent' => {'percent' => 13},
                    },
                }
            },
        ]
      }
    end

    context 'default' do

      it 'show basic vms information' do
        command.should_receive(:say).with("Deployment `#{deployment}'")
        command.should_receive(:say) do |s|
          expect(s.to_s).to include 'job1/0'
          expect(s.to_s).to include 'awesome'
          expect(s.to_s).to include 'rp1'
          expect(s.to_s).to include '192.168.0.1'
        end
        command.should_receive(:say).with('VMs total: 1')

        command.show_deployment deployment, details: details, vitals: vitals
      end

    end

    context 'with details' do
      let(:details) { true }

      it 'shows vm details' do
        command.should_receive(:say).with("Deployment `#{deployment}'")
        command.should_receive(:say) do |s|
          expect(s.to_s).to include 'job1/0'
          expect(s.to_s).to include 'awesome'
          expect(s.to_s).to include 'rp1'
          expect(s.to_s).to include '192.168.0.1'
          expect(s.to_s).to include 'cid1'
          expect(s.to_s).to include 'agent1'
        end
        command.should_receive(:say).with('VMs total: 1')

        command.show_deployment deployment, details: details, vitals: vitals
      end

    end

    context 'with vitals' do
      let(:vitals) { true }

      it 'shows the vm vitals' do
        command.should_receive(:say).with("Deployment `#{deployment}'")
        command.should_receive(:say) do |s|
          expect(s.to_s).to include 'job1/0'
          expect(s.to_s).to include 'awesome'
          expect(s.to_s).to include 'rp1'
          expect(s.to_s).to include '192.168.0.1'
          expect(s.to_s).to include '1%, 2%, 3%'
          expect(s.to_s).to include '4%'
          expect(s.to_s).to include '5%'
          expect(s.to_s).to include '6%'
          expect(s.to_s).to include '7% (8.0K)'
          expect(s.to_s).to include '9% (10.0K)'
          expect(s.to_s).to include '11%'
          expect(s.to_s).to include '12%'
          expect(s.to_s).to include '13%'
        end
        command.should_receive(:say).with('VMs total: 1')

        command.show_deployment deployment, details: details, vitals: vitals
      end

    end

  end

end
