# == Schema Information
#
# Table name: questionnaires
#
#  id         :uuid             not null, primary key
#  user_id    :uuid
#  question   :string
#  options    :json
#  choice     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  no         :string
#

class Questionnaire < ApplicationRecord
  belongs_to :user
end
