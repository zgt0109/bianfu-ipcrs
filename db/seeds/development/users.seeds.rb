[
  {
    name: '丁文娟',
    cert_no: '340621198308075623'
  },

  {
    name: '刘洋',
    cert_no: '370284199003261015'
  },
  {
    name: '马俊丽',
    cert_no: '412728198107241242'
  },
  {
    name: '廖永泽',
    cert_no: '532626198608022530'
  },
  {
    name: '安霞',
    cert_no: '612601197910220624'
  },
].each do|person|
  user = User.new(person.merge(mobile: '13185844143'))
  puts "添加测试用户: #{user.cert_no}(#{user.name})" if user.save
end
