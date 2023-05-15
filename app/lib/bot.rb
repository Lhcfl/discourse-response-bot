# frozen_string_literal: true

module DiscourseResponseBot
  def DiscourseResponseBot.create_bot(id, admin: false, username: "Chartbot")
    User.new.tap do |user|
      user.id = id
      user.email = "user#{SecureRandom.hex}@localhost#{SecureRandom.hex}.fake"
      user.username = username || "user#{SecureRandom.hex}"
      user.password = SecureRandom.hex
      user.username_lower = user.username.downcase
      user.active = true
      user.approved = true
      user.save!
      user.grant_admin! if admin
      user.change_trust_level!(TrustLevel[4])
      user.activate
    end
  end

  def DiscourseResponseBot.getBot()
    User.find_by(id: SiteSetting.dicourse_response_bot_plugin_bot_id?) ||
      DiscourseResponseBot.create_bot(SiteSetting.dicourse_response_bot_plugin_bot_id?)
  end

  def DiscourseResponseBot.botSendPost(topic_id, rawText, **opts)
    PostCreator.create!(
      getBot,
      topic_id: topic_id,
      raw: rawText,
      guardian: Guardian.new(Discourse.system_user),
      **opts,
    )
  end

  def DiscourseResponseBot.botParseCmd(text, handles)
    return nil if text.length > 100
    text = text.strip
    slice_p = text.index " "
    handles[text[...slice_p]&.downcase]&.call(text[slice_p..].lstrip)
  end
end
