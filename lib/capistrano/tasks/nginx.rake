namespace :load do
  task :defaults do
    set :nginx_service_path, -> { 'service nginx' }
    set :nginx_use_sudo_for, -> { [:nginx_service_path, :nginx_sites_enabled, :nginx_sites_available] }
    set :nginx_roles, -> { :web }
    set :nginx_log_path, -> { "#{shared_path}/log" }
    set :nginx_root_path, -> { "/etc/nginx" }
    set :nginx_static_dir, -> { "public" }
    set :nginx_sites_enabled, -> { "sites-enabled" }
    set :nginx_sites_available, -> { "sites-available" }
    set :nginx_template, -> { :default }
    set :nginx_use_ssl, -> { false }
    set :nginx_ssl_certificate, -> { "#{fetch(:application)}.crt" }
    set :nginx_ssl_certificate_path, -> { '/etc/ssl/certs' }
    set :nginx_ssl_certificate_key, -> { "#{fetch(:application)}.crt" }
    set :nginx_ssl_certificate_key_path, -> { '/etc/ssl/private' }
    set :app_server, -> { true }
  end
end

namespace :nginx do

  # prepend :sudo to list if arguments if :key is in :nginx_use_sudo_for list
  def add_sudo_if_required argument_list, key
    if use_sudo? key
      argument_list.unshift(:sudo)
    end
  end

  def use_sudo? key
    return fetch(:nginx_use_sudo_for).include? key
  end

  task :load_vars do
    set :sites_available, -> { File.join(fetch(:nginx_root_path), fetch(:nginx_sites_available)) }
    set :sites_enabled, -> { File.join(fetch(:nginx_root_path), fetch(:nginx_sites_enabled)) }
    set :enabled_application, -> { File.join(fetch(:sites_enabled), fetch(:application)) }
    set :available_application, -> { File.join(fetch(:sites_available), fetch(:application)) }
  end

  %w[start stop restart reload].each do |command|
    desc "#{command.capitalize} nginx service"
    task command do
      nginx_service = fetch(:nginx_service_path)
      on release_roles fetch(:nginx_roles) do
        test_sudo = use_sudo?(:nginx_service_path) ? 'sudo ' : ''
        if command === 'stop' || (test "[ $(#{test_sudo}#{nginx_service} configtest | grep -c 'fail') -eq 0 ]")
          arguments = nginx_service, command
          add_sudo_if_required arguments, :nginx_service_path
          execute *arguments
        end
      end
    end
  end

  after 'deploy:check', nil do
    on release_roles fetch(:nginx_roles) do
      arguments = :mkdir, '-pv', fetch(:nginx_log_path)
      add_sudo_if_required arguments, :nginx_log_path
      execute *arguments
    end
  end

  desc 'Compress JS and CSS with gzip'
  task :gzip_static => ['nginx:load_vars'] do
    on release_roles fetch(:nginx_roles) do
      within release_path do
        execute :find, "'#{fetch(:nginx_static_dir)}' -type f -name '*.js' -o -name '*.css' -exec gzip -v -9 -f -k {} \\;"
      end
    end
  end

  namespace :site do
    desc 'Creates the site configuration and upload it to the available folder'
    task :add => ['nginx:load_vars'] do
      on release_roles fetch(:nginx_roles) do
        within fetch(:sites_available) do
          config_file = fetch(:nginx_template)
          if config_file == :default
              config_file = File.expand_path('../../../../templates/nginx.conf.erb', __FILE__)
          end
          config = ERB.new(File.read(config_file)).result(binding)
          upload! StringIO.new(config), '/tmp/nginx.conf'
          arguments = :mv, '/tmp/nginx.conf', fetch(:application)
          add_sudo_if_required arguments, :nginx_sites_available
          execute *arguments
        end
      end
    end

    desc 'Enables the site creating a symbolic link into the enabled folder'
    task :enable => ['nginx:load_vars'] do
      on release_roles fetch(:nginx_roles) do
        if test "! [ -h #{fetch(:enabled_application)} ]"
          within fetch(:sites_enabled) do
            arguments = :ln, '-nfs', fetch(:available_application), fetch(:enabled_application)
            add_sudo_if_required arguments, :nginx_sites_enabled
            execute *arguments
          end
        end
      end
    end

    desc 'Disables the site removing the symbolic link located in the enabled folder'
    task :disable => ['nginx:load_vars'] do
      on release_roles fetch(:nginx_roles) do
        if test "[ -f #{fetch(:enabled_application)} ]"
          within fetch(:sites_enabled) do
            arguments = :rm, '-f', fetch(:application)
            add_sudo_if_required arguments, :nginx_sites_enabled
            execute *arguments
          end
        end
      end
    end

    desc 'Removes the site removing the configuration file from the available folder'
    task :remove => ['nginx:load_vars'] do
      on release_roles fetch(:nginx_roles) do
        if test "[ -f #{fetch(:available_application)} ]"
          within fetch(:sites_available) do
            arguments = :rm, fetch(:application)
            add_sudo_if_required arguments, :nginx_sites_enabled
            execute *arguments
          end
        end
      end
    end
  end
end
