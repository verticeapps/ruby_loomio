module PollNotificationEvent
  private
  #TODO: there are some discussion dependencies that will need to be resolved here

  def notification_recipients
    if announcement
      announcement_notification_recipients
    else
      specified_notification_recipients
    end
  end

  def announcement_notification_recipients
    Queries::UsersByVolumeQuery.loud(eventable.discussion)
  end

  def specified_notification_recipients
    Queries::UsersToMentionQuery.for(eventable)
  end

  def email_recipients
    if announcement
      announcement_email_recipients
    else
      specified_email_recipients
    end
  end

  def announcement_email_recipients
    Queries::UsersByVolumeQuery.normal_or_loud(eventable.discussion)
  end

  def specified_email_recipients
    notification_recipients.where(email_when_mentioned: true)
  end

  def mailer
    PollMailer
  end
end