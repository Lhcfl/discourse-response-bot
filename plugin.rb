# frozen_string_literal: true

# name: discourse-response-bot
# about: Auto response with bot
# version: 0.0.1
# authors: Lhc_fl
# url: https://github.com/Lhcfl/discourse-response-bot
# required_version: 3.0.0

enabled_site_setting :dicourse_response_bot_plugin_enabled

require_relative "app/lib/bot.rb"

after_initialize do
  %w[app/lib/bot.rb app/lib/dicourse_response_bot_plugin_handle_new_posts.rb].each do |f|
    load File.expand_path("../#{f}", __FILE__)
  end
end
