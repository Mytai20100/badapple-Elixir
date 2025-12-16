defmodule BadApple do
  @ascii_chars ' .:-=+*#%@'
  @width 80
  @height 40

  def download_video(url) do
    IO.puts("Downloading video...")
    System.cmd("yt-dlp", ["-f", "worst", "-o", "badapple.mp4", url])
  end

  def rgb_to_ascii(r, g, b) do
    brightness = div(r + g + b, 3)
    index = div(brightness * (String.length(@ascii_chars) - 1), 255)
    String.at(@ascii_chars, index)
  end

  def extract_and_display_frame(time) do
    cmd = "ffmpeg -ss #{time} -i badapple.mp4 -vframes 1 -vf scale=#{@width}:#{@height} -f rawvideo -pix_fmt rgb24 - 2>/dev/null"
    
    case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true) do
      {pixels, 0} when byte_size(pixels) > 0 ->
        IO.write("\033[2J\033[H")
        
        for y <- 0..(@height - 1) do
          for x <- 0..(@width - 1) do
            idx = (y * @width + x) * 3
            if idx + 2 < byte_size(pixels) do
              <<_::binary-size(idx), r, g, b, _::binary>> = pixels
              IO.write(rgb_to_ascii(r, g, b))
            end
          end
          IO.puts("")
        end
        IO.write(:stdio)
        
      _ -> :ok
    end
  end

  def play(url) do
    download_video(url)
    fps = 10
    duration = 30
    
    Stream.iterate(0, &(&1 + 1.0 / fps))
    |> Stream.take_while(&(&1 < duration))
    |> Enum.each(fn time ->
      extract_and_display_frame(time)
      Process.sleep(trunc(1000 / fps))
    end)
  end
end

url = System.argv() |> List.first() || "https://youtu.be/FtutLA63Cp8"
BadApple.play(url)
