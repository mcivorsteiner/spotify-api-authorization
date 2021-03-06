class SpotifyAuth
  include HTTParty
  base_uri 'https://accounts.spotify.com'

  def initialize
    @client_id = ENV['CLIENT_ID']
    @client_secret = ENV['CLIENT_SECRET']
    @scope = "user-read-private user-read-email user-library-read playlist-read-private"
  end

  def spotify_auth_url(state, host)
    query_hash = {
      response_type: 'code',
      client_id: @client_id,
      scope: @scope,
      redirect_uri: redirect_uri(host),
      state: state
    }

    'https://accounts.spotify.com/authorize?' + query_hash.to_query
  end

  def request_tokens(auth_code, host)
    query_hash = {
      grant_type: 'authorization_code',
      code: auth_code,
      redirect_uri: redirect_uri(host),
      client_id: @client_id,
      client_secret: @client_secret
    }

    self.class.post('/api/token', query: query_hash)
  end

  def request_token_refresh(refresh_token)
    query_hash = {
      grant_type: "refresh_token",
      refresh_token: refresh_token
    }

    self.class.post("/api/token", query: query_hash, headers: { "Authorization" => auth_header })
  end

  private

  def redirect_uri(host)
    host << ":3000" if host == "localhost"
    "http://#{host}/callback/"
  end

  def auth_header
    "Basic " + Base64.strict_encode64(@client_id + ":" + @client_secret)
  end
end
