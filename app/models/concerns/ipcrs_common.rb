module IpcrsCommon
  extend ActiveSupport::Concern

  included do
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
