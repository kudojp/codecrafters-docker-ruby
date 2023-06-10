require "open3"

docker_command = ARGV[0]
image_tag = ARGV[1]
command = ARGV[2]
command_args = ARGV[3...]

return if docker_command != 'run'

stdout, stderr, status = Open3.capture3(command, *command_args)
$stdout.puts stdout
$stderr.puts stderr
exit status.exitstatus
