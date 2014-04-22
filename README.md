# Capistrano::Nginx [![Gem Version](https://badge.fury.io/rb/capistrano3-nginx.png)](http://badge.fury.io/rb/capistrano3-nginx)

This is a fork of [platanus/capistrano3-nginx](https://github.com/platanus/capistrano3-nginx). I am not entirely sure
how actively that one is maintained.

Differences
-----------
- `nginx:gzip_static` to gzip compress all `*.js` and `*.css` files below `:nginx_doc_root` recursively
- Removed the potentially dangerous fallback to a default nginx site-configuration template, when the 
  configured one isn't found

Nginx support for Capistrano 3.x

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano3-nginx', '~> 1.0', :github => 'KingCrunch/capistrano3-nginx'
    gem 'capistrano'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano3-nginx

## Usage

Require in `Capfile` to use the default task:

```ruby
require 'capistrano/nginx'
```

You will get the following tasks

```ruby
cap nginx:start                    # Start nginx service
cap nginx:stop                     # Stop nginx service
cap nginx:reload                   # Reload nginx service
cap nginx:restart                  # Restart nginx service
cap nginx:gzip_static              # Compress JS and CSS assets
cap nginx:site:add                 # Creates the site configuration and upload it to the available folder
cap nginx:site:disable             # Disables the site removing the symbolic link located in the enabled folder
cap nginx:site:enable              # Enables the site creating a symbolic link into the enabled folder
cap nginx:site:remove              # Removes the site removing the configuration file from the available folder
```

Configurable options, shown here with examples:

```ruby
# Server name for nginx
# No default vaue
set :nginx_domains, "foo.bar.com"

# Roles the deploy nginx site on,
# default value: :web
set :nginx_roles, :web

# Path, where nginx log file will be stored
# default value:  "#{shared_path}/log"
set :nginx_log_path, "#{shared_path}/log"

# Path where nginx is installed
# default value: "/etc/nginx"
set :nginx_root_path, "/etc/nginx"

# The webservers/applications document root
set :nginx_doc_root, "/var/www"

# Path where nginx available site are stored
# default value: "sites-available"
set :nginx_sites_available, "sites-available"

# Path where nginx available site are stored
# default value: "sites-enabled"
set :nginx_sites_enabled, "sites-enabled"

# Path to look for custom config template
# default value: "config/deploy/#{stage}/nginx.conf.erb"
set :nginx_template, "config/deploy/#{stage}/nginx.conf.erb"

# Use ssl on port 443 to serve on https. Every request to por 80
# will be rewritten to 443
# default value: false
set :nginx_use_ssl, false

# Whether you want to server an application through a proxy pass
# default value: true
set :app_server, true

# Socket file that nginx will use as upstream to serve the application
# Note: Socket upstream has priority over host:port upstreams
# no default value
set :app_server_socket, "#{shared_path}/sockets/#{application}.sock"

# The host that nginx will use as upstream to server the application
# default value: 127.0.0.1
set :app_server_port,

# The port the application server is running on
# no default value
set :app_server_host,
```

## Thanks
Thansk for the inspiration on several nginx recipes out there

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
