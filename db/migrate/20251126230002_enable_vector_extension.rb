class EnableVectorExtension < ActiveRecord::Migration[7.1]
  def up
    enable_extension "vector" unless extension_enabled?("vector")

    create_table :facial_profiles, id: :uuid do |t|
      t.string :image_path
      t.references :student, null: false, foreign_key: { on_update: :cascade, on_delete: :cascade }, type: :uuid
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE facial_profiles 
      ADD COLUMN embedding vector(512);
    SQL

    execute <<-SQL
      CREATE INDEX index_facial_profiles_on_embedding 
      ON facial_profiles 
      USING ivfflat (embedding vector_l2_ops)
      WITH (lists = 100);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX IF EXISTS index_facial_profiles_on_embedding;
    SQL

    execute <<-SQL
      ALTER TABLE facial_profiles DROP COLUMN IF EXISTS embedding;
    SQL

    drop_table :facial_profiles

    disable_extension "vector" if extension_enabled?("vector")
  end
end