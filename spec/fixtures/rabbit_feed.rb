receive do
  from(application: 'chopin', version: '1.0.0') do
    event { 'purchase' }
    event { 'quote' }
  end
end
