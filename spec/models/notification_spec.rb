require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:phone_number_authed_user) { create(:user,
                                          phone_number_valid: true,
                                          phone_number: Faker::PhoneNumber.cell_phone) }
  let(:phone_number_unauth_user) { create(:user, phone_number_valid: false) }

  context 'valid' do
    it 'with factory' do
      notification = build(:notification)
      expect(notification).to be_valid
      expect(notification.save).to be_truthy
    end
  end

  context 'invalid' do
    it 'unauthed user can only send register sms' do
      Notification.categories.each do |key, value|
        if key == 'register'
          expect(build(:notification, user: phone_number_unauth_user, category: key)).to be_valid
        else
          expect(build(:notification, user: phone_number_unauth_user, category: key)).to_not be_valid
        end
      end
    end

    it 'authed user can send any type of sms, except register' do
      Notification.categories.each do |key, value|
        if key == 'register'
          expect(build(:notification, user: phone_number_authed_user, category: key)).to_not be_valid
        else
          expect(build(:notification, user: phone_number_authed_user, category: key)).to be_valid
        end
      end
    end
  end

  context 'execute' do
    let(:notification_to_advertise) { create(:notification, user: phone_number_authed_user, category: :advertise) }

    it 'success' do
      mock_response = double(status: true, message: 'message id')
      allow(notification_to_advertise).to receive(:send_sms).and_return(mock_response)

      result = notification_to_advertise.execute
      expect(result).to eq true
      expect(notification_to_advertise.successful?).to eq true
    end

    it 'failed' do
      mock_response = double(status: false, message: 'failed message')
      allow(notification_to_advertise).to receive(:send_sms).and_return(mock_response)

      result = notification_to_advertise.execute
      expect(result).to eq false
      expect(notification_to_advertise.failed?).to eq true
    end
  end
end