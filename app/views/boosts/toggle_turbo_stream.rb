# frozen_string_literal: true

class Views::Boosts::ToggleTurboStream < Views::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::TurboStream

  def initialize(boostable:)
    @boostable = boostable
  end

  def view_template
    turbo_stream.replace(dom_id(@boostable, :boost)) do
      render Components::Boosts::Button.new(boostable: @boostable)
    end
  end
end
