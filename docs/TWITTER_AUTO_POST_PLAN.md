# Twitter/X Auto-Post Feature Plan

**Status:** Draft
**Created:** 2025-12-16
**Last Updated:** 2025-12-16

## Overview

Implement automatic posting to Twitter/X for key hackr.tv events to increase visibility and engagement. This feature will support opt-in posting for admin actions and include a systematic alerting system for failures.

## Scope

### In Scope (This Project)
1. **Admin Pulses on PulseWire** - Post when an admin sends a Pulse with opt-in checkbox
2. **Hackr Log First Publish** - Post when a Hackr Log is published for the first time with opt-in checkbox
3. **Admin Alerting System** - Notify admins of Twitter post failures and other system events
4. **Rate Limiting/Throttling** - Prevent excessive API calls

### Deferred (Future Project)
- **THE PULSE GRID Events** - New player registrations, achievements, milestones (noted in architecture for future extension)

---

## Architecture

### Component Overview

```
app/
├── jobs/
│   └── twitter_post_job.rb           # Background job for posting tweets
├── services/
│   ├── twitter_service.rb            # Twitter API wrapper
│   └── admin_alert_service.rb        # Centralized admin alerting
├── models/
│   ├── twitter_post.rb               # Audit log of posts/attempts
│   └── admin_alert.rb                # Alert records for admin dashboard
├── controllers/
│   └── admin/
│       └── admin_alerts_controller.rb  # Alert management UI
└── views/
    └── admin/
        └── admin_alerts/             # Alert dashboard views
```

### Database Schema

#### twitter_posts (Audit Log)

Tracks all Twitter post attempts for debugging and analytics.

```ruby
create_table :twitter_posts do |t|
  t.string :postable_type, null: false      # Polymorphic: "Pulse", "HackrLog", etc.
  t.bigint :postable_id, null: false        # ID of the source record
  t.string :tweet_id                         # Twitter's ID (null if failed)
  t.string :status, null: false, default: "pending"  # pending, posted, failed, rate_limited
  t.text :content                            # The tweet content that was/will be posted
  t.text :error_message                      # Error details if failed
  t.integer :retry_count, default: 0         # Number of retry attempts
  t.datetime :posted_at                      # When successfully posted
  t.datetime :last_attempted_at              # Last attempt timestamp
  t.timestamps

  t.index [:postable_type, :postable_id]
  t.index :status
  t.index :created_at
end
```

#### admin_alerts (Alerting System)

Centralized alerting for admins - extensible beyond Twitter failures.

```ruby
create_table :admin_alerts do |t|
  t.string :alert_type, null: false         # twitter_failure, system_error, security, etc.
  t.string :severity, null: false, default: "warning"  # info, warning, error, critical
  t.string :title, null: false              # Short alert title
  t.text :message                           # Detailed message
  t.string :source_type                     # Polymorphic reference to source (optional)
  t.bigint :source_id
  t.boolean :acknowledged, default: false   # Has an admin seen this?
  t.bigint :acknowledged_by_id              # GridHackr who acknowledged
  t.datetime :acknowledged_at
  t.json :metadata                          # Flexible additional data
  t.timestamps

  t.index :alert_type
  t.index :severity
  t.index :acknowledged
  t.index :created_at
end
```

### Model Changes

#### Pulse Model

Add opt-in field and callback:

```ruby
# Migration
add_column :pulses, :post_to_twitter, :boolean, default: false

# app/models/pulse.rb
class Pulse < ApplicationRecord
  after_create_commit :queue_twitter_post, if: :should_post_to_twitter?

  private

  def should_post_to_twitter?
    post_to_twitter? && grid_hackr.admin?
  end

  def queue_twitter_post
    TwitterPostJob.perform_later(self)
  end
end
```

#### HackrLog Model

Add opt-in field and first-publish detection:

```ruby
# Migration
add_column :hackr_logs, :post_to_twitter, :boolean, default: false
add_column :hackr_logs, :twitter_posted_at, :datetime  # Track if already posted

# app/models/hackr_log.rb
class HackrLog < ApplicationRecord
  after_update_commit :queue_twitter_post_on_first_publish

  private

  def queue_twitter_post_on_first_publish
    return unless should_post_to_twitter_on_publish?

    update_column(:twitter_posted_at, Time.current)
    TwitterPostJob.perform_later(self)
  end

  def should_post_to_twitter_on_publish?
    post_to_twitter? &&
      saved_change_to_published? &&
      published? &&
      twitter_posted_at.nil?  # Never posted before
  end
end
```

