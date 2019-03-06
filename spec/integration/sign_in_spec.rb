require 'spec_helper'

RSpec.describe 'Sign In', type: :system do
  before :each do
    @user = User.new(email: 'matt@geemail.com', password: 'password')
  end

  it 'creates a valid user' do
    expect(@user.valid?).to be true
  end

  it 'generates a ROTP code' do
    expect(@user.valid_otp_auth_secret?).to be true
  end
end
