require 'spec_helper'

describe 'heat::db' do

  shared_examples 'heat::db' do

    context 'with default parameters' do

      it { is_expected.to contain_class('heat::db::sync') }
      it { is_expected.to contain_heat_config('database/connection').with_value('sqlite:////var/lib/heat/heat.sqlite').with_secret(true) }
      it { is_expected.to contain_heat_config('database/idle_timeout').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_heat_config('database/min_pool_size').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_heat_config('database/max_pool_size').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_heat_config('database/max_retries').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_heat_config('database/retry_interval').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_heat_config('database/db_max_retries').with_value('<SERVICE DEFAULT>') }

    end

    context 'with specific parameters' do
      let :params do
        { :database_connection     => 'mysql+pymysql://heat:heat@localhost/heat',
          :database_idle_timeout   => '3601',
          :database_min_pool_size  => '2',
          :database_max_pool_size  => '12',
          :database_max_retries    => '11',
          :database_retry_interval => '11',
          :database_db_max_retries => '-1',
          :sync_db                 => false }
      end

      it { is_expected.not_to contain_class('heat::db::sync') }
      it { is_expected.to contain_heat_config('database/connection').with_value('mysql+pymysql://heat:heat@localhost/heat').with_secret(true) }
      it { is_expected.to contain_heat_config('database/idle_timeout').with_value('3601') }
      it { is_expected.to contain_heat_config('database/min_pool_size').with_value('2') }
      it { is_expected.to contain_heat_config('database/max_pool_size').with_value('12') }
      it { is_expected.to contain_heat_config('database/max_retries').with_value('11') }
      it { is_expected.to contain_heat_config('database/retry_interval').with_value('11') }
      it { is_expected.to contain_heat_config('database/db_max_retries').with_value('-1') }

    end

    context 'with MySQL-python library as backend package' do
      let :params do
        { :database_connection => 'mysql://heat:heat@localhost/heat' }
      end

      it { is_expected.to contain_heat_config('database/connection').with_value('mysql://heat:heat@localhost/heat').with_secret(true) }
    end

    context 'with postgresql backend' do
      let :params do
        { :database_connection     => 'postgresql://heat:heat@localhost/heat', }
      end

      it 'install the proper backend package' do
        is_expected.to contain_package('python-psycopg2').with(:ensure => 'present')
      end

    end

    context 'with incorrect database_connection string' do
      let :params do
        { :database_connection     => 'redis://heat:heat@localhost/heat', }
      end

      it_raises 'a Puppet::Error', /validate_re/
    end

    context 'with incorrect database_connection string' do
      let :params do
        { :database_connection     => 'foo+pymysql://heat:heat@localhost/heat', }
      end

      it_raises 'a Puppet::Error', /validate_re/
    end

  end

  on_supported_os({
    :supported_os   => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'heat::db'

      context 'using pymysql driver' do
        let :params do
          { :database_connection     => 'mysql+pymysql://heat:heat@localhost/heat' }
        end

        case facts[:osfamily]
        when 'Debian'
          it { is_expected.to contain_package('db_backend_package').with({ :ensure => 'present', :name => 'python-pymysql' }) }
        when 'RedHat'
          it { is_expected.not_to contain_package('db_backend_package') }
        end
      end

    end
  end

end
