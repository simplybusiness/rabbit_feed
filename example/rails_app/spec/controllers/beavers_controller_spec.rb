describe BeaversController do
  describe 'POST create' do
    it 'publishes a create event' do
      expect do
        post :create, beaver: { name: 'beaver' }
      end.to publish_event('user_creates_beaver', 'beaver_name' => 'beaver')
    end
  end

  context 'for an existing beaver' do
    let(:beaver) { Beaver.create name: 'beaver' }

    describe 'PUT update' do
      it 'publishes an update event' do
        expect do
          put :update, id: beaver.id, beaver: { name: 'beaver_updated' }
        end.to publish_event('user_updates_beaver', 'beaver_name' => 'beaver_updated')
      end
    end

    describe 'DELETE destroy' do
      it 'publishes an delete event' do
        expect do
          delete :destroy, id: beaver.id
        end.to publish_event('user_deletes_beaver', 'beaver_name' => 'beaver')
      end
    end
  end
end
