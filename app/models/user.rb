# == Schema Information
#
# Table name: users
#
#  id         :uuid             not null, primary key
#  name       :string
#  cert_no    :string
#  mobile     :string
#  account    :string
#  password   :string
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  payload    :json
#
# Indexes
#
#  index_users_on_state  (state)
#

class User < ApplicationRecord
  include Ipcrs

  before_create {
    self.account = "#{Pinyin.t(name, splitter: '')}#{cert_no.last(6)}"
    self.password = "#{Pinyin.t(name, splitter: '')}#{cert_no.last(6)}"
    self.payload = {}
  }
end
