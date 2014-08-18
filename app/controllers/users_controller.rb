class UsersController < ApplicationController
  
  def show
    @user = User.find(params[:id])
    spotify_client = SpotifyClient.new(access_token: session[:access_token])
    @artists = spotify_client.get_user_artists
  end

  def create
    auth_client = SpotifyAuth.new
    state = SecureRandom.urlsafe_base64
    session[:spotify_auth_state] = state
    redirect_to auth_client.spotify_auth_url(state)
  end

  def callback
    auth_code = params[:code]
    auth_client = SpotifyAuth.new

    if params[:state] == session[:spotify_auth_state]
      session.clear
      response = auth_client.request_tokens(auth_code)

      if response.code.to_i == 200
        token_data = JSON.parse(response.body)
        spotify_client = SpotifyClient.new(access_token: token_data["access_token"])
        profile_data = spotify_client.get_profile_data

        if @user = User.find_by_spotify_user_id(profile_data["id"])
          @user.update_attributes( refresh_token: token_data["refresh_token"])
        else
          @user = User.create( spotify_user_id: profile_data["id"], refresh_token: token_data["refresh_token"])
        end

        session[:user_id] = @user.id
        session[:access_token] = token_data["access_token"]
        redirect_to @user
      end
    else
      redirect_to root
    end
  end

  def refresh
    @user = User.find(session[:user_id])
    auth_client = SpotifyAuth.new
    render json: auth_client.request_token_refresh(@user.refresh_token)
  end
end