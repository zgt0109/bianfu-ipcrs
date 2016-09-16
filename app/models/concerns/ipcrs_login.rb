module IpcrsLogin
  extend ActiveSupport::Concern

  # @TODO: 用户模拟模拟登录,获取数据
  included do

    def ipcrs_login_bootstrap
      url = 'https://ipcrs.pbccrc.org.cn/page/login/loginreg.jsp'
      headers = {
        'Host'        => 'ipcrs.pbccrc.org.cn',
        'User-Agent'  => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36'
      }
      response        = RestClient::Request.execute(method: 'get', url: url, :headers => headers, :verify_ssl=> false)
      response.cookie_jar.save(ipcrs_cookie_file, :session => true)
    end
    # 图片验证码解析
    def ipcrs_login_captcha_image
      url = 'https://ipcrs.pbccrc.org.cn/imgrc.do'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/page/login/loginreg.jsp',
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
      payload[:image_login] = response['pic_str'].downcase
      save
    end


    # 用户登录

    def ipcrs_login
      url = 'https://ipcrs.pbccrc.org.cn/login.do'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/page/login/loginreg.jsp',
        'Cookie'    =>  ipcrs_cookie
      }
      params = {
        'method' => 'login',
        'date' => (Time.now.to_f*1000).to_i,
        'loginname' => account,
        'password' => password,
        '_@IMGRC@_' => payload['image_login'],
      }
      response = RestClient::Request.execute(method: 'post', url: url, :payload => params, :headers => headers, :verify_ssl=> false)
    end

    # 设置安全等级
    def ipcrs_login_safe
      url = 'https://ipcrs.pbccrc.org.cn/setSafetyLevel.do'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/setSafetyLevel.do?method=index&isnew=true',
        'Cookie'    =>  ipcrs_cookie
      }
      params = {
        'method' => 'setSafetyLevelStep2',
      }
      response = RestClient::Request.execute(method: 'post', url: url, :payload => params, :headers => headers, :verify_ssl=> false)
      payload['csrf_safe'] = response.body.match(/value=.*([a-z0-9]{32})/)[1]
      save
    end

    # 选择问题验证
    def ipcrs_login_question
      url = 'https://ipcrs.pbccrc.org.cn/setSafetyLevel.do'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/setSafetyLevel.do',
        'Cookie'    =>  ipcrs_cookie
      }
      params = {
        'org.apache.struts.taglib.html.TOKEN' => payload['csrf_safe'],
        'method'    => 'chooseCertify',
        'authtype' => '2'
      }
      response = RestClient::Request.execute(method: 'post', url: url, :payload => params, :headers => headers, :verify_ssl=> false)
      if response.body.encode('UTF-8').match('目前系统尚未收录足够的信息对您的身份进行')
        self.state = 'failed_uninfo'
        save
      end
    end
  end
end
