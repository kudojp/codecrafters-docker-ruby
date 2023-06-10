require "open3"
require "fileutils"

docker_command = ARGV[0]
image_tag = ARGV[1]
command_line = ARGV[2...]

if docker_command != 'run'
  $stderr.puts "Currently only 'mydocker run' is supported"
  exit 1
end

FileUtils.mkdir_p("/app/root_dir/usr/local/bin")
FileUtils.cp("/usr/local/bin/docker-explorer", "/app/root_dir/usr/local/bin/docker-explorer")

stdout, stderr, status = Open3.capture3("chroot", "/app/root_dir", *command_line)
$stdout.puts stdout
$stderr.puts stderr
exit status.exitstatus
