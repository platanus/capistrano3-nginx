namespace :load do
  task :defaults do
    set :nginx_roles, -> { :web }
    set :nginx_log_path, -> { "#{shared_path}/log" }
    set :nginx_root_path, -> { "/etc/nginx" }
    set :nginx_doc_root, -> { "/var/www" }
    set :nginx_sites_enabled, -> { "sites-enabled" }
    set :nginx_sites_available, -> { "sites-available" }
    set :nginx_template, -> { "config/deploy/#{fetch(:stage)}/nginx.conf.erb" }
    set :nginx_use_ssl, -> { false }
    set :app_server, -> { true }
  end
end

namespace :nginx do
  task :load_vars do
    set :sites_available, -> { File.join(fetch(:nginx_root_path), fetch(:nginx_sites_available)) }
    set :sites_enabled, -> { File.join(fetch(:nginx_root_path), fetch(:nginx_sites_enabled)) }
    set :enabled_application, -> { File.join(fetch(:sites_enabled), fetch(:application)) }
    set :available_application, -> { File.join(fetch(:sites_available), fetch(:application)) }
  end

  %w[start stop restart reload].each do |command|
    desc "#{command.capitalize} nginx service"
    task command do
      on release_roles fetch(:nginx_roles) do
        if command === 'stop' || (test "sudo nginx -t")
          execute :sudo, "service nginx #{command}"
        end
      end
    end
  end

  after 'deploy:check', nil do
    on release_roles fetch(:nginx_roles) do
      execute :mkdir, '-pv', fetch(:nginx_log_path)
    end
  end
    
  desc 'Compress JS and CSS with gzip'
  task :gzip_static => ['nginx:load_vars'] do
    on release_roles fetch(:nginx_roles) do
      within release_path do
        execute :find, "'#{fetch(:nginx_doc_root)}' -type f -name '*.js' -o -name '*.css' -exec gzip -v -9 -f -k {} \\;"
      end
    end
  end

  namespace :site do
    desc 'Creates the site configuration and upload it to the available folder'
    task :add => ['nginx:load_vars'] do
      on release_roles fetch(:nginx_roles) do
        within fetch(:sites_available) do
          config_file = fetch(:nginx_template)
          unless File.exists?(config_file)
            config_file = File.expand_path('../../../../templates/nginx.conf.erb', __FILE__)
          end
          config = ERB.new(File.read(config_file)).result(binding)
          upload! StringIO.new(config), '/tmp/nginx.conf'

          execute :mv, '/tmp/nginx.conf', fetch(:application)
        end
      end
    end

    desc 'Enables the site creating a symbolic link into the enabled folder'
    task :enable => ['nginx:load_vars'] do
      on release_roles fetch(:nginx_roles) do
        if test "! [ -h #{fetch(:enabled_application)} ]"
          within fetch(:sites_enabled) do
            execute :ln, '-nfs', fetch(:available_application), fetch(:enabled_application)
          end
        end
      end
    end

    desc 'Disables the site removing the symbolic link located in the enabled folder'
    task :disable => ['nginx:load_vars'] do
      on release_roles fetch(:nginx_roles) do
        if test "[ -f #{fetch(:enabled_application)} ]"
          within fetch(:sites_enabled) do
            execute :rm, '-f', fetch(:application)
          end
        end
      end
    end

    desc 'Removes the site removing the configuration file from the available folder'
    task :remove => ['nginx:load_vars'] do
      on release_roles fetch(:nginx_roles) do
        if test "[ -f #{fetch(:available_application)} ]"
          within fetch(:sites_available) do
            execute :rm, fetch(:application)
          end
        end
      end
    end
  end
end
