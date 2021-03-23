
require_relative "lib/wafer.rb"
require "erubis"
require "json"

repo = JSONRepo.new ENV["WAFER_USER_REPO_FILE"]

settings = {}
if ENV["WAFER_SETTINGS_FILE"] && !ENV["WAFER_SETTINGS_FILE"].empty?
  settings = JSON.load File.read(ENV["WAFER_SETTINGS_FILE"])
end
wafer = Wafer::Server.new(repo: repo, settings: settings)

# This runs the CtlD and AuthD servers in a background thread.
# If the settings say so then it also connects to the DGD incoming port to
# replace userdb-authctl.
BACKGROUND_THREAD = Thread.new do
  begin
    puts "Entered the thread..."
    wafer.event_loop
  rescue Exception
        puts "Got exception in thread! Dying! #{$!.inspect}"
        raise
  end
end

RACK_404 = [404, {}, ["File not found!"]]

run (proc do |env|
  path = env['PATH_INFO']
  path = "/index.html" if path == "" || path == "/"

  template_path = File.join(__dir__, "www", path) + ".erb"
  if File.exist?(template_path)
    erb_text = File.read(template_path)
    eruby = Erubis::Eruby.new(erb_text)
    html_text = eruby.result env: env,
      play_port: wafer.settings["dgd"]["portbase"] + 80

    [200, { 'Content' => 'text/html' }, [html_text] ]
  else
    [404, {}, [ "File not found: #{template_path}" ]]
  end

end)
