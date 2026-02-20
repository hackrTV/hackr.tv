module Api
  module Admin
    class HackrLogsController < BaseController
      # GET /api/admin/hackr_logs
      def index
        page = [params[:page].to_i, 1].max
        per_page = params[:per_page].to_i
        per_page = 25 if per_page <= 0
        per_page = [per_page, 100].min

        logs = HackrLog.includes(:grid_hackr).ordered
        total = logs.count
        logs = logs.limit(per_page).offset((page - 1) * per_page)

        render json: {
          success: true,
          hackr_logs: logs.map { |log| log_json(log) },
          meta: {
            total: total,
            page: page,
            per_page: per_page,
            total_pages: (total.to_f / per_page).ceil
          }
        }
      end

      # POST /api/admin/hackr_logs
      def create
        slug = generate_unique_slug(params[:title])
        published = params.fetch(:published, true)
        published = ActiveModel::Type::Boolean.new.cast(published)

        log = HackrLog.new(
          grid_hackr: @current_admin_hackr,
          title: params[:title],
          slug: slug,
          body: params[:body],
          published: published,
          published_at: published ? Time.current : nil
        )

        if log.save
          render json: {
            success: true,
            message: "Hackr log created",
            hackr_log: log_json(log)
          }, status: :created
        else
          render json: {
            success: false,
            error: log.errors.full_messages.join(", ")
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/admin/hackr_logs/:slug
      def update
        log = HackrLog.find_by(slug: params[:slug])
        unless log
          return render json: {success: false, error: "Hackr log not found"}, status: :not_found
        end

        # Handle publish/unpublish toggling
        if params.key?(:published)
          should_publish = ActiveModel::Type::Boolean.new.cast(params[:published])
          if should_publish && !log.published?
            log.publish!
          elsif !should_publish && log.published?
            log.unpublish!
          end
        end

        # Update other fields if provided
        attrs = {}
        attrs[:title] = params[:title] if params.key?(:title)
        attrs[:body] = params[:body] if params.key?(:body)

        if attrs.any?
          unless log.update(attrs)
            return render json: {
              success: false,
              error: log.errors.full_messages.join(", ")
            }, status: :unprocessable_entity
          end
        end

        render json: {
          success: true,
          message: "Hackr log updated",
          hackr_log: log_json(log.reload)
        }
      end

      private

      def generate_unique_slug(title)
        base_slug = title.to_s.parameterize
        slug = base_slug
        counter = 1

        while HackrLog.exists?(slug: slug)
          slug = "#{base_slug}-#{counter}"
          counter += 1
        end

        slug
      end

      def log_json(log)
        {
          id: log.id,
          title: log.title,
          slug: log.slug,
          body: log.body,
          published: log.published,
          published_at: log.published_at&.iso8601,
          grid_hackr: {
            id: log.grid_hackr.id,
            hackr_alias: log.grid_hackr.hackr_alias
          },
          created_at: log.created_at.iso8601,
          updated_at: log.updated_at.iso8601
        }
      end
    end
  end
end
