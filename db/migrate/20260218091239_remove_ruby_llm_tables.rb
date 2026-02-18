class RemoveRubyLlmTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :ruby_llm_agents_execution_details
    drop_table :ruby_llm_agents_executions
  end
end
