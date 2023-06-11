require "open3"
require "fileutils"
require "./app/base_image_reproducer"

docker_command = ARGV[0]
image_tag = ARGV[1]
command_line = ARGV[2...]
# command_line[0] is assumed to be `/usr/local/bin/docker-explorer`

repo, tag = image_tag.split(":", 2)
tag ||= "latest"

root_dir = "/app/root_dir"

FileUtils.mkdir_p(root_dir) # This is used as the root directory of the container
BaseImageReproducer.new(repo, tag, root_dir).reproduce!

if docker_command != 'run'
  $stderr.puts "Currently only 'mydocker run' is supported"
  exit 1
end


FileUtils.mkdir_p("/app/root_dir/usr/local/bin")
FileUtils.cp("/usr/local/bin/docker-explorer", "/app/root_dir/usr/local/bin/docker-explorer")

# ref. https://blog.amedama.jp/entry/linux-pid-namespace_1
unshare_command_line = ["unshare", "--pid", "--fork", "--mount-proc"]
chmod_command_line = ["chroot", "/app/root_dir"]

stdout, stderr, status = Open3.capture3(*unshare_command_line, *chmod_command_line, *command_line)
$stdout.puts stdout
$stderr.puts stderr
exit status.exitstatus
