namespace :assets do
  desc "Cleans and copies working asset files into /public prefixed with a cache-busting token"
  task :precompile do
    p ""
    p "[[  Cleaning and recompiling assets...  ]]"
    p ""

    FileUtils.rm_rf("public")
    FileUtils.mkdir("public")

    # BEGIN Cache-busting
    cache_busting_token = Time.now.to_i.to_s

    File.write("public/cache_busting_token", cache_busting_token)

    # We'll assume only one level of asset directories for now.
    Dir.glob("assets/*").each do |assets_glob|
      Dir.glob(assets_glob).each do |glob|
        dir = glob.split("/")[1]
        FileUtils.mkdir_p "public/#{dir}"
        Dir.glob(glob + "/*").each do |filepath|
          next if File.directory?(filepath)
          filename = filepath.split("/").last
          file_data =
            File
              .read(filepath)
              .gsub("~~~CACHE_BUSTING_TOKEN~~~", cache_busting_token)
          File.write("public/#{dir}/#{cache_busting_token}_#{filename}", file_data)
        end
      end
    end
    # END Cache-busting

    p ""
    p "[[  Recompilation complete!  ]]"
    p ""
  end
end
