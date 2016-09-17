class AddNoToQuestionnaire < ActiveRecord::Migration[5.0]
  def change
    add_column :questionnaires, :no, :string, comment: '问题编号'
  end
end
