require "webmock/rspec"

# No spec should reach a real external provider; adapter specs stub HTTP
# explicitly. Local connections stay allowed for any in-process test servers.
WebMock.disable_net_connect!(allow_localhost: true)
