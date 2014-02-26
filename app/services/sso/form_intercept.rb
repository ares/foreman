module SSO
  class FormIntercept < Apache

    def current_user
      return User.find_by_login(request.env[CAS_USERNAME])
    end

    def login_url
      controller.main_app.login_users_path
    end

    def logout_url
      controller.logout_users_path
    end

    def expiration_url
      controller.main_app.login_users_path
    end
  end
end
