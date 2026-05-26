# frozen_string_literal: true

Tailmix::Engine.routes.draw do
  get "definitions", to: "definitions#show", as: :definitions
end
