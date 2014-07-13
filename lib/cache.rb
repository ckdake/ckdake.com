require 'digest/md5'

$cache_dir = './tmp/custom_cache/'

def cache_fetch(cache, &block)
  Dir.mkdir($cache_dir) unless File.exists? $cache_dir

  file = Digest::MD5.hexdigest(cache)
  file_path = File.join($cache_dir, file)
  if !File.exists? file_path
    File.open(file_path, "w") do |data|
      data.write(Marshal.dump(yield block))
    end
  end
  Marshal.load(File.open(File.join($cache_dir, file)).read)
end
