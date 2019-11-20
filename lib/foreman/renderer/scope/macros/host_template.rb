module Foreman
  module Renderer
    module Scope
      module Macros
        module HostTemplate
          extend ApipieDSL::Module

          # TODO see does not work inside a module

          apipie :class, desc: 'HostTemplate' do
            property :host, String, desc: 'Host macros will execute be executed on this host object'
          end

          include Foreman::Renderer::Errors

          # TODO incomplete - the whole file needs revisit when rendering works
          apipie :method, 'Returns a host ENC representation' do
             desc "External Node Classifier is a concept used by configuration management
               systems that allows Foreman to define, what configuration should be applied to a given
               host. It consists of configuration environment, configuration classes (e.g. puppet classes)
               and its parameters. Foreman adds some additional parameters that can be consumed by
               configuration management agents.
               Sometimes it can be useful to look at values specified for configuration management
               agent and render a template accordingly. For example the ntp_server later managed by puppet
               can be configured during provisioning already.
               An example of minimal ENC output can look similar to this
               <pre>
               {'parameters'=>
                {'foreman_subnets'=>[],
                 'foreman_interfaces'=>
                  [{'ip'=>nil,
                    'ip6'=>'',
                    'mac'=>'ee:8c:1b:48:0c:34',
                    'name'=>'bart2.guest2.wlan.public',
                    'attrs'=>{},
                    'virtual'=>false,
                    'link'=>true,
                    'identifier'=>'wlp61s0',
                    'managed'=>true,
                    'primary'=>true,
                    'provision'=>true,
                    'subnet'=>nil,
                    'subnet6'=>nil,
                    'tag'=>nil,
                    'attached_to'=>nil,
                    'type'=>'Interface'}],
                 'location'=>'Default Location',
                 'location_title'=>'Default Location',
                 'organization'=>'Default Organization',
                 'organization_title'=>'Default Organization',
                 'domainname'=>'guest2.wlan.public',
                 'owner_name'=>'Admin User',
                 'owner_email'=>'root@example.tst',
                 'ssh_authorized_keys'=>[],
                 'foreman_users'=>
                  {'admin'=>
                    {'firstname'=>'Admin',
                     'lastname'=>'User',
                     'mail'=>'root@example.tst',
                     'description'=>'',
                     'fullname'=>'Admin User',
                     'name'=>'admin',
                     'ssh_authorized_keys'=>[]}},
                 'root_pw'=>
                  '$5$0XSSSSrdSn1l3mzn$6KeSBoHpg8pEgCK5JexVB4WqFqTI72ZYaE8jMaEcmWC',
                 'foreman_config_groups'=>[],
                 'puppetmaster'=>''},
               'classes'=>[]}
               </pre>"
            optional :path, String, desc: 'expanded array of strings definining a subtree of ENC output'
            returns Object, desc: 'part of the ENC output for a given host'
            raises error: HostENCParamUndefined, desc: 'when user asks for invalid path.'
            example "host_enc # => { ... } "
            example "host_enc('classes') # => [] "
            example "host_enc('parameters', 'owner_email') # => 'root@example.tst'"
          end
          def host_enc(*path)
            check_host
            return enc if path.compact.empty?
            path.reduce(enc) do |e, step|
              begin
                e.fetch(step)
              rescue KeyError
                raise HostENCParamUndefined.new(name: path, step: step, host: host)
              end
            end
          end

          apipie :method, 'Returns a host parameter value' do
            desc "Host can be assigned parameters. These are perfect match for conditional logic
              in any template. Parameters can be set globally (affecting all hosts), per organization, location,
              domain, subnet, operating system, hostgroup, host. The list is in order in which they are evaluated.
              Meaning a global parameter with name +ntp_server+ can be overriden for a specific subnet, if defined
              for that subnet with the same name. Only objects assigned to such host are considered during evaluation.

              The evaluation can take some time, therefore values are cached per template rendering. Meaning if some
              parameter renders the value dynmacilly, e.g. using ERB, it would be evaluated just once.

              Only parameters authorized via +view_params+ are considered. The user under which the template is rendered
              is considered for all authorization checks."
            required :param_name, String, desc: 'name of the parameter'
            optional :default, Object, desc: 'a value returned if the parameter is not defined for the host (including parameter inheritance)'
            returns Object, desc: 'evaluated value based on parameter inheritance, the value is of parameter type, hence could be e.g. String, Array, Hash'
            raises error: HostUnknown , desc: 'when user asks for a parameter but host is available in rendering context.'
            example "host_param('ntp_server') # => ntp.example.com"
            example "host_param('motd') # => nil"
            example "host_param('motd', 'Hello world') # => 'Hello world'"
          end
          def host_param(param_name, default = nil)
            check_host
            host.host_param(param_name) || default
          end

          apipie :method, 'Returns a host parameter value' do
            desc "Host can be assigned parameters. These are perfect match for conditional logic
              in any template. Parameters can be set globally (affecting all hosts), per organization, location,
              domain, subnet, operating system, hostgroup, host. The list is in order in which they are evaluated.
              Meaning a global parameter with name +ntp_server+ can be overriden for a specific subnet, if defined
              for that subnet with the same name. Only objects assigned to such host are considered during evaluation.

              The evaluation can take some time, therefore values are cached per template rendering. Meaning if some
              parameter renders the value dynmacilly, e.g. using ERB, it would be evaluated just once.

              Only parameters authorized via +view_params+ are considered. The user under which the template is rendered
              is considered for all authorization checks."
            required :param_name, String, desc: 'name of the parameter'
            returns Object, desc: 'evaluated value based on parameter inheritance, the value is of parameter type, hence could be e.g. String, Array, Hash'
            raises error: HostParamUndefined , desc: 'when user asks for undefined parameter.'
            example "host_param!('ntp_server') # => ntp.example.com"
            # see "host_param"
          end
          def host_param!(param_name)
            check_host_param(param_name)
            host_param(param_name)
          end

          apipie :method, 'Returns an array of puppet classes assigned to host' do
            desc "Host can be assigned puppet classes either directly or through host groups and config
              groups. This methods returns puppet class objects assigned to host directly."
            returns Array, desc: 'evaluated value based on parameter inheritance, the value is of parameter type, hence could be e.g. String, Array, Hash'
            raises error: HostUnknown , desc: 'when user asks for a parameter but host is available in rendering context.'
            example "host_puppet_classes # => [...]"
          end
          def host_puppet_classes
            check_host
            host.puppetclasses
          end

          apipie :method, desc: "Returns a true if a parameter is considered truthy" do
            desc "Parameters tends to be used in conditions. Users who set parameters tends to use
              different values for truthy and falsy values. This method will return true for mostly used truthy values.
              Following values are considered truthy: true, t, yes, y, on, 1
              Following values are considered falsy: false, f, no, n, off, 0"
            required :param_name, String, desc: 'name of the parameter'
            returns one_of: [true, false], desc: 'true for truthy values, fales for falsy values or when parameter with a given name was not found'
            raises error: HostUnknown , desc: 'when user asks for a parameter but host is available in rendering context.'
            example "host_param_true?('enable-epel') # => true"
            example "host_param_true?('motd') # => false"
          end
          def host_param_true?(name)
            check_host
            host.params.has_key?(name) && Foreman::Cast.to_bool(host.params[name])
          end

          apipie :method, 'Returns a false if a parameter is considered falsy' do
            desc "Parameters tends to be used in conditions. Users who set parameters tends to use
              different values for truthy and falsy values. This method will return true for mostly used falsy values.
              Following values are considered truthy: true, t, yes, y, on, 1
              Following values are considered falsy: false, f, no, n, off, 0"
            required :param_name, String, desc: 'name of the parameter'
            returns one_of: [true, false], desc: 'true for falsy values, false for truthy values, or when parameter with a given name was not found'
            raises error: HostUnknown , desc: 'when user asks for a parameter but host is available in rendering context.'
            example "host_param_false?('enable-epel') # => false"
            example "host_param_false?('motd') # => false"
            #see "host_param_true?"
          end
          def host_param_false?(name)
            check_host
            host.params.has_key?(name) && Foreman::Cast.to_bool(host.params[name]) == false
          end

          apipie :method, 'Returns a root password hash for a host' do
            desc "Root password can be set for host either directly, for host group or globally, using
              +root_pass+ setting. The macro finds the value in host first, fallbacks to host's host group and then to
              setting. Both host and host group level root password is hashed using host OS hash function, usually sha256.
              Value stored in settings is not hashed and is printed as a plain text value.
              Whenever the host object is saved and it's root password is missing, it copies value from host group/setting
              and hashes it, so the password remains set the same even if common value changes."
            returns String, desc: 'either a hash or plain text of password based on source'
            raises error: HostUnknown , desc: 'when user asks for a parameter but host is available in rendering context.'
            example "root_pass # => '$5$0XSSSSrdSn1l3mzn$6KeSBoHpg8pEgCK5JexVB4WqFqTI72ZYaE8jMaEcmWC'"
            example "root_pass # => 'changeme'"
          end
          def root_pass
            check_host
            host.root_pass
          end

          apipie :method, desc: "Returns a kickstart snippet for setting GRUB password for a host on bootloader line" do
            desc "GRUB password can be set for host either direcrly or for host group. The value is
              always stored hashed on host object. If GRUB password is changed later on host group, it will remain
              untouched on the host, hence this macro will continue returning the original value.
              It returns empty string in case, GRUB is not set. #TODO, can't tell when it's set to something
              If the stored hashed password is using md5 (previous versions of Foreman), --md5pass variant will be used."
            returns String, desc: 'hashed value of a GRUB password'
            example "grub_pass # => '--iscrypted --password=$6$50lofaqqIsKQAHCE$d1.K7jF37DqN7KleaRAt5yfgbdx4q8NAnJI44LIGEQMI4CTEP/Vld8tprB2y69gUzREvMffy4XEeA7JCAvC.S1'"
            example "grub_pass # => '--md5sum=$1$IKwrkaAn$CIfQOpDXqCWAkBGjjIdHn0'"
          end
          def grub_pass
            return '' unless @grub
            host.grub_pass.start_with?('$1$') ? "--md5pass=#{host.grub_pass}" : "--iscrypted --password=#{host.grub_pass}"
          end

          # TODO revisit with someone who knows better
          apipie :method, desc: "Returns a kickstart snippet for setting a serial console" do
            desc "A serial console can be configured in kickstart template using console parameter
              on bootloader line. User can specify port and baud."
            returns String, desc: 'serial console configuration snippet, empty string if either @port of @baud variables are missing'
            example "ks_console # => 'console=ttyS#1,64'"
            example "ks_console # => ''"
          end
          def ks_console
            (@port && @baud) ? "console=ttyS#{@port},#{@baud}" : ''
          end

          private

          def enc
            @enc ||= host.info.deep_dup
          end

          def check_host
            raise c if host.nil?
          end

          def check_host_param(name)
            check_host
            raise HostParamUndefined.new(name: name, host: host) unless host.params.key?(name)
          end
        end
      end
    end
  end
end
