class UsersController < ApplicationController
  
  def show
    @user = User.find(params[:id])
    spotify_client = Spotify::Client.new(access_token: session[:access_token])
    @artists = spotify_client.get_user_artists
  end

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
      session.clear
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
        spotify_client = Spotify::Client.new(access_token: token_data["access_token"])
        profile_data = spotify_client.get_profile_data
        if @user = User.find_by_spotify_user_id(profile_data["id"])
          @user.update_attributes( refresh_token: token_data["refresh_token"])
        else
          @user = User.create( spotify_user_id: profile_data["id"], refresh_token: token_data["refresh_token"])
        end
        session[:id] = @user.id
        session[:access_token] = token_data["access_token"]
        redirect_to @user
      end
    else
      redirect_to root
    end
  end

end