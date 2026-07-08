class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  rescue_from StandardError, with: :handle_unexpected_error

  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  rescue_from ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordNotUnique,
              with: :handle_record_write_failure

  private
    def handle_record_not_found
      redirect_to root_path, alert: "The page you were looking for doesn't exist."
    end

    def handle_record_write_failure
      redirect_to (request.referer || root_path), alert: "Something went wrong and your change couldn't be saved. Please try again."
    end

    def handle_unexpected_error(exception)
      Rails.logger.error("Unexpected error: #{exception.class}: #{exception.message}\n#{Array(exception.backtrace).first(10).join("\n")}")

      if request.referer.present?
        redirect_to request.referer, allow_other_host: false, alert: "Something went wrong. Please try again."
      else
        render file: Rails.public_path.join("500.html"), status: :internal_server_error, layout: false
      end
    end
end