---

## Services

### TwitterService

Wrapper for Twitter API interactions with built-in rate limiting.

```ruby
# app/services/twitter_service.rb
class TwitterService
  class RateLimitError < StandardError; end
  class ApiError < StandardError; end

  # Rate limit: max 10 tweets per 15-minute window (conservative)
  RATE_LIMIT_WINDOW = 15.minutes
  RATE_LIMIT_MAX = 10

  def initialize
    @client = Twitter::Client.new(
      api_key: Rails.application.credentials.twitter[:api_key],
      api_secret: Rails.application.credentials.twitter[:api_secret],
      access_token: Rails.application.credentials.twitter[:access_token],
      access_token_secret: Rails.application.credentials.twitter[:access_token_secret]
    )
  end

  def post(content)
    check_rate_limit!

    response = @client.tweet(content)
    record_post_attempt

    response
  rescue Twitter::RateLimitError => e
    raise RateLimitError, e.message
  rescue Twitter::Error => e
    raise ApiError, e.message
  end

  def rate_limited?
    recent_count >= RATE_LIMIT_MAX
  end

  private

  def check_rate_limit!
    raise RateLimitError, "Rate limit exceeded" if rate_limited?
  end

  def recent_count
    TwitterPost.where(status: "posted")
               .where("posted_at > ?", RATE_LIMIT_WINDOW.ago)
               .count
  end

  def record_post_attempt
    # Called after successful post for rate tracking
    Rails.cache.increment("twitter_posts_count", 1, expires_in: RATE_LIMIT_WINDOW)
  end
end
```

### AdminAlertService

Centralized service for creating admin alerts.

```ruby
# app/services/admin_alert_service.rb
class AdminAlertService
  ALERT_TYPES = %w[twitter_failure system_error security moderation].freeze
  SEVERITIES = %w[info warning error critical].freeze

  class << self
    def twitter_failure(twitter_post, error_message)
      create_alert(
        alert_type: "twitter_failure",
        severity: "warning",
        title: "Twitter Post Failed",
        message: "Failed to post #{twitter_post.postable_type} ##{twitter_post.postable_id}: #{error_message}",
        source: twitter_post,
        metadata: {
          postable_type: twitter_post.postable_type,
          postable_id: twitter_post.postable_id,
          retry_count: twitter_post.retry_count
        }
      )
    end

    def system_error(title, message, metadata: {})
      create_alert(
        alert_type: "system_error",
        severity: "error",
        title: title,
        message: message,
        metadata: metadata
      )
    end

    # Extensible for future alert types
    def security_alert(title, message, severity: "warning", metadata: {})
      create_alert(
        alert_type: "security",
        severity: severity,
        title: title,
        message: message,
        metadata: metadata
      )
    end

    private

    def create_alert(alert_type:, severity:, title:, message:, source: nil, metadata: {})
      AdminAlert.create!(
        alert_type: alert_type,
        severity: severity,
        title: title,
        message: message,
        source: source,
        metadata: metadata
      )

      # Future: Could broadcast via ActionCable to admin dashboard
      # AdminChannel.broadcast_to("alerts", { type: "new_alert", ... })
    end
  end
end
```

---

## Background Job

### TwitterPostJob

Handles posting with retries and failure alerting.

