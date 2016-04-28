require 'rqrcode'
require 'base64'

module DeviseTwoFactorable
  module Controllers
    module Helpers
      def authenticate_scope!
        send(:"authenticate_#{resource_name}!", force: true)
        self.resource = send("current_#{resource_name}")
      end

      #
      # similar to DeviseController#set_flash_message, but sets the scope inside
      # the otp controller
      #
      def otp_set_flash_message(key, kind, options = {})
        options[:scope] ||= "devise.two_factor.#{controller_name}"
        options[:default] = Array(options[:default]).unshift(kind.to_sym)
        options[:resource_name] = resource_name
        options = devise_i18n_options(options) if respond_to?(:devise_i18n_options, true)
        message = I18n.t("#{options[:resource_name]}.#{kind}", options)
        flash[key] = message if message.present?
      end

      def otp_t
      end

      def trusted_devices_enabled?
        resource.class.otp_trust_persistence && (resource.class.otp_trust_persistence > 0)
      end

      def recovery_enabled?
        resource_class.otp_recovery_tokens && (resource_class.otp_recovery_tokens > 0)
      end

      #
      # Sanity check for resource validity
      #
      def ensure_resource!
        raise ArgumentError, 'Should not happen' if resource.nil?
      end

      # FIXME: do cookies and persistence need to be scoped? probably

      #
      # check if the resource needs a credentials refresh. IE, they need to be asked a password again to access
      # this resource.
      #
      def needs_credentials_refresh?(resource)
        return false unless resource.class.otp_credentials_refresh

        (!session[otp_scoped_refresh_property].present? ||
            (session[otp_scoped_refresh_property] < DateTime.now)).tap { |need| otp_set_refresh_return_url if need }
      end

      #
      # credentials are refreshed
      #
      def otp_refresh_credentials_for(resource)
        return false unless resource.class.otp_credentials_refresh
        session[otp_scoped_refresh_property] = (Time.now + resource.class.otp_credentials_refresh)
      end

      #
      # is the current browser trusted?
      #
      def is_otp_trusted_device_for?(resource)
        return false unless resource.class.otp_trust_persistence
        if cookies[otp_scoped_persistence_cookie].present?
          cookies.signed[otp_scoped_persistence_cookie] ==
            [resource.to_key, resource.authenticatable_salt, resource.otp_persistence_seed]
        else
          false
        end
      end

      #
      # make the current browser trusted
      #
      def otp_set_trusted_device_for(resource)
        return unless resource.class.otp_trust_persistence
        cookies.signed[otp_scoped_persistence_cookie] = {
          httponly: true,
          expires: Time.now + resource.class.otp_trust_persistence,
          value: [resource.to_key, resource.authenticatable_salt, resource.otp_persistence_seed]
        }
      end

      def otp_set_refresh_return_url
        session[otp_scoped_refresh_return_url_property] = request.fullpath
      end

      def otp_fetch_refresh_return_url
        session.delete(otp_scoped_refresh_return_url_property) { :root }
      end

      def otp_scoped_refresh_return_url_property
        "otp_#{resource_name}refresh_return_url".to_sym
      end

      def otp_scoped_refresh_property
        "otp_#{resource_name}refresh_after".to_sym
      end

      def otp_scoped_persistence_cookie
        "otp_#{resource_name}_device_trusted"
      end

      #
      # make the current browser NOT trusted
      #
      def otp_clear_trusted_device_for(_resource)
        cookies.delete(otp_scoped_persistence_cookie)
      end

      #
      # clears the persistence list for this kind of resource
      #
      def otp_reset_persistence_for(resource)
        otp_clear_trusted_device_for(resource)
        resource.reset_otp_persistence!
      end

      #
      # returns the URL for the QR Code to initialize the Authenticator device
      #
      def otp_authenticator_token_image(resource)
        data = resource.otp_provisioning_uri
        qrcode = RQRCode::QRCode.new(data, level: :m, mode: :byte_8bit)
        png = qrcode.as_png(fill: 'white', color: 'black', border_modules: 1, module_px_size: 4)
        url = "data:image/png;base64,#{Base64.encode64(png.to_s).strip}"
        image_tag(url, alt: 'OTP Authenticator QRCode')
      end
    end
  end
end