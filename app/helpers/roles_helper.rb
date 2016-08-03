module RolesHelper
  def role_link(role)
    if role.builtin?
      content_tag(:em, h(role.name) + ' ' + role_status(role))
    else
      content_tag(:span) do
        link_to_if_authorized(h(role.name) + ' ' + role_status(role), hash_for_edit_role_path(:id => role))
      end
    end
  end

  def role_status(role)
    if role.filters_out_of_sync?
      content_tag(:i, '', :class => 'pficon-info status-warn', :title => _('Some filters have organizations or locations out of sync.')).html_safe
    else
      ''
    end
  end
end
