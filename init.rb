require 'redmine'

require_relative './lib/event_notification/patches/users_helper_patch'
require_relative './lib/event_notification/patches/user_patch'
require_relative './lib/event_notification/patches/project_patch'
require_relative './lib/event_notification/patches/member_patch'
require_relative './lib/event_notification/patches/issue_patch'
require_relative './lib/event_notification/patches/document_patch'
require_relative './lib/event_notification/patches/journal_patch'
require_relative './lib/event_notification/patches/message_patch'
require_relative './lib/event_notification/patches/wiki_content_patch'
require_relative './lib/event_notification/patches/watchers_controller_patch'
require_relative './lib/event_notification/patches/groups_controller_patch'
require_relative './lib/event_notification/patches/principal_memberships_controller_patch'
require_relative './lib/event_notification/patches/user_preference_patch'
require_relative './lib/event_notification/patches/custom_field_patch'
require_relative './lib/event_notification/patches/news_patch'
require_relative './lib/event_notification/patches/watcher_patch'

require_relative './lib/event_notification/patches/mailer_patch'

Rails.configuration.to_prepare do
  require_dependency 'event_notification/hooks/event_notification_hook_listener'
  require_relative './lib/event_notification/patches/acts_as_watchable_patch'
end

# Rails.application.config.after_initialize do
#   Redmine::Acts::Watchable::InstanceMethods.send(:include, EventNotification::Patches::ActsAsWatchablePatch)
#   CustomField.send(:include, EventNotification::Patches::CustomFieldPatch)
#   Document.send(:include, EventNotification::Patches::DocumentPatch)
#   GroupsController.send(:include, EventNotification::Patches::GroupsControllerPatch)
#   Issue.send(:include, EventNotification::Patches::IssuePatch)
#   Journal.send(:include, EventNotification::Patches::JournalPatch)
#   Mailer.send(:include, EventNotification::Patches::MailerPatch)
#   Member.send(:include, EventNotification::Patches::MemberPatch)
#   Message.send(:include, EventNotification::Patches::MessagePatch)
#   News.send(:include, EventNotification::Patches::NewsPatch)
#   PrincipalMembershipsController.send(:include, EventNotification::Patches::PrincipalMembershipsControllerPatch)
#   Project.send(:include, EventNotification::Patches::ProjectPatch)
#   User.send(:include, EventNotification::Patches::UserPatch)
#   UserPreference.send(:include, EventNotification::Patches::UserPreferencePatch)
#   UsersHelper.send(:include, EventNotification::Patches::UsersHelperPatch)
#   Watcher.send(:include, EventNotification::Patches::WatcherPatch)
#   WatchersController.send(:include, EventNotification::Patches::WatchersControllerPatch)
#   WikiContent.send(:include, EventNotification::Patches::WikiContentPatch)
#   # unless GroupsHelper.included_modules.include?(RedmineAutoAssignGroup::GroupsHelperPatch)
#   #   GroupsHelper.send(:prepend, RedmineAutoAssignGroup::GroupsHelperPatch)
#   # end
# end

Redmine::Plugin.register :event_notifications do
  name 'Event Notifications plugin'
  author 'Rupesh J'
  description 'Customizes redmine project notification settings for every project event.'
  version '2.4.1'
  author_url 'mailto:rupeshj@esi-group.com'

  settings :default => {
    'enable_event_notifications'        => false,
    'issue_cf_notifications'            => [],
    'issue_category_notifications'      => [],
    'issue_involved_in_related_notified'=> nil,
    'issue_relation_attachment_notified'=> false,
    'event_notifications_with_author'   => false,
    'enable_watcher_notification'       => 0},
  	:partial => 'settings/event_notifications_settings'
end
