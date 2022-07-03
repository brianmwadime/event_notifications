require_dependency 'mailer'
module EventNotification
  module Patches
    module MailerPatch
      unloadable

      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.instance_eval do
          alias_method :attachments_added_without_events, :attachments_added
          alias_method :attachments_added, :attachments_added_with_events

          alias_method :old_mail, :mail

          define_method(:mail) do |headers={}, &block|
            # Add a display name to the From field if Setting.mail_from does not
            # include it
            begin
              mail_from = Mail::Address.new(Setting.mail_from)
              if mail_from.display_name.blank? && mail_from.comments.blank?
                mail_from.display_name =
                  @author&.logged? ? @author.name : Setting.app_title
              end
              from = mail_from.format
              list_id = "<#{mail_from.address.to_s.tr('@', '.')}>"
            rescue Mail::Field::IncompleteParseError
              # Use Setting.mail_from as it is if Mail::Address cannot parse it
              # (probably the emission address is not RFC compliant)
              from = Setting.mail_from.to_s
              list_id = "<#{from.tr('@', '.')}>"
            end

            headers.reverse_merge! 'X-Mailer' => 'Redmine',
                    'X-Redmine-Host' => Setting.host_name,
                    'X-Redmine-Site' => Setting.app_title,
                    'X-Auto-Response-Suppress' => 'All',
                    'Auto-Submitted' => 'auto-generated',
                    'From' => from,
                    'List-Id' => list_id

            # Replaces users with their email addresses
            [:to, :cc, :bcc].each do |key|
              if headers[key].present?
                headers[key] = self.class.email_addresses(headers[key])
              end
            end

            # Removes the author from the recipients and cc
            # if the author does not want to receive notifications
            # about what the author do
            if @author&.logged? && @author.pref.no_self_notified
              addresses = @author.mails
              headers[:to] -= addresses if headers[:to].is_a?(Array)
              headers[:cc] -= addresses if headers[:cc].is_a?(Array)
            end

            if @author&.logged?
              redmine_headers 'Sender' => @author.login
            end

            # Blind carbon copy recipients
            if Setting.bcc_recipients?
              headers[:bcc] = [headers[:to], headers[:cc]].flatten.uniq.reject(&:blank?)
              headers[:to] = nil
              headers[:cc] = nil
            end

            if @message_id_object
              headers[:message_id] = "<#{self.class.message_id_for(@message_id_object, @user)}>"
            end
            if @references_objects
              headers[:references] = @references_objects.collect {|o| "<#{self.class.references_for(o, @user)}>"}.join(' ')
            end

            if block_given?
              super headers, &block
            else
              super headers do |format|
                format.text
                format.html unless Setting.plain_text_mail?
              end
            end
          end
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def attachments_added_with_events(attachments)
          if Setting.plugin_event_notifications["enable_event_notifications"] == "on"
            container = attachments.first.container
            added_to = ''
            added_to_url = ''
            @author = attachments.first.author
            case container.class.name
              when 'Project'
                added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container)
                added_to = "#{l(:label_project)}: #{container}"
                recipients = container.project.notified_users(container).select {|user| user.allowed_to?(:view_files, container.project)}.collect  {|u| u.mail}
              when 'Version'
                added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container.project)
                added_to = "#{l(:label_version)}: #{container.name}"
                recipients = container.project.notified_users(container).select {|user| user.allowed_to?(:view_files, container.project)}.collect  {|u| u.mail}
              when 'Document'
                added_to_url = url_for(:controller => 'documents', :action => 'show', :id => container.id)
                added_to = "#{l(:label_document)}: #{container.title}"
                recipients = container.notified_users
            end
            redmine_headers 'Project' => container.project.identifier
            @attachments = attachments
            @added_to = added_to
            @added_to_url = added_to_url
            mail :to => recipients,
                 :subject => "[#{container.project.name}] #{l(:label_attachment_new)}"
          else
            attachments_added_without_events(attachments)
          end
        end

        def redmine_from
          return Setting.mail_from if @author.nil?
          case Setting.plugin_event_notifications["event_notifications_with_author"]
            when "author"
              "\"#{@author.name} [REDMINE]\" <#{@author.mail}>"
            when "authorname"
              "\"#{@author.name} [REDMINE]\" <#{Setting.mail_from.sub(/.*?</, '').gsub(">", "")}>"
            else
              Setting.mail_from
          end
        end

        def quality_tree_comment_added(comment,users,subject="")
          news = comment.commented
          redmine_headers 'Project' => news.project.identifier
          @author = comment.author
          message_id comment
          references news
          @news = news
          @comment = comment
          if comment.commented.is_a?(Issue)
            @news_url = url_for(:controller => 'issues', :action => 'show', :id => news)
          else
            @news_url = url_for(:controller => 'news', :action => 'show', :id => news)
          end
          mail :to => users.map(&:mail),
               :subject => "[#{news.project.name}] #{subject}: #{comment.author} mentioned you in a note."
        end

        def quality_tree_comment_notifiers(comment,users,subject="")
          news = comment.commented
          redmine_headers 'Project' => news.project.identifier
          @author = comment.author
          message_id comment
          references news
          @news = news
          @comment = comment
          if comment.commented.is_a?(Issue)
            @news_url = url_for(:controller => 'issues', :action => 'show', :id => news)
          elsif comment.commented.is_a?(News)
            @news_url = url_for(:controller => 'news', :action => 'show', :id => news)
          else
            @news_url = signin_path
          end
          mail :bcc => users.map(&:mail),
               :subject => "[#{news.project.name}] #{subject}: #{comment.author} added a note."
        end

        def watcher_added(watcher, current_user)
          @watcher = watcher
          @watchable = watcher.watchable
          @current_user = current_user
          if @watchable.respond_to?(:project)
            @project = @watchable.project
            redmine_headers 'Project' => @watchable.project.identifier
          end

          message_id @watchable
          references @watchable

          @watchable_url = if @watchable.is_a?(Issue)
                             url_for(:controller => 'issues', :action => 'show', :id => @watchable)
                           else
                             # @watchable_url = polymorphic_path(watcher)
                             nil
                           end

          mail :to => [@watcher.user.mail],
               :subject => l(:label_watcher_mailer, author: @current_user, watcher: @watcher.user)
        end
      end
    end
  end
end

Rails.configuration.to_prepare do
  Mailer.send(:include, EventNotification::Patches::MailerPatch)
end