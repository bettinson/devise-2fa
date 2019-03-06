class User
  attr_accessor :email, :password

  def initialize(email:, password:)
    @email = email
    @password = password
  end

  def otp_auth_secret
    @otp_auth_secret ||= SecureRandom.hex
  end

  def valid?
    valid_email? && valid_password?
  end

  private

  def validate(field)
    !field.blank?
  end

  def method_missing(m, *args, &block)
    if m.to_s.start_with?('valid_')
      field = m.to_s.split('valid_')[1]
      field = field.split('?')[0]

      send('validate', field, &block)
    end
  end
end
