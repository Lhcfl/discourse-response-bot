# frozen_string_literal: true

DiscourseEvent.on(:post_created) do |*params|
  if SiteSetting.dicourse_response_bot_plugin_enabled
    # Get params of post you created.
    post, opt, user = params

    bot = DiscourseResponseBot.getBot()

    if user.id != bot.id && post.raw
      to_response = "@#{bot.username&.downcase}"

      slice_p = post.raw.downcase.index to_response

      cmds = post.raw[slice_p + to_response.length + 1..]

      # varibles
      @values = {}

      def calc(data = "")
        data&.gsub(/{[\s\S]+?\}/) { |b| @values[b[1..-2]] }
      end

      cmdList = cmds.split(" ")

      settingList = SiteSetting.dicourse_response_bot_plugin_bot_command_variables?.split("|")

      # combine cmd and settings
      [cmdList.size, settingList.size].min.times do |i|
        str, exprs = cmdList[i], settingList[i].split(",")
        @values["%s"] = str

        exprs.each do |expr|
          # Ternary operator
          matched =
            expr.match /([a-zA-Z]+[0-9a-zA-Z]*)=([\s\S]*?)==([\s\S]*?)\?([\s\S]*?):([\s\S]*)/
          if matched
            @values[matched[1]] = (
              if calc(matched[2]) == calc(matched[3])
                calc(matched[4])
              else
                calc(matched[5])
              end
            )
          else
            matched = expr.match /([a-zA-Z]+[0-9a-zA-Z]*)=([\s\S]*)/
            @values[matched[1]] = calc(matched[2])
          end
        end
      end

      DiscourseResponseBot.botSendPost(
        post.topic_id,
        calc(SiteSetting.dicourse_response_bot_plugin_bot_response?),
        reply_to_post_number: post.post_number,
        # import_mode: true,
        skip_validations: true,
      )
    end
  end
end
