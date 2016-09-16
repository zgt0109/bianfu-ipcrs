class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users, id: :uuid, comment: '央行征信注册信息' do |t|
      t.string :name, comment: '姓名'
      t.string :cert_no, comment: '证件号码'
      t.string :mobile, comment: '手机号码'
      t.string :account, comment: '登录帐号'
      t.string :password, comment: '登录密码'
      t.string :state, comment: '状态'

      t.timestamps
    end
    add_index :users, :state
  end
end
