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

  has_many :questionnaires, ->{ limit(5).order(created_at: :desc)}

  before_create {
    self.account = "bf_#{(0..9).to_a.shuffle[0..6].join}"
    self.password = "#{Pinyin.t(name, splitter: '')}#{cert_no.last(6)}"
    self.payload = {registry:{}, login:{}, question:{}}
  }


  def build_kba_params
    questionnaires.reverse.map.with_index do |qst, i|
      {
      "kbaList[#{i}].derivativecode" => payload['question']['derivativecode'],
      "kbaList[#{i}].businesstype" => payload['question']['businesstype'],
      "kbaList[#{i}].kbanum" => payload['question']['kbanum'],
      "kbaList[#{i}].questionno" => qst.no,
      "kbaList[#{i}].question" => qst.question.encode('GBK'),
      "kbaList[#{i}].options1" => qst.options[0].encode('GBK'),
      "kbaList[#{i}].options2" => qst.options[1].encode('GBK'),
      "kbaList[#{i}].options3" => qst.options[2].encode('GBK'),
      "kbaList[#{i}].options4" => qst.options[3].encode('GBK'),
      "kbaList[#{i}].options5" => qst.options[4].encode('GBK'),
      "kbaList[#{i}].answerresult" => qst.choice,
      "kbaList[#{i}].options"  => qst.choice
      }
    end
  end

end
