class UsersController < ApplicationController
  def create
    client_id = ENV['CLIENT_ID']
    client_secret = ENV['CLIENT_SECRET']
    client_callback_url = "http://localhost:3000/callback/"
    # AUTH_HEADER = "Basic " + Base64.strict_encode64(CLIENT_ID + ":" + CLIENT_SECRET)
    # SPOTIFY_ACCOUNTS_ENDPOINT = URI.parse("https://accounts.spotify.com")
    # SPOTIFY_PROFILE_ENDPOINT = URI.parse("https://api.spotify.com")


    state_key = SecureRandom.urlsafe_base64
    session[:spotify_auth_state] = state_key
    scope = "user-read-private user-read-email user-library-read playlist-read-private"
    query_hash = {
      response_type: 'code',
      client_id: client_id,
      scope: scope,
      redirect_uri: client_callback_url,
      state: state_key
    }
    url = 'https://accounts.spotify.com/authorize?' + query_hash.to_query
    redirect_to url
  end

  def callback
    client_callback_url = "http://localhost:3000/callback/"
    client_id = ENV['CLIENT_ID']
    client_secret = ENV['CLIENT_SECRET']
    auth_code = params[:code]
    state = params[:state]

    if state == session[:spotify_auth_state]
      query_hash = {
        code: auth_code,
        redirect_uri: client_callback_url,
        grant_type: 'authorization_code',
        client_id: client_id,
        client_secret: client_secret
      }
      response = HTTParty.post('https://accounts.spotify.com/api/token', query: query_hash)

      if response.code.to_i == 200
        token_data = JSON.parse(response.body)
        profile_data = get_profile_data(token_data["access_token"])

        render json: {token_data: token_data, profile_data: profile_data}
      end
    else
      redirect_to root
    end
  end

  private

  def get_profile_data(access_token)
    spotify_profile_endpoint = URI.parse("https://api.spotify.com")
    
    http = Net::HTTP.new(spotify_profile_endpoint.host, spotify_profile_endpoint.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new("/v1/me")
    request.add_field("Authorization", "Bearer " + access_token)
    response = http.request(request)

    return JSON.parse(response.body)
  end
end