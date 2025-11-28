# Configuração para suporte ao tipo vector do pgvector no Rails
# NOTA: O Rails não consegue fazer dump automático do tipo vector no schema.rb
# A tabela facial_profiles precisa ser adicionada manualmente ao schema.rb
# ou você pode usar a gem 'neighbor' que adiciona suporte completo ao pgvector

# Registra o tipo vector no adapter do PostgreSQL para uso em migrações
if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:vector] = { name: 'vector' }
end


