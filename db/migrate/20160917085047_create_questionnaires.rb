class CreateQuestionnaires < ActiveRecord::Migration[5.0]
  def change
    create_table :questionnaires,id: :uuid, comment: '用户问卷' do |t|
      t.uuid :user_id, comment: '关联用户'
      t.string :question, comment: '问题'
      t.json :options, comment: '选择项'
      t.string :choice, comment: '回答'

      t.timestamps
    end
  end
end
