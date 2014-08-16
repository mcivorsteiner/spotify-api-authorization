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
end