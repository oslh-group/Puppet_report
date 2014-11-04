require 'puppet'
require 'puppet/network/http_pool'
require 'uri'
require 'yaml'

Puppet::Reports.register_report(:cmdb) do

  desc <<-DESC
    Send reports via HTTP or HTTPS. This report processor submits reports as
    POST requests to the address in the `cmdb_reporturl` setting. The body of each POST
    request is the YAML dump of a Puppet::Transaction::Report object, and the
    Content-Type is set as `application/x-yaml`.
  DESC

  $setting_file = 'cmdb_setting.yaml'

  def process
    setting = YAML.load_file($setting_file)
    url = URI.parse(setting[:report_url])
    fact_dir = Pathname(Puppet[:vardir]) + Pathname('yaml/facts')
    headers = { "Content-Type" => "application/x-yaml" }
    options = {}
    fact_file = Pathname(fact_dir) + Pathname("#{self.name}.yaml")
    if not fact_file.exist?
      Puppet.err "Fact file not exist #{fact_file}"
    end
    fact_content = File.read(fact_file)
    conn = Puppet::Network::HttpPool.http_instance(url.host, url.port, false, false)
    response = conn.post(url.path, fact_content, headers, options)
    unless response.kind_of?(Net::HTTPSuccess)
      Puppet.err "Unable to submit report to #{url} [#{response.code}] #{response.msg}"
    end
  end

end
