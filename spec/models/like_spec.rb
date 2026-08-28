# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Like, type: :model do
  set_fixture_class fedipub_actors: Fedipub::Actor
  fixtures :users, :articles, :sites, :fedipub_actors

  describe '.for_actor' do
    let(:actor) { fedipub_actors(:john_actor) }
    let(:other_actor) { fedipub_actors(:jane_actor) }
    let(:article) { articles(:ruby_article) }
    let(:other_article) { articles(:similar_article) }

    it 'returns Article/Post likes belonging to the given actor, newest first' do
      older = Like.create!(actor: actor, likeable: other_article, created_at: 2.days.ago)
      newer = Like.create!(actor: actor, likeable: article, created_at: 1.day.ago)

      expect(Like.for_actor(actor)).to eq([ newer, older ])
    end

    it 'excludes likes from other actors' do
      mine = Like.create!(actor: actor, likeable: article)
      Like.create!(actor: other_actor, likeable: other_article)

      expect(Like.for_actor(actor)).to eq([ mine ])
    end

    it 'returns none when actor is nil' do
      Like.create!(actor: actor, likeable: article)

      expect(Like.for_actor(nil)).to be_empty
    end
  end
end
