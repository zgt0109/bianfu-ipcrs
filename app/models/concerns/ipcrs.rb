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

    # 图片验证码解析
    def ipcrs_captcha_image
      url = 'https://ipcrs.pbccrc.org.cn/imgrc.do'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/userReg.do?method=initReg',
        'Cookie'    =>  ipcrs_cookie
      }
      headers[:params] = {
        a: (Time.now.to_f*1000).to_i
      }
      response = RestClient::Request.execute(method: 'get', url: url, :headers => headers, :verify_ssl=> false)

      # 超级鹰
      params = {
      	'user'     => '2008futao',
      	'pass'     => '198659',
      	'softid'   => '891709',
      	'codetype' => 5000,
      	'file_base64' => Base64.encode64(response.body)
      }
     response = RestClient.post 'http://upload.chaojiying.net/Upload/Processing.php', params
     response = JSON.parse(response)
     self.payload[:image] = response['pic_str'].downcase
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
