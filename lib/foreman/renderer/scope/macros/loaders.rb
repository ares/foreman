module Foreman
  module Renderer
    module Scope
      module Macros
        module Loaders
          include Foreman::Renderer::Errors

          # TODO all helpers
          apipie :method, 'Loads hosts objects' do
            desc "This macro returns a collection of Hosts matching search criteria.
              The collection is limited to what objects the current user is authorized to view. Also it's loaded in bulk
              of 1 000 records."
            param_group :load_resource_keywords
            returns array_of: Host, desc: 'The collection that can be iterated over using each_record'
            example "<% load_hosts.each_record do |host| %>
  <%= host.name %>, <%= host.ip %>
<% end %>", desc: 'Prints host name and ip of each host'
            example "<% load_hosts(search: 'domain = example.com', includes: [ :interfaces ]).each_record do |host| %>
  <%= host.name %>, <%= host.interfaces.map { |i| i.mac }.join(', ') %>
<% end %>"
end
          LOADERS = [
            [ :load_organizations, Organization, :view_organizations ],
            [ :load_locations, Location, :view_locations ],
            [ :load_hosts, Host, :view_hosts ],
            [ :load_operating_systems, Operatingsystem, :view_operatingsystems ],
            [ :load_subnets, Subnet, :view_subnets ],
            [ :load_smart_proxies, SmartProxy, :view_smart_proxies ],
            [ :load_user_groups, Usergroup, :view_usergroups ],
            [ :load_host_groups, Hostgroup, :view_hostgroups ],
            [ :load_domains, Domain, :view_domains ],
            [ :load_realms, Realm, :view_realms ],
            [ :load_users, User, :view_users ],
          ]

          LOADERS.each do |name, model, permission|
            define_method name do |search: '', includes: nil, preload: nil, joins: nil, select: nil, batch: 1_000, limit: nil|
              load_resource(klass: model, search: search, permission: permission, includes: includes, preload: preload, joins: joins, select: select, batch: batch, limit: limit)
            end
          end

          private

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
