EventDefinitions do
  define_event('user_creates_beaver', version: '1.0.0') do
    defined_as do
      'A beaver has been created'
    end
    payload_contains do
      field('beaver_name', type: 'string', definition: 'The name of the beaver')
    end
  end

  define_event('user_updates_beaver', version: '1.0.0') do
    defined_as do
      'A beaver has been updated'
    end
    payload_contains do
      field('beaver_name', type: 'string', definition: 'The name of the beaver')
    end
  end

  define_event('user_deletes_beaver', version: '1.0.0') do
    defined_as do
      'A beaver has been deleted'
    end
    payload_contains do
      field('beaver_name', type: 'string', definition: 'The name of the beaver')
    end
  end
end

EventRouting do
  accept_from('non_rails_app') do
    event('application_acknowledges_event') do |event|
      ::EventHandler.handle_event event
    end
  end
end
