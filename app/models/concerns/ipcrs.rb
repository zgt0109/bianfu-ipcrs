module Ipcrs
  extend ActiveSupport::Concern


  included do
    def ipcrs_bootstrap
      url = 'https://ipcrs.pbccrc.org.cn/userReg.do?method=initReg'
      headers = {
        'Host'        => 'ipcrs.pbccrc.org.cn',
        'Referer'     => 'https://ipcrs.pbccrc.org.cn/top1.do',
        'User-Agent'  => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36'
      }
      response        = RestClient::Request.execute(method: 'get', url: url, :headers => headers, :verify_ssl=> false)
      response.cookie_jar.save(ipcrs_cookie_file, :session => true)
      self.payload = {csrf_identity: response.body.match(/value=.*([a-z0-9]{32})/)[1]}
      save
    end

  private
    def ipcrs_cookie_file
      Rails.root.join('tmp', 'cache', "#{self.id}.cookie").to_s
    end

    def ipcrs_cookie
      jar = HTTP::CookieJar.new
      HTTP::Cookie.cookie_value(jar.load(ipcrs_cookie_file).cookies) if File.exist?(ipcrs_cookie_file)
    end
  end

end
