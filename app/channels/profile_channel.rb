# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class ProfileChannel < ApplicationCable::Channel

  def subscribed
    if current_user.present?
      stream_from "profile_channel_#{current_user.id}"
    else
      current_user = find_verified_user
      stream_from "profile_channel_#{current_user.id}"
    end
  end

  def unsubscribed
    stop_all_streams
  end

  def update(data)
    response = MemberProfile.update(data, current_user)
    ProfileJob.perform_later response, current_user.id
  end
  
  def update_user_location(data)
    response = MemberProfile.update_user_location(data, current_user)
    ProfileJob.perform_later response, current_user.id
  end
  
  def reset_password(data)
    response = User.reset_password(data, current_user)
    ProfileJob.perform_later response, current_user.id
  end

  def logout(data)
    response = User.log_out(data, current_user)
    ProfileJob.perform_later response, current_user.id
  end

  def event_create(data)
    response, event_id = Event.event_create(data, current_user)
    ProfileJob.perform_later response, current_user.id
    if event_id != 0
      Event.event_sync_to_members(event_id, current_user)
    end
  end

  def show_event(data)
    response = Event.show_event(data, current_user)
    ProfileJob.perform_later response, current_user.id
  end
  
  def follow_member(data)
    response, is_accepted = MemberFollowing.follow_member(data, current_user)
    ProfileJob.perform_later response, current_user.id
    if is_accepted
      response = Post.newly_created_posts(current_user)
      PostJob.perform_later response, current_user.id
    end
  end
  
  # def get_following_requests(data)
  #   response = MemberFollowing.get_following_requests(data, current_user)
  #   ProfileJob.perform_later response, current_user.id
  # end
  
  def unfollow_member(data)
    response = MemberFollowing.unfollow_member(data, current_user)
    ProfileJob.perform_later response, current_user.id
  end

  def accept_reject_follower(data)
    response, status, member_following = MemberFollowing.accept_reject_follower(data, current_user)
    ProfileJob.perform_later response, current_user.id
    # if status == 1 && member_following.following_status == 'accepted'
      # MemberFollowing.member_following_notification(member_following, current_user, true)
    # end
  end

  def get_following_members(data)
    response = MemberFollowing.get_following_members(data, current_user)
    ProfileJob.perform_later response, current_user.id
  end
  

  protected
  def find_verified_user
    user_session = UserSession.find_by_auth_token(params[:auth_token])

    if user_session.present?
      user_session.user
    else
      reject_unauthorized_connection
    end
  end
end
