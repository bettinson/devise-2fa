require 'spec_helper'

describe User do
  context 'attributes' do
    user = User.new(email: 'matt@geemail.com', password: 'hi')

    describe '#email' do
      it 'can store and retrieve email' do
        expect(user.email).to eq 'matt@geemail.com'
      end
    end

    describe '#password' do
      it 'can store and retrieve password' do
        expect(user.password).to eq 'hi'
      end
    end
  end
end
