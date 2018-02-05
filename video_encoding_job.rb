class VideoEncodingJob < ActiveJob::Base
  queue_as :default

  def perform(video)
    file_path = video.video.file.file
    filename = video.video.file.filename
    movie = FFMPEG::Movie.new(file_path)
    movie_bitrate = movie.metadata[:streams].first[:bit_rate].to_i / 1000
    movie_frame_rate = movie.frame_rate.to_i
    frame_rate = movie_frame_rate < 25 ? movie_frame_rate : 25
    bitrate = movie_bitrate < 500 ? movie_bitrate : 500
    buf_size = bitrate * 2
    encoded_video_path = "#{Rails.root}/public/uploads/video/video/#{video.id}/encode_#{filename}"
    system("ffmpeg -i '#{file_path}' -codec:v libx264 -vf format=yuv420p -profile:v baseline -level 3.0 -preset slow -movflags +faststart -b:v '#{bitrate}'k -bufsize '#{buf_size}'k -r '#{frame_rate}' -threads 0 '#{encoded_video_path}'")

    video.video = Pathname.new(encoded_video_path).open
    File.delete(encoded_video_path) if File.exist?(encoded_video_path)
    video.save!
  end
end

