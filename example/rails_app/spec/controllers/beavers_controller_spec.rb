require 'rails_helper'

describe BeaversController do

  describe 'POST create' do
    it 'publishes a create event' do
      expect{
        post :create, beaver: { name: 'beaver' }
      }.to publish_event('user_creates_beaver', { 'beaver_name' => 'beaver' })
    end
  end

  context 'for an existing beaver' do
    let(:beaver) { Beaver.create name: 'beaver' }

    describe 'PUT update' do
      it 'publishes an update event' do
        expect{
          put :update, id: beaver.id, beaver: { name: 'beaver_updated' }
        }.to publish_event('user_updates_beaver', { 'beaver_name' => 'beaver_updated' })
      end
    end

    describe 'DELETE destroy' do
      it 'publishes an delete event' do
        expect{
          delete :destroy, id: beaver.id
        }.to publish_event('user_deletes_beaver', { 'beaver_name' => 'beaver' })
      end
    end
  end
end
