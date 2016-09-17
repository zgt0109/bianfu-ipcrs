module IpcrsLogin
  extend ActiveSupport::Concern

  # @TODO: 用户模拟模拟登录,获取数据
  included do

    def ipcrs_login_bootstrap
      url = 'https://ipcrs.pbccrc.org.cn/login.do?method=initLogin'
      headers = {
        'Host'        => 'ipcrs.pbccrc.org.cn',
        'User-Agent'  => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36',
        'Referer'     => 'https://ipcrs.pbccrc.org.cn/top1.do'
      }
      response        = RestClient::Request.execute(method: 'get', url: url, :headers => headers, :verify_ssl=> false)
      response.cookie_jar.save(ipcrs_cookie_file, :session => true)
      payload['login']['csrf_login'] = response.body.match(/value=.*([a-z0-9]{32})/)[1]
      save
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
      payload['login']['image'] = response['pic_str'].downcase
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
        'org.apache.struts.taglib.html.TOKEN' => payload['login']['csrf_login'],
        'method' => 'login',
        'date' => (Time.now.to_f*1000).to_i,
        'loginname' => account,
        'password' => password,
        '_@IMGRC@_' => payload['login']['image'],
      }
      response = RestClient::Request.execute(method: 'post', url: url, :payload => params, :headers => headers, :verify_ssl=> false)
      if response.body.encode('UTF-8').match('验证码输入错误')
        self.state = 'failed_login_image'
        save
      end
      if response.body.encode('UTF-8').match('您可以通过以下步骤获取信用报告')
        self.state = 'login'
        save
      end

    end

    # 申请信用报告
    def ipcrs_login_report
      url = 'https://ipcrs.pbccrc.org.cn/reportAction.do?method=applicationReport'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/menu.do',
        'Cookie'    =>  ipcrs_cookie
      }
      response = RestClient::Request.execute(method: 'get', url: url, :headers => headers, :verify_ssl=> false)
      payload['login']['csrf_report'] = response.body.match(/value=.*([a-z0-9]{32})/)[1]
      save
    end

    # 选择问题验证
    def ipcrs_login_question
      ipcrs_login_bootstrap
      ipcrs_login_captcha_image
      ipcrs_login
      ipcrs_login_report
      url = 'https://ipcrs.pbccrc.org.cn/reportAction.do'
      headers = {
        'Host'      => 'ipcrs.pbccrc.org.cn',
        'Referer'   => 'https://ipcrs.pbccrc.org.cn/menu.do',
        'Cookie'    =>  ipcrs_cookie
      }
      params = {
        'org.apache.struts.taglib.html.TOKEN' => payload['login']['csrf_report'],
        'method' => 'checkishasreport',
        'authtype'=> 2,
        'ApplicationOption' => 25,
        'ApplicationOption' => 24,
        'ApplicationOption' => 21,
      }
      response = RestClient::Request.execute(method: 'post', url: url, :payload => params, :headers => headers, :verify_ssl=> false)

      body = response.body.encode('UTF-8')
      payload['question']['derivativecode'] = body.match(/value="(\w{27}=)"/)[1]
      payload['question']['businesstype']   = body.match(/businesstype.*?value="(\d*)"/m)[1]
      payload['question']['kbanum']         = body.match(/kbanum.*?value="(\d*)"/m)[1]

      questionno  = body.scan(/questionno.*?value="(\d*)"/m).flatten
      question    = body.scan(/question[^no]*?value="(.*?)"/m).flatten.map{|opt| opt.squeeze}
      options     = body.scan(/options\d+.*?value="(.*?)"/m).flatten.map{|opt| opt.squeeze}


      questionno.map.with_index do |no, i|
        questionnaires.build(no: no, question: question[i], options: options.slice(i*5, 5))
      end
      state = 'pending-question'
      save
    end
  end
end
