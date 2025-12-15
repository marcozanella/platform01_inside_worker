# Mission Control configuration
# Disable authentication for internal admin tool access

Rails.application.config.to_prepare do
  # Override Mission Control authentication
  MissionControl::Jobs::ApplicationController.class_eval do
    skip_before_action :authenticate, raise: false

    # Override any HTTP Basic authentication
    def authenticate
      # Allow unrestricted access
      true
    end
  end
end
