# frozen_string_literal: true

DiscourseEvent.on(:post_created) do |*params|
  if SiteSetting.dicourse_response_bot_plugin_enabled

    # Get params of post you created.
    post, opt, user = params

    bot = DiscourseResponseBot.getBot()

    DiscourseResponseBot.botParseCmd(
      post.raw,
      {
        # Handle post like `@bot cmd1 cmd2 cmd3`
        "@#{bot.username&.downcase}" => ->(cmds) do

          guardian = Guardian.new(user)

          # varibles
          @values = {}

          def calc(data = "")
            data&.gsub(/{[\s\S]+?\}/) do |b|
              @values[b[1..-2]]
            end
          end
          
          cmdList = cmds.split(' ')

          settingList = SiteSetting.dicourse_response_bot_plugin_bot_command_variables?.split('|')
          
          # combine cmd and settings
          [cmdList.size, settingList.size].min.times do |i|
            str, exprs = cmdList[i], settingList[i].split(',')
            @values['%s'] = str

            exprs.each do |expr|
              # Ternary operator
              matched = expr.match /([a-zA-Z]+[0-9a-zA-Z]*)=([\s\S]*?)==([\s\S]*?)\?([\s\S]*?):([\s\S]*)/
              if matched
                @values[matched[1]] = calc(matched[2]) == calc(matched[3]) ? calc(matched[4]) : calc(matched[5])
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

        end,
      },
    # BOT SHOULD NOT HANDLE ITSELF
    ) if user.id != bot.id
  end
end
