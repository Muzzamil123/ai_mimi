module Projects
  # Creates a project owned by the given user and records the initial status.
  # Raises ActiveRecord::RecordInvalid on validation failure.
  class CreateProject < ApplicationService
    def initialize(user, params)
      @user = user
      @params = params
    end

    MAX_SLUG_ATTEMPTS = 3

    def call
      project = @user.projects.new(@params)
      attempts = 0

      begin
        Project.transaction do
          project.save!
          project.status_changes.create!(from_status: nil, to_status: project.status, actor: @user)
        end
      rescue ActiveRecord::RecordNotUnique
        # Lost a race on the [user_id, slug] unique index — recompute and retry.
        raise if (attempts += 1) > MAX_SLUG_ATTEMPTS

        project.slug = nil
        retry
      end

      project
    end
  end
end
