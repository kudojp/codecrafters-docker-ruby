require 'json'
require 'net/http'

class ImageFetcher
  REGISTRY_HOST = "registry.hub.docker.com".freeze
  OFFICIAL_LIBRARY_REPOS = ["ubuntu", "alpine", "busybox"].freeze

  def initialize(repo, tag)
    repo = "library/#{repo}" if OFFICIAL_LIBRARY_REPOS.include? repo

    @repo = repo
    @tag = tag
  end

  def layers
    amd_manifest_digest = self.manifest_list[0]["digest"] # arch = amd # TODO: fix with filtering
    self.image_layers(amd_manifest_digest).each_with_object([]) do |layer, layers|
      layers << self.image_layer(layer["digest"])
    end
  end

  private

  # Return value is formatted like:
  # [{"digest":"sha256:2fdb1cf4995abb74c035e5f520c0f3a46f12b3377a59e86ecca66d8606ad64f9","mediaType":"application/vnd.oci.image.manifest.v1+json","platform":{"architecture":"amd64","os":"linux"},"size":424},{"digest":"sha256:c80ed91cdc47229010c4f34f96c3442bc02dca260d0bf26f6c4b047ea7d11cf2","mediaType":"application/vnd.oci.image.manifest.v1+json","platform":{"architecture":"arm","os":"linux","variant":"v7"},"size":424},{"digest":"sha256:77bdd217935d10f0e753ed84118e9b11d3ab0a66a82bdf322087354ccd833733","mediaType":"application/vnd.oci.image.manifest.v1+json","platform":{"architecture":"arm64","os":"linux","variant":"v8"},"size":424},{"digest":"sha256:268686ba2c6284461cae1642d9d055e51b16f8e711d49b34638146b78050f5a0","mediaType":"application/vnd.oci.image.manifest.v1+json","platform":{"architecture":"ppc64le","os":"linux"},"size":424},{"digest":"sha256:b0b966f885ea29d809d03d027c3d21182676380b241c3a271aa83f8e9d7bac06","mediaType":"application/vnd.oci.image.manifest.v1+json","platform":{"architecture":"s390x","os":"linux"},"size":424}]
  def manifest_list()
    # ref. https://docs.docker.com/registry/spec/api/#pulling-an-image-manifest
    url = URI("https://#{REGISTRY_HOST}/v2/#{@repo}/manifests/#{@tag}")
    token = get_bearer_token(url)

    response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new url
      req['Authorization'] = "Bearer #{token}"
      req["Accept"] = "application/vnd.oci.image.index.v1+json"
      http.request req
    end

    JSON.load(response.body)["manifests"]
  end

  # Return value is formatted like:
  # [{"mediaType"=>"application/vnd.oci.image.layer.v1.tar+gzip", "size"=>29534702, "digest"=>"sha256:837dd4791cdc6f670708c3a570b72169263806d7ccc2783173b9e88f94878271"}]
  def image_layers(manifest_digest)
    # ref. https://docs.docker.com/registry/spec/api/#pulling-an-image-manifest
    url = URI("https://#{REGISTRY_HOST}/v2/#{@repo}/manifests/#{manifest_digest}")
    token = get_bearer_token(url)

    response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new url
      req['Authorization'] = "Bearer #{token}"
      req["Accept"] = "application/vnd.oci.image.manifest.v1+json"
      http.request req
    end

    puts puts response.body
    JSON.load(response.body)["layers"]
  end

  def image_layer(layer_digest)
    url = URI("https://#{REGISTRY_HOST}/v2/#{@repo}/blobs/#{layer_digest}")
    token = get_bearer_token(url)

    response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new url
      req['Authorization'] = "Bearer #{token}"
      req["Accept"] = "application/vnd.oci.image.layer.v1.tar+gzip"
      http.request req
    end

    # The endpoint may issue a 307 (302 for <HTTP 1.1) redirect to another service for downloading the layer and clients should be prepared to handle redirects.
    if (response.is_a? Net::HTTPRedirection)
      response = self.redirect_for_image_layer(response['location'], response['location'])
    end

    puts response.header.to_hash
    response.body
  end

  def redirect_for_image_layer(url, redirect_limit=5)
    raise StandardError.new("Reached the redirect limit.") if redirect_limit == 0 
    url = URI(url)

    response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new url
      # Seems like Authorization and Accept headers is not necessary when redirection.
      http.request req
    end

    if response.is_a? Net::HTTPRedirection
      response = self.redirect_for_image_layer(response['location'], redirect_limit-1)
    end

    response
  end

  def get_bearer_token(url)
    response = Net::HTTP.get_response(url)
    realm, service, scope = (response.header["Www-Authenticate"] || response.header["www-Authenticate"]).split(" ")[1].split(",")
    realm = realm.split("=")[1][1...][...-1]        # "https://auth.docker.io/token"
    service = service.split("=")[1][1...][...-1]    # "registry.docker.io"
    scope = scope.split("=")[1][1...][...-1]        # e.g. "repository:library/ubuntu:pull"

    auth_url = "#{realm}?service=#{URI.encode_www_form_component(service)}&scope=#{URI.encode_www_form_component(scope)}" # "https://hub.docker.com/v2/library/ubuntu/tags/list"
    response = Net::HTTP.get_response(URI.parse(auth_url))
    token = JSON.parse(response.body)["token"]
    token
  end
end