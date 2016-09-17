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
  include IpcrsCommon
  include IpcrsRegistry
  include IpcrsLogin

  has_many :questionnaires

  before_create {
    self.account = "bf_#{(0..9).to_a.shuffle[0..6].join}"
    self.password = "#{Pinyin.t(name, splitter: '')}#{cert_no.last(6)}"
    self.payload = {registry:{}, login:{}}
  }


  def add_question
    questionno, question, options = ipcrs_login_question
    question.map.with_index  do|q, index|
      questionnaires.build question: q.squeeze, options: options.slice(index*5,5)
    end
    save
  end


end
