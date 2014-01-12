module Api::ImportPuppetclassesCommonController
  extend ActiveSupport::Concern

  included do
    before_filter :find_required_puppet_proxy, :only => [:import_puppetclasses]
    before_filter :get_environment_id, :only => [:import_puppetclasses]
    before_filter :find_optional_environment, :only => [:import_puppetclasses]
  end

  extend Apipie::DSL::Concern

  api :POST, "/smart_proxies/:id/import_puppetclasses", "Import puppet classes from puppet proxy."
  api :POST, "/smart_proxies/:smart_proxy_id/environments/:id/import_puppetclasses", "Import puppet classes from puppet proxy for particular environment."
  api :POST, "/environments/:environment_id/smart_proxies/:id/import_puppetclasses", "Import puppet classes from puppet proxy for particular environment."
  param :id, :identifier, :required => true
  param :smart_proxy_id, String, :required => false
  param :environment_id, String, :required => false
  param :dryrun, :bool, :required => false

  def import_puppetclasses
    return unless changed_environments

    # DRYRUN - /import_puppetclasses?dryrun - do not run PuppetClassImporter
    rabl_template = @environment ? 'show' : 'index'
    if params.key?('dryrun') && !['false', false].include?(params['dryrun'])
      render("api/v1/import_puppetclasses/#{rabl_template}", :layout => "api/layouts/import_puppetclasses_layout")
      return
    end

    # RUN PuppetClassImporter
    if (errors = ::PuppetClassImporter.new.obsolete_and_new(@changed)).empty?
      render("api/v1/import_puppetclasses/#{rabl_template}", :layout => "api/layouts/import_puppetclasses_layout")
    else
      render :json => {:message => "Failed to update the environments and puppetclasses from the on-disk puppet installation #{errors.join(", ")}"}, :status => 500
    end
  end

  def changed_environments
    begin
      opts      =  { :url => @smart_proxy.url }
      @importer = PuppetClassImporter.new(opts)
      @changed  = @importer.changes

      # check if environemnt id passed in URL is name of NEW environment in puppetmaster that doesn't exist in db
      if @environment || (@changed['new'].keys.include?(@env_id) && (@environment ||= OpenStruct.new(:name => @env_id)))
        # only return :keys equal to @environment in @changed hash
        ["new", "obsolete", "updated"].each do |kind|
          @changed[kind].slice!(@environment.name) unless @changed[kind].empty?
        end
      end

    rescue => e
      if e.message =~ /puppet feature/i
        msg = 'We did not find a foreman proxy that can provide the information, ensure that this proxy has the puppet feature turned on.'
      else
        msg = e.message
      end
      render :json => {:message => msg}, :status => 500 and return false
    end

    # PuppetClassImporter expects [kind][env] to be in json format
    ["new", "obsolete", "updated"].each do |kind|
      unless (envs = @changed[kind]).empty?
        envs.keys.sort.each do |env|
          @changed[kind][env] = @changed[kind][env].to_json
        end
      end
    end

    # @environments is used in import_puppletclasses/index.json.rabl
    environment_names = (@changed["new"].keys + @changed["obsolete"].keys + @changed["updated"].keys).uniq.sort
    @environments = environment_names.map do |name|
                      OpenStruct.new(:name => name)
                    end

    render :json => {:message => "No changes to your environments detected"} and return false unless @environments.any?
    @environments.any?
  end

  def find_required_puppet_proxy
    id = params.keys.include?('smart_proxy_id') ? params['smart_proxy_id'] : params['id']
    @smart_proxy   = SmartProxy.authorized(:view_smart_proxies).find_by_id(id.to_i) if id.to_i > 0
    @smart_proxy ||= SmartProxy.authorized(:view_smart_proxies).find_by_name(id)
    unless @smart_proxy && SmartProxy.puppet_proxies.pluck("smart_proxies.id").include?(@smart_proxy.id)
      not_found 'We did not find a foreman proxy that can provide the information, ensure that this proxy has the puppet feature turned on.'
    end
    @smart_proxy
  end

  def get_environment_id
    @env_id = if params.keys.include?('environment_id')
                params['environment_id']
              elsif controller_name == 'environments' && params['id'].present?
                params['id']
              end
    @env_id
  end

  def find_optional_environment
    @environment   = Environment.authorized(:view_environments).find_by_id(@env_id.to_i) if @env_id.to_i > 0
    @environment ||= Environment.authorized(:view_environments).find_by_name(@env_id)
    @environment
  end

end
