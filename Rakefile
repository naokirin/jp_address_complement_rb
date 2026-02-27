# frozen_string_literal: true

require 'bundler/gem_tasks'
load 'lib/tasks/jp_address_complement.rake'
task default: %i[]

# RBS 型定義の生成（research.md §5, FR-005）
# steep/rbs:generate は Rails 不要のため :environment 依存にしない（Rails/RakeEnvironment 除外理由）
namespace :rbs do
  desc 'rbs-inline で sig/ を生成する'
  task generate: [] do
    sh 'bundle exec rbs-inline --output sig/ lib/'
  end
end

# 型チェック（research.md §5, FR-006）
task steep: [] do
  sh 'bundle exec steep check'
end
