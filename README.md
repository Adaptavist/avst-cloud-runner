# avst-cloud-runner

Automated creation, bootstrapping and provisioning of servers. Currently supports AWS, Azure, Rackspace

## Prerequisites
Make sure rvm and ruby 2.0 is installed.
The application depends on several gems listed in avst-cloud-runner.gemspec file. Bundle install command will install all dependencies. 

## Installation from source

- Download source
- Navigate to folder
- Run bundle install 
- Run sudo rake install

## Configuration

The hiera.yaml file configures the location of configuration files. The location of custom hiera.yaml file can be specified using the -c or --config options. 

By default hiera.yaml loads data from config/hiera in order:
  - custom_config
  - "%{::customer_short_code}/%{::env}/%{::server_name}"
  - "%{::customer_short_code}/%{::env}"
  - "%{::customer_short_code}"
  - global

See [hiera documentation](http://docs.puppetlabs.com/hiera/1/) for details on how hiera loads the configuration.

By default (see global.eyaml configuration), avst-cloud-runner is setup to create centos-7, t2.medium server on eu-west aws with 12G of HDD. While running 'all' option it starts the server. Bootstraps it with rvm, ruby, gems (hiera, puppet, facter, puppet-runner) and provide required ssh keys. Provisioning stage of avst-cloud-runner loads on the newly created server content of git repo defined by 'git' and 'branch' parameter. By default [base_puppet_templates](https://github.com/Adaptavist/base_puppet_templates). After git pull [puppet-runner](https://github.com/Adaptavist/puppet-runner) is called based on the command defined by 'puppet_runner_prepare' parameter. The parameter 'download_dependencies_command' defines how to download resources for 'puppet_runner' call, it defaults to installation or r10k and execution of 'r10k puppetfile install', and start of puppet via command 'puppet_runner' (see defaults in global.eyaml).

NOTE: In case you want to start aws server, make sure you provide aws specific setup to be able to connect to server. See global.eyaml for details.

## Global Configuration

Configuration can be done via global yaml config file. Place config to HOME/.avst-cloud.yaml. Options will be loaded if no command line option is provided or setup in hiera config.

Supported options are

* avst_cloud_config_service, avst_cloud_config_service_username, avst_cloud_config_service_password
* server_config_url_username, server_config_url_password - if --server_config_url option is used
* confluence_url, confluence_user, confluence_access_password, confluence_space, confluence_parent_page_id - to setup confluence_reporter
* provider_username, provider_password, region - provider credentials and region
* config_dir

## Minimal Configuration

To be able to start Jira 6.4.11 on Ubuntu 14 on AWS (check other details in global.eyaml), you have to provide:

### global.eyaml setup

* provider credentials, provider_username, provider_password (preferably ENC)
* server domain - like 'mycompany.com'
* server connection key, aws_key_name ('admin'), aws_ssh_key (/path/to/admin.pem)
* aws_subnet_id, aws_security_group_ids - check youw aws account
* set no_report to true or provide confluence credentials and details for reporting
* provide ami_image_id and hdd_device_path or configuration service via avst_cloud_config_service or configuration via local file with avst_cloud_config_file

### Required files

For list of files check config/bootstrap/"cloud_operating_system".yaml.erb section custom_file_uploads for local files that will be uploaded. Additionaly pem key to access aws server defined by aws_ssh_key in global.yaml


## Customisation

### Avst-cloud-runner params customisation

In case you want to overwrite default parameters for avst-cloud-runner config, create file customer_short_code/env/server_name.yaml and place overwrites there or on the higher lever in folder hierarchy(see hiera.yaml) in case you want to reuse them. 

You can check the final config by running avst-cloud-runner server_name test-config. 

Store your custom config in appropriate git repo per client to keep track of the setup.

List of available avst-cloud-runner parameters and their description is listed below. 

### Provisioning customisation

For provisioning you have to provide id_rsa and known_hosts file in files folder that will be uploaded to created server as part of bootstrap to allow access to git account as part of capistrano provisioning. Check bootstrap folder and required operating system for list of required files and their locations.

There are two ways of defining provisioning configuration for puppet. 

- Preferably - Fork base_puppet_templates into separate repo per client, create the configuration for puppet-runner as desired in hiera-configs folder for your server and change 'git' and 'branch' parameters of avst-cloud. base_puppet_templates contains example setups in hiera-configs, for more info check puppet-runner documentation.

- For dev and testing purposes - You can provide your puppet-runner server configuration, templates, defaults and puppetfile-dictionary as described in Override Puppet config section below. See puppet-runner page for details.

## Avst-cloud-runner config description

### Parameters and default values

#### domain

The FQDN set during bootstrapping will be '#{server_name}.#{domain}' so do not include a dot at the beginning.

#### cloud_operating_system

- "centos-7" #&lt;default&gt;

For AWS, available options are: 'centos-7', 'centos-6' 'ubuntu-14', 'ubuntu-12', 'debian-6' (these specify an AMI to base the machine off - to use a specific AMI use the ami_image_id parameter in hiera)

#### provider

- "aws" &lt;default&gt;

Details of fog support for AWS can be found here: https://github.com/fog/fog/blob/master/lib/fog/aws/models/compute/server.rb

#### provider_username provider_password

Credentials to access provider cloud.

#### env

server_number, customer_short_code, env are parsed from server_name parameter passed

Env can be overwritten by setting it inside hiera. It will not change the name only behavior

#### mould

On **AWS**:

- "m3.medium" &lt;default&gt;

The mould parameter maps directly onto the [AWS instance names](http://aws.amazon.com/ec2/instance-types/).

On Aws you must also set aws_availability_zone, aws_ebs_size (can be nil), aws_key_name, aws_ssh_key, aws_subnet_id, aws_subnet_id, aws_security_group_ids
Optionally you can define additional disks to be attached to the server by defining hash additional_hdds containing device_name (e.g. /dev/sda1) and ebs_size per each hdd

#### git

- Default value "https://github.com/Adaptavist/base_puppet_templates" defines repository where to load puppet code and its hiera configuration

#### branch

- Default value "master", specifies branch 

#### reference

- Default is nil, can identify git tag to load

For more details and options check config/hiera/global.eyaml

#### Bootstrap configuration

Default bootstrap script (config/bootstrap/"cloud_operating_system.yaml.erb") runs as part of bootstrap phase. It can be replaced by providing "bootstrap_template" parameter with full path to the template. See default file for required format.

There are 3 parts in bootstrap file representing 3 stages:
- pre_upload_commands - list of commands to run before custom files are uploaded
- custom_file_uploads - hash of local path to file and path to file to upload on the server
- post_upload_commands - list of commands to run after custom files are uploaded

To be able to better scale and organize bootstrap scripts you can use additional scripts. Each file that will be included must comply to default bootstrap file format. Commands included in the templates will be appended to bootstrap in order at the end of apropriate bootstrap stage. 

To include all yaml.erb scripts from folders defined as list via extra_bootstrap_templates_folders parameter, inclusion is done in lexical order, so make sure you prefix the files with e.g. 1_file.yaml.erb, 2_file.yaml.erb. Files from folder will be added after default/custom bootstrap file commands. 

```
extra_bootstrap_templates_folders:
    - "path"/bootstrap/extra/bootstrap-centos7
```

You can as well add extra bootstrap scripts by adding extra_bootstrap_templates parameter that contains array of scripts to include in order as defined.
```
extra_bootstrap_templates:
    - "path"/bootstrap/extra/extra2.yaml.erb
    - "path"/bootstrap/extra/extra1.yaml.erb
```

It is possible to pass custom data to bootstrap scripts via "custom_data" parameter. 

### **Rackspace** setup

Check config/hiera/global.eyaml for example Rackspace setup. You have to provide Rackspace credentials, image_id, flavor_id for your instance. If you are running one of the commands bootstrap, provision, stop, you have to provide root_password for your server.

### **Azure** setup

Support for Azure Resource Manager based management was added. To create a server you have to provide:

* provider: "azurerm"
* # See https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/
* client_id: "" # Client ID:
* client_secret:  "" # 2 Year Key: ...
* tenant_id: ""  # Tenant ID: ...
* subscription_id: "" # Subscription ID

* cloud_operating_system: "centos-7"
* publisher: 'OpenLogic'
* offer: 'CentOS'
* sku: '7.1'
* version: 'latest'

* root_user: "azureuser"
* # Must comply to Azure pass guidelines
* password: "superSecretUbuntuPass111_@"
* location: 'West Europe' # Will default to West Europe
* resource_group: "new_resource_group" # if RG does not exists it will create it
* vm_size: 'Standard_A3' # Defaults to Basic_A0
* storage_account_name: "new_storage_account" # creates it if not there, if not provided will autogenerate one based on hostname
* network_interface_name: "new_network_interface" # creates it if not there, see defaults in azure_rm_connection, if not provided will autogenerate one based on hostname
* virtual_network_name: "new_virtual_network" # creates it if not there, see defaults in azure_rm_connection
* #subnet_name:  # by default one gets created for new new network, if there is one we use it if more or none it fails 
* ip_configuration_name: "new_ip_config" # creates it if not there, see defaults in azure_rm_connection, if not provided will autogenerate one based on hostname
* private_ip_allocation_method: "Dynamic"
* public_ip_allocation_method: "Static"
* #subnet_address_list: ''
* #dns_list: ''
* #network_address_list: ''
* #address_prefix: ''
* use_public_ip: true # will return public ip, if set to false, private will be used by bootstrap
* availability_set_name: # name of availability set the server should be assigned to, is in the same RG
* # define destroy behaviour, if resources should be destroyed with the server
* azure_destroy_availability_set: false
* azure_destroy_public_ip_counfig: true
* azure_destroy_netowrk_interface: true
* azure_destroy_virtual_network: false
* azure_destroy_storage_account: true
* azure_destroy_resource_group: true

### Provider none setup

Lets say you have already running server and it is not on provider avst-cloud supports. You are able to run bootstrap and provision commands with the same setup as on supported providers. 

Required parameters:

* provider: 'none'
* root_user: 'access_user_name_with_sudo'
* root_password: ''
* ip_address: 'ip_or_connection_url'



## Usage

```
Adaptavist Cloud Runner

Usage:
  avst-cloud-runner <server-name> (all|create|start|bootstrap|provision|clean) [-f] [-c CONFIG] [-x CUSTOM] [-s SERVER_CONFIG_URL]
                               [--no-report] [-u SERVER_CONFIG_URL_USERNAME] [-p SERVER_CONFIG_URL_PASSWORD]
  avst-cloud-runner <server-name> (destroy|stop) [-f] [-c CONFIG] [-x CUSTOM] [-s SERVER_CONFIG_URL] [--no-report]
                             [-k | --remove-known-hosts] [-u SERVER_CONFIG_URL_USERNAME] [-p SERVER_CONFIG_URL_PASSWORD]
  avst-cloud-runner <server-name> (test-config|status) [-f] [-c CONFIG] [-x CUSTOM] [-s SERVER_CONFIG_URL] [-u SERVER_CONFIG_URL_USERNAME] [-p SERVER_CONFIG_URL_PASSWORD]
  avst-cloud-runner (all|create|start|stop|destroy|bootstrap|provision|clean) [-f] [-x CUSTOM] [-s SERVER_CONFIG_URL] [--no-report] [-u SERVER_CONFIG_URL_USERNAME] [-p SERVER_CONFIG_URL_PASSWORD]
  avst-cloud-runner -h | --help

Options:
  -h --help                          Show this screen.
  -f --force                         Don't confirm settings [default: false]
  --no-report                        Do not report event to Confluence [default: false]
  -k --remove-known-hosts            Delete entry from ~/.ssh/known_hosts file [default: false]
  -c CONFIG --hiera_config CONFIG    Hiera config file
  -x CUSTOM --custom_config CUSTOM   Contains JSON that will be available to hiera to configure avst-cloud and passed as facts to created server
  -s SERVER_CONFIG_URL --server_config_url SERVER_CONFIG_URL url to retrieve avst-cloud configuration for the server
  -u SERVER_CONFIG_URL_USERNAME --server_config_url_username SERVER_CONFIG_URL_USERNAME username to use to retireve avst-cloud configuration for the server
  -p SERVER_CONFIG_URL_PASSWORD --server_config_url_password SERVER_CONFIG_URL_PASSWORD password for username to retrieve avst-cloud configuration for the server
Arguments:
  server-name   Must be in the format: {customer_shortcode}-{env}{server_id}
                The customer_shortcode and environment may contain
                alphanumerics and underscores.

Commands:
  all           Runs the following commands: start, bootstrap, provision
  create        Creates a server, is stopped will start it. Without bootstrap os provision
  start         Start a server on the provider. Does not bootstrap or
                provision the machine
  bootstrap     Installs required dependencies for provisioning. (RVM, Ruby,
                Puppet, Git, Hiera, Eyaml...)
                This MUST be run before the provision command
  provision     Provisions server using Puppet and Capistrano based on the
                repository specified in hiera
  clean         Runs clean commands on the server, by default gathers system stats. 
                Can pass custom commands to run. 
  status        Checks and prints a servers status
  stop          Shuts down a server but does not destroy it. (Not available
                for Rackspace provider)
  destroy       Shuts down a server and destroys it
  test-config   Checks and prints configuration

```

Server name must comply to "{customer_short_code}-{env}{server_number}" - see customer [short code and naming conventions](https://i.adaptavist.com/display/INFRA/Naming+conventions).

## Commands

 - all 
    - starts, bootstraps and provisions
 - create
    - Creates a server, is stopped will start it. Without bootstrap os provision
 - status
    - print out the status of a server
 - start 
    - starts new server, requires following params to be set in hiera:
 - stop
    - shutdown the server, but don't destroy it (not available on Rackspace as the API reports shutdown servers as ACTIVE)
 - bootstrap 
    - installs rvm, ruby 2.0, puppet, augeas, unzip
    - sets up .ssh keys, hostname and known_hosts
    - (in case of Rackspace provider, the param `root_password` is set as root password to the system)
 - provision 
    - uses Capistrano to push code from git repo/branch to server
    - runs `download_dependencies_command` command that by default installs and executes `r10k puppetfile install` and `puppet apply`
    - requires git repo and branch are setup
    - Rackspace provider requires `root_password` to be set
 - destroy 
    - destroys the server
 - test-config
    - prints out hiera setup that will be used

## Setup options

### Setup via config service

avst_cloud_config_service param must be set, in case service requires authentication, avst_cloud_config_service_username and avst_cloud_config_service_password must be provided. The service is used to load configuration and must implement following REST API:

GET "#{avst_cloud_config_service}/server_identifier"
params = {"provider" => provider, "region" => region, "operating_system" => cloud_operating_system}
returns json:
{ "image_name": "ami123123",
  "root_device_path": "/dev/sda1"}

root_device_path is used only for AWS and if it is nil it defaults to "/dev/sda1" for aws
image_name must be valid image identifier for provider, region and os

### Setup via config file

avst_cloud_config_file - path to YAML file with server image config and root device path config.

An example: 

```

---
#{provider}:
    #{region}:
        #{os}:
            'image_name': 'ami-1234123'
            'root_device_path': '/dev/xvda'

```

## Bootstrap

Bootstrap loads erb templates from config/bootstrap/{os}.sh.erb substitutes variables and run every line in separate call as part of bootstrap process. Check lib/fog_server.rb for details on default commands and uploads done.

You can define your custom bootstrap script by providing custom_bootstrap_script config in hiera setup. Define valid erb template path. An example setup is in global.eyaml and file is config/bootstrap/custom.sh.erb

## Post provision commands

After provisionning phase is done, you can setup custom commands to run on the server. By default the cleanup commnads are executed. You can specify additional commands to get executed by defining extra_post_provision_templates_folders array with folders containing yaml.erb templates and extra_post_provision_templates array containing yaml.erb files. Templates from folders are loaded in alphabetical order. Each yaml.erb file must contain post_provision_commands array of commands. Extra commands can be defined in server config file by custom_post_provision_commands array. In the templates you can use bindings and especially custom_data array that you can define in the server config files. You can use custom_cleanup_commands array in the server config file to define array of commmands to run as last in the process. Commands from templates are added in order, ordered temapltes from folders, templates defined via extra_post_provision_templates in order defined, custom_post_provision_commands array and custom_cleanup_commands from server config file.

## Reporting

Reporting to confluence via confluence reporter gem. Set following params:
- no_report - default false
- confluence_url
- confluence_user
- confluence_access_password
- confluence_parent_page_id
- confluence_space

## Override Puppet config

This is mainly used for development and testing purposes. Make sure the configurations for staging/production or any client configuration is kept in git repository.

Before puppet-runner is initiated, you can push your local configuration to newly created server by placing them to custom_system_config folder.

Like this you can replace/add any hiera config or file from the specified 'git' repo, or provide your custom configuration.

After Capistrano downloads sources from specified 'git' repo and 'branch', it will upload folders recursively from:

- `config/custom_system_config/environments`
- `config/custom_system_config/'client'/environments`
- `config/custom_system_config/'client'/'env'/environments`
- `config/custom_system_config/'client'/'env'/'server_name'/environments` 

into newly created server to /etc/puppet/environments.

then:

- `config/custom_system_config/hiera-configs`

into newly created server to /etc/puppet/hiera-configs. Place your puppet setup('server_name'.yaml and 'server_name'_facts.yaml as defined in puppet-runner) for server here.  

Files from:

- `config/custom_system_config/'client'/files`
- `config/custom_system_config/'client'/'env'/files`
- `config/custom_system_config/'client'/'env'/'server_name'/files` 

will be uploaded to /etc/puppet/config/files.

This project contains example for server environments folder and hiera-configs.