```ruby
# app/jobs/twitter_post_job.rb
class TwitterPostJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff: 1min, 5min, 30min
  retry_on TwitterService::RateLimitError, wait: :polynomially_longer, attempts: 5
  retry_on TwitterService::ApiError, wait: 1.minute, attempts: 3

  discard_on ActiveRecord::RecordNotFound

  def perform(postable)
    twitter_post = find_or_create_twitter_post(postable)

    return if twitter_post.status == "posted"
    return if skip_due_to_rate_limit?(twitter_post)

    content = generate_content(postable)
    twitter_post.update!(content: content, last_attempted_at: Time.current)

    begin
      response = TwitterService.new.post(content)

      twitter_post.update!(
        status: "posted",
        tweet_id: response.id.to_s,
        posted_at: Time.current
      )
    rescue TwitterService::RateLimitError => e
      handle_rate_limit(twitter_post, e)
      raise # Re-raise to trigger job retry
    rescue TwitterService::ApiError => e
      handle_api_error(twitter_post, e)
      raise # Re-raise to trigger job retry
    end
  end

  private

  def find_or_create_twitter_post(postable)
    TwitterPost.find_or_create_by!(
      postable_type: postable.class.name,
      postable_id: postable.id
    )
  end

  def skip_due_to_rate_limit?(twitter_post)
    if TwitterService.new.rate_limited?
      twitter_post.update!(status: "rate_limited")
      # Re-enqueue for later
      TwitterPostJob.set(wait: 15.minutes).perform_later(twitter_post.postable)
      true
    else
      false
    end
  end

  def generate_content(postable)
    case postable
    when Pulse
      PulseTweetFormatter.new(postable).format
    when HackrLog
      HackrLogTweetFormatter.new(postable).format
    else
      raise ArgumentError, "Unknown postable type: #{postable.class}"
    end
  end

  def handle_rate_limit(twitter_post, error)
    twitter_post.update!(
      status: "rate_limited",
      error_message: error.message,
      retry_count: twitter_post.retry_count + 1
    )
  end

  def handle_api_error(twitter_post, error)
    twitter_post.increment!(:retry_count)
    twitter_post.update!(
      status: "failed",
      error_message: error.message
    )

    # Alert admins after multiple failures
    if twitter_post.retry_count >= 3
      AdminAlertService.twitter_failure(twitter_post, error.message)
    end
  end
end
```

---

## Tweet Formatters

Separate formatter classes for content generation (to be customized later).

```ruby
# app/services/pulse_tweet_formatter.rb
class PulseTweetFormatter
  def initialize(pulse)
    @pulse = pulse
  end

  def format
    # TODO: Customize format
    # Example: "New transmission from @hackr_alias on the WIRE: [content] https://hackr.tv/wire"
    content = truncate_content(@pulse.content, 200)
    "[PULSEWIRE] #{@pulse.grid_hackr.hackr_alias}: #{content} https://hackr.tv/wire"
  end

  private

  def truncate_content(text, max_length)
    return text if text.length <= max_length
    "#{text[0, max_length - 3]}..."
  end
end

# app/services/hackr_log_tweet_formatter.rb
class HackrLogTweetFormatter
  def initialize(hackr_log)
    @hackr_log = hackr_log
  end

  def format
    # TODO: Customize format
    # Example: "New Hackr Log: [title] by @author https://hackr.tv/logs/slug"
    "[HACKR LOG] #{@hackr_log.title} https://hackr.tv/logs/#{@hackr_log.slug}"
  end
end
```

---

## Admin UI Changes

### Pulse Creation Form

Add checkbox to admin Pulse creation (if exists) or API:

```erb
<%# In admin pulse form %>
<% if current_hackr.admin? %>
  <div class="field">
    <%= f.check_box :post_to_twitter %>
    <%= f.label :post_to_twitter, "Post to Twitter/X" %>
  </div>
<% end %>
```

### Hackr Log Form

Add checkbox to admin Hackr Log form:

```erb
<%# app/views/admin/hackr_logs/_form.html.erb %>
<div class="field">
  <%= f.check_box :post_to_twitter %>
  <%= f.label :post_to_twitter, "Post to Twitter/X when published" %>
  <% if @hackr_log.twitter_posted_at.present? %>
    <span class="hint">(Already posted on <%= @hackr_log.twitter_posted_at.strftime("%Y-%m-%d %H:%M") %>)</span>
  <% end %>
</div>
```

### Admin Alerts Dashboard

New admin section for viewing and managing alerts:

**Routes:**
```ruby
# config/routes.rb
namespace :admin do
  # ... existing routes
  resources :admin_alerts, only: [:index, :show] do
    member do
      post :acknowledge
    end
    collection do
      post :acknowledge_all
    end
  end
end
```

**Controller:**
```ruby
# app/controllers/admin/admin_alerts_controller.rb
class Admin::AdminAlertsController < Admin::BaseController
  def index
    @alerts = AdminAlert.order(created_at: :desc)
    @alerts = @alerts.where(acknowledged: false) if params[:unacknowledged]
    @alerts = @alerts.where(severity: params[:severity]) if params[:severity].present?
    @alerts = @alerts.page(params[:page]).per(25)
  end

  def acknowledge
    @alert = AdminAlert.find(params[:id])
    @alert.update!(
      acknowledged: true,
      acknowledged_by: current_hackr,
      acknowledged_at: Time.current
    )
    redirect_to admin_admin_alerts_path, notice: "Alert acknowledged"
  end

  def acknowledge_all
    AdminAlert.where(acknowledged: false).update_all(
      acknowledged: true,
      acknowledged_by_id: current_hackr.id,
      acknowledged_at: Time.current
    )
    redirect_to admin_admin_alerts_path, notice: "All alerts acknowledged"
  end
end
```

