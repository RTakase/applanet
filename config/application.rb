# -*- coding: utf-8 -*-
require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Applanet
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    #特徴量の識別子とその日本語表現
    charInfo = Hash.new
    charInfo["title"] = "タイトル"
    charInfo["icongeo"] = "アイコン（形ベース）"
    charInfo["iconcolor"] = "アイコン（色ベース）"
    charInfo["description"] = "説明文"
    charInfo["ratecount"] = "レビュー数"
    charInfo["rateaverage"] = "星の数"
    charInfo["simapps"] = "類似のアプリ"
    config.charInfo = charInfo

    #未実装な部分
    showOnly = Array.new
    showOnly = ["iconcolor", "description", "ratecount", "rateaverage", "simapps"]
    config.showOnly = showOnly


  end
end
