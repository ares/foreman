module Foreman
  module Renderer
    module Scope
      module Macros
        module Base
          extend ApipieDSL::Module
          include Foreman::Renderer::Errors
          include ::Foreman::ForemanUrlRenderer

          attr_reader :template_name, :medium_provider

          delegate :medium_uri, to: :medium_provider

          apipie :method, desc: "Returns true if subnet has a given parameter set, false otherwise.
              This does not take inheritance into consideration,
              it only searches for parameters assigned directly to the subnet. " do
            required :subnet, Subnet, desc: 'a __Subnet__ object for which we check the parameter presence'
            required :param_name, String, desc: 'a parameter __name__ to check the presence of'
            returns one_of: [true, false]
            raises error: WrongSubnetError, desc: 'when user passes non-subnet object as __subnet__ parameter'
          end
          def subnet_has_param?(subnet, param_name)
            validate_subnet(subnet)
            subnet.parameters.exists?(name: param_name)
          end

          apipie :method, desc: "Returns the value of global setting" do
            required :name, String, desc: "The name of the setting which can be found by hovering the setting with mouse cursor in the UI, or via API/CLI"
            optional :blank_default, Object, desc: "If the setting is not set to any value, this value will be returned instead"
            returns Object, desc: 'the value of global setting'
            example "global_setting('foreman_url') # => 'https://foreman.example.com'"
            example "global_setting('outofsync_interval', 30) # => 30"
          end
          def global_setting(name, blank_default = nil)
            raise FilteredGlobalSettingAccessed.new(name: name) if Setting[:safemode_render] && !Foreman::Renderer.config.allowed_global_settings.include?(name.to_sym)
            setting = Setting.find_by_name(name.to_sym)
            (setting.settings_type != "boolean" && setting.value.blank?) ? blank_default : setting.value
          end

          apipie :method, desc: "Returns true if plugin with a given name is installed in this Foreman instance" do
            required :name, String, desc: 'The name of the plugin'
            returns one_of: [true, false]
            example "plugin_present?('foreman_ansible') # => true"
            example "plugin_present?('foreman_virt_who_configure') # => false"
          end
          def plugin_present?(name)
            Foreman::Plugin.find(name).present?
          end

          apipie :method, desc: "Returns the value of parameter set on subnet" do
            required :name, Subnet, desc: 'The subnet to load the parameter from'
            # returns 'the value'
            returns Object, desc: 'The value'
            # returns one_of: [nil, Object]
          end
          def subnet_param(subnet, param_name)
            validate_subnet(subnet)
            param = subnet.parameters.where(name: param_name).first
            param.nil? ? nil : param.value
          end

          def foreman_server_fqdn
            config = URI.parse(Setting[:foreman_url])
            config.host
          end

          def foreman_server_url
            Setting[:foreman_url]
          end

          def pxe_kernel_options
            return '' unless host || host.operatingsystem
            host.operatingsystem.pxe_kernel_options(host.params).join(' ')
          rescue => e
            template_logger.warn "Unable to build PXE kernel options: #{e}"
            ''
          end

          def save_to_file(filename, content)
            "cat << EOF > #{filename}\n#{content}EOF"
          end

          def indent(count, skip1: false)
            return unless block_given? && (text = yield.to_s)
            prefix = ' ' * count
            result = []
            text.each_line.with_index do |line, line_no|
              if line_no == 0 && skip1
                result << line
              else
                result << prefix + line
              end
            end
            result.join('')
          end

          def dns_lookup(name_or_ip)
            resolver = Resolv::DNS.new
            Timeout.timeout(Setting[:dns_conflict_timeout]) do
              begin
                resolver.getname(name_or_ip)
              rescue Resolv::ResolvError
                resolver.getaddress(name_or_ip)
              end
            end
          rescue StandardError => e
            log_warn "Template helper dns_lookup failed: #{e}"
            raise e
          end

          def default_template_url(template, hostgroup)
            uri      = URI.parse(Setting[:unattended_url])
            host     = uri.host
            port     = uri.port
            protocol = uri.scheme

            url_for(:only_path => false, :action => :hostgroup_template, :controller => '/unattended',
                    :id => template.name, :hostgroup => hostgroup.title, :protocol => protocol,
                    :host => host, :port => port)
          end

          def load_hosts(search: '', includes: nil, preload: nil)
            load_resource(klass: Host, search: search, permission: 'view_hosts', includes: includes, preload: preload)
          end

          def all_host_statuses
            @all_host_statuses ||= HostStatus.status_registry.to_a.sort_by(&:status_name)
          end

          def all_host_statuses_hash(host)
            all_host_statuses.map { |status| [status.status_name, host_status(host, status.status_name).status] }.to_h
          end

          def host_status(host, name)
            klass = all_host_statuses.find { |status| status.status_name == name }
            raise UnknownHostStatusError.new(status: name, statuses: all_host_statuses.map(&:status_name).join(',')) if klass.nil?
            host.get_status(klass)
          end

          def preview?
            mode == Renderer::PREVIEW_MODE
          end

          def rand_hex(n)
            SecureRandom.hex(n)
          end

          def rand_name
            NameGenerator.new.generate_next_random_name
          end

          def mac_name(mac_address)
            NameGenerator.new.generate_next_mac_name(mac_address)
          end

          def host_kernel_release(host)
            host&.kernel_release&.value
          end

          def host_uptime_seconds(host)
            host&.uptime_seconds
          end

          private

          def validate_subnet(subnet)
            raise WrongSubnetError.new(object_name: subnet.to_s, object_class: subnet.class.to_s) unless subnet.is_a?(Subnet)
          end

          # returns a batched relation, use either
          #   .each { |batch| batch.each { |record| record.name }}
          # or
          #   .each_record { |record| record.name }
          def load_resource(klass:, search:, permission:, batch: 1_000, includes: nil, limit: nil, select: nil, joins: nil, where: nil, preload: nil)
            limit ||= 10 if preview?

            base = klass
            base = base.search_for(search)
            base = base.preload(preload) unless preload.nil?
            base = base.includes(includes) unless includes.nil?
            base = base.joins(joins) unless joins.nil?
            base = base.authorized(permission) unless permission.nil?
            base = base.limit(limit) unless limit.nil?
            base = base.where(where) unless where.nil?
            base = base.select(select) unless select.nil?
            base.in_batches(of: batch)
          end
        end
      end
    end
  end
end
