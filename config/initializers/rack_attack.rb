Rack::Attack.throttle("requests by ip", limit: 300, period: 5.minutes) do |req|
  req.ip unless req.path.start_with?("/api-docs")
end

Rack::Attack.throttle("auth attempts", limit: 5, period: 1.minute) do |req|
  req.ip if req.path.match?(%r{/api/v1/(login|register)}) && req.post?
end