---

## Configuration

### Twitter API Credentials

Store in Rails credentials:

```yaml
# config/credentials.yml.enc (decrypted)
twitter:
  api_key: "your_api_key"
  api_secret: "your_api_secret"
  access_token: "your_access_token"
  access_token_secret: "your_access_token_secret"
```

### Feature Toggle (Optional)

```ruby
# config/settings.yml or environment variable
TWITTER_AUTO_POST_ENABLED=true
```

---

## Future Extension: THE PULSE GRID

The architecture supports future Grid event posting:

```ruby
# Future: app/services/grid_tweet_formatter.rb
class GridTweetFormatter
  def initialize(event_type, data)
    @event_type = event_type
    @data = data
  end

  def format
    case @event_type
    when :new_hackr
      "[THE PULSE GRID] A new hackr has jacked in: #{@data[:hackr_alias]} // https://hackr.tv/grid"
    when :milestone
      "[THE PULSE GRID] #{@data[:hackr_alias]} achieved: #{@data[:milestone_name]}"
    # ... more event types
    end
  end
end

# Future: In GridHackr model
after_create_commit :queue_twitter_announcement, if: :should_announce?

def should_announce?
  !admin? && Rails.application.config.twitter_announce_new_hackrs
end
```

---

## Implementation Steps

### Phase 1: Foundation
1. [ ] Add Twitter gem to Gemfile (`gem 'twitter'` or `gem 'x'`)
2. [ ] Create migrations for `twitter_posts` and `admin_alerts` tables
3. [ ] Create `TwitterPost` and `AdminAlert` models
4. [ ] Set up Twitter API credentials in Rails credentials

### Phase 2: Core Services
5. [ ] Implement `TwitterService` with rate limiting
6. [ ] Implement `AdminAlertService`
7. [ ] Implement `TwitterPostJob` background job
8. [ ] Implement tweet formatter classes (placeholder content)

### Phase 3: Pulse Integration
9. [ ] Add `post_to_twitter` column to pulses table
10. [ ] Update Pulse model with callback
11. [ ] Update admin Pulse UI (if applicable) or API params

### Phase 4: Hackr Log Integration
12. [ ] Add `post_to_twitter` and `twitter_posted_at` columns to hackr_logs
13. [ ] Update HackrLog model with first-publish detection
14. [ ] Update admin Hackr Log form with checkbox

### Phase 5: Admin Dashboard
15. [ ] Create AdminAlertsController
16. [ ] Create admin alerts views
17. [ ] Add alerts link to admin navigation
18. [ ] Add unread alert count indicator

### Phase 6: Testing
19. [ ] Write model specs for TwitterPost and AdminAlert
20. [ ] Write service specs for TwitterService and AdminAlertService
21. [ ] Write job specs for TwitterPostJob
22. [ ] Write integration tests for full flow

### Phase 7: Polish
23. [ ] Finalize tweet content formats
24. [ ] Add admin dashboard for viewing Twitter post history
25. [ ] Documentation

---

## Testing Strategy

### Unit Tests
- `TwitterService` rate limiting logic
- `AdminAlertService` alert creation
- Tweet formatter output
- Model validations and callbacks

### Integration Tests
- Full flow: Pulse creation -> job enqueue -> Twitter post
- Full flow: HackrLog publish -> job enqueue -> Twitter post
- Failure scenarios: API errors, rate limits
- Admin alert creation on failures

### Manual Testing
- Verify Twitter API connectivity
- Test with Twitter API sandbox/test environment
- Verify admin alert dashboard functionality

---

## Open Questions

1. **Twitter account** - Which Twitter account will post? Dedicated @hackrtv account?
2. **Tweet content** - Final format for each post type (to be decided later per requirements)
3. **Real-time admin alerts** - Should alerts push via ActionCable to admin dashboard?
4. **Email notifications** - Should critical alerts also email admins?

---

## Dependencies

- `twitter` gem (or `x` gem for X API v2)
- Solid Queue (already in use via Solid Cable) or Sidekiq for background jobs
- Rails credentials for secure API key storage
