require "open3"

docker_command = ARGV[0]
image_tag = ARGV[1]
command = ARGV[2]
command_args = ARGV[3...]

if docker_command != 'run'
  $stderr.puts "Currently only 'mydocker run' is supported"
  exit 1
end

stdout, stderr, status = Open3.capture3("chroot", "./root_dir", command, *command_args)
$stdout.puts stdout
$stderr.puts stderr
exit status.exitstatus
