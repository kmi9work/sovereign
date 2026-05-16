Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Build origins list dynamically based on environment
    dev_ip = ENV['DEV_IP'] || '192.168.1.101'
    frontend_port = ENV['FRONTEND_PORT'] || '5173'
    
    allowed_origins = [
      # Production frontend URLs
      'https://sovereign.igroteh.su',
      
      # Frontend URLs
      "http://#{dev_ip}:#{frontend_port}",
      "http://localhost:#{frontend_port}",
      
      # Mobile Expo URLs (common ports)
      "http://#{dev_ip}:8081",
      "http://localhost:8081",
      "http://#{dev_ip}:19000",
      "http://localhost:19000",
      "http://#{dev_ip}:19006",
      "http://localhost:19006",
      
      # Localhost variations
      'http://127.0.0.1:5173',
      'http://127.0.0.1:8081',
      'http://127.0.0.1:19000',
      'http://127.0.0.1:19006',
    ]
    
    # In development, also allow all local network origins
    if Rails.env.development?
      allowed_origins << /^http:\/\/192\.168\.\d+\.\d+:(5173|8081|19000|19006)$/
      allowed_origins << /^http:\/\/10\.\d+\.\d+\.\d+:(5173|8081|19000|19006)$/
      allowed_origins << /^http:\/\/172\.(1[6-9]|2[0-9]|3[0-1])\.\d+\.\d+:(5173|8081|19000|19006)$/
    end
    
    origins allowed_origins
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true  # Important: must be true for session cookies to work
  end
end

# https://pragmaticstudio.com/tutorials/rails-session-cookies-for-api-authentication
