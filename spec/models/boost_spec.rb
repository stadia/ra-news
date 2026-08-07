# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Boost, type: :model do
  set_fixture_class federails_actors: Federails::Actor
  fixtures :users, :articles, :sites, :federails_actors

  describe '.for_actor' do
    let(:actor) { federails_actors(:john_actor) }
    let(:other_actor) { federails_actors(:jane_actor) }
    let(:article) { articles(:ruby_article) }
    let(:other_article) { articles(:similar_article) }

    it 'returns Article/Post boosts belonging to the given actor, newest first' do
      older = Boost.create!(actor: actor, boostable: other_article, created_at: 2.days.ago)
      newer = Boost.create!(actor: actor, boostable: article, created_at: 1.day.ago)

      expect(Boost.for_actor(actor)).to eq([ newer, older ])
    end

    it 'excludes boosts from other actors' do
      mine = Boost.create!(actor: actor, boostable: article)
      Boost.create!(actor: other_actor, boostable: other_article)

      expect(Boost.for_actor(actor)).to eq([ mine ])
    end

    it 'returns none when actor is nil' do
      Boost.create!(actor: actor, boostable: article)

      expect(Boost.for_actor(nil)).to be_empty
    end
  end
end
