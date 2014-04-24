json.array!(@beavers) do |beaver|
  json.extract! beaver, :id, :name
  json.url beaver_url(beaver, format: :json)
end
