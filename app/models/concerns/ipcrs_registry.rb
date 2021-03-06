module IpcrsRegistry
  extend ActiveSupport::Concern


  included do

    def ipcrs_registry_bootstrap
      url = 'https://ipcrs.pbccrc.org.cn/userReg.do?method=initReg'
      headers = {
        'Host'        => 'ipcrs.pbccrc.org.cn',
        'Referer'     => 'https://ipcrs.pbccrc.org.cn/top1.do',
        'User-Agent'  => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36'
      }
      response        = RestClient::Request.execute(method: 'get', url: url, :headers => headers, :verify_ssl=> false)
      response.cookie_jar.save(ipcrs_cookie_file, :session => true)
      payload['csrf_identity'] = response.body.match(/value=.*([a-z0-9]{32})/)[1]
      save
    end

    # 图片验证码解析
    def ipcrs_registry_captcha_image
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
     payload[:image] = response['pic_str'].downcase
     save
    end


    # 检查用户是否注册
    def ipcrs_registry_identity
      url = 'https://ipcrs.pbccrc.org.cn/userReg.do'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/userReg.do?method=initReg',
        'Cookie'    =>  ipcrs_cookie
      }
      params = {
        'org.apache.struts.taglib.html.TOKEN' => payload['csrf_identity'],
        'method' => 'checkIdentity',
        'userInfoVO.name' => name.encode('GBK'),
        'userInfoVO.certType' => 0,
        'userInfoVO.certNo' => cert_no,
        '_@IMGRC@_' => payload['image'],
        '1' => 'on'
      }
      response = RestClient::Request.execute(method: 'post', url: url, :payload => params, :headers => headers, :verify_ssl=> false)
      if response.body.encode('UTF-8').match('您已注册过用户')
        self.state = 'failed_registered'
        save
      else
        payload['csrf_reg']    = response.body.match(/value=.*([a-z0-9]{32})/)[1]
        save
      end
    end


    # 发送短信验证码
    def ipcrs_registry_captcha_mobile
      url = 'https://ipcrs.pbccrc.org.cn/userReg.do'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/userReg.do',
        'Cookie'    =>  ipcrs_cookie
      }
      params = {
        'method'=>'getAcvitaveCode',
        'mobileTel' => self.mobile
      }
      response = RestClient::Request.execute(method: 'post', url: url, :payload => params, :headers => headers, :verify_ssl=> false)
      payload['tcid'] = response.to_s
      save
    end

    # 用户注册

    def ipcrs_registry
      url = 'https://ipcrs.pbccrc.org.cn/userReg.do'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/userReg.do',
        'Cookie'    =>  ipcrs_cookie
      }
      params = {
        'org.apache.struts.taglib.html.TOKEN' => payload['csrf_reg'],
        'method' => 'saveUser',
        'counttime' => '',
        'tcId' => payload['tcid'],
        'userInfoVO.loginName' => account,
        'userInfoVO.password' => password,
        'userInfoVO.confirmpassword' => password,
        'userInfoVO.email' => '',
        'userInfoVO.mobileTel' => mobile,
        'userInfoVO.verifyCode' => payload['mobile']
      }
      response = RestClient::Request.execute(method: 'post', url: url, :payload => params, :headers => headers, :verify_ssl=> false)

      # @todo: 该登录名已存在
      if response.body.encode('UTF-8').match('您在个人信用信息平台已注册成功')
        self.state = 'registered'
        save
      end

      # @TODO: 参数错误302 待处理
      # @TODO: 用户名已经存在
      if response.body.encode('UTF-8').match('此手机号码已注册')
        self.state = 'failed_mobile_exist'
        save
      end
    end
  end
end
