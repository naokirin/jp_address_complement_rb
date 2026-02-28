class CreateJpAddressComplementPostalCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :jp_address_complement_postal_codes do |t|
      t.string :postal_code,      limit: 7,   null: false
      t.string :pref_code,        limit: 2,   null: false
      t.string :pref,             limit: 10,  null: false
      t.string :city,             limit: 50,  null: false
      t.string :town,             limit: 100
      t.string :kana_pref,        limit: 20
      t.string :kana_city,        limit: 100
      t.string :kana_town,        limit: 200
      t.boolean :has_alias,       default: false, null: false
      t.boolean :is_partial,      default: false, null: false
      t.boolean :is_large_office, default: false, null: false
      t.integer :version, default: 0, null: false
      t.timestamps
    end

    add_index :jp_address_complement_postal_codes, :postal_code,
              name: 'idx_jp_address_complement_postal_code'

    # 同一の郵便番号・都道府県・市区町村・町域（漢字）でも読み（カナ）が異なれば別レコードとする
    reversible do |dir|
      dir.up do
        unique_index_columns = if connection.adapter_name =~ /mysql/i
          "(postal_code, pref_code, city, (COALESCE(town,'')), (COALESCE(kana_pref,'')), (COALESCE(kana_city,'')), (COALESCE(kana_town,'')))"
        else
          "(postal_code, pref_code, city, COALESCE(town,''), COALESCE(kana_pref,''), COALESCE(kana_city,''), COALESCE(kana_town,''))"
        end
        execute <<-SQL.squish
          CREATE UNIQUE INDEX idx_jp_address_complement_unique
          ON jp_address_complement_postal_codes
          #{unique_index_columns}
        SQL
      end
      dir.down do
        remove_index :jp_address_complement_postal_codes, name: 'idx_jp_address_complement_unique'
      end
    end

    add_index :jp_address_complement_postal_codes, :version,
              name: 'idx_jp_address_complement_version'
  end
end
