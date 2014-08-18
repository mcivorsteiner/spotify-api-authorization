class SpotifyClient
  include HTTParty
  base_uri 'https://api.spotify.com'

  attr_accessor :access_token

  def initialize(args = {})
    @access_token = args[:access_token]
  end

  def request(path, options = {})
    response = self.class.get(path, options)
    JSON.parse(response.body)
  end

  def get_profile_data
    request('/v1/me', headers: { "Authorization" => "Bearer #{@access_token}" })
  end

  def get_user_tracks
    tracks = { "items" => [] }
    path = "/v1/me/tracks"

    while path
      response = request(path, headers: { "Authorization" => "Bearer #{@access_token}" }, query: { "limit" => 50 })
      tracks["items"].concat(response.delete("items"))
      tracks.merge!(response)
      path = response["next"] ? response["next"].gsub("https://api.spotify.com", "") : nil
    end

    tracks
  end

  def get_user_artists
    tracks = get_user_tracks
    aggregate_artists(tracks)
  end

  private

  def aggregate_artists(tracks)
    top_artists = {}
    artist_cache = {}
    tracks["items"].each do |item|
      artist = item["track"]["artists"].first
      unless top_artists.has_key?(artist["uri"])
        top_artists[artist["uri"]] = 0
        artist_cache[artist["uri"]] = artist
      end
      top_artists[artist["uri"]] += 1
    end
    { top_artists: top_artists, artist_cache: artist_cache }
  end
end