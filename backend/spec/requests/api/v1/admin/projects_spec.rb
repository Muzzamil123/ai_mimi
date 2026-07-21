require "rails_helper"

RSpec.describe "Admin Projects API", type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/projects"

  describe "GET /api/v1/admin/projects" do
    it "lists every user's projects with filters" do
      create(:project, :ready)
      draft = create(:project)

      get "/api/v1/admin/projects", params: { status: "draft" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["projects"].map { |p| p["id"] }
      expect(ids).to contain_exactly(draft.id)
    end
  end

  describe "GET /api/v1/admin/projects/:id" do
    it "returns a full inspection payload" do
      project = create(:project, :ready)
      character = create(:character, :approved, project: project)
      project.update!(active_character_id: character.id)
      create(:video, :with_idea, project: project)

      get "/api/v1/admin/projects/#{project.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["project"]["id"]).to eq(project.id)
      expect(body["owner"]["email"]).to eq(project.user.email)
      expect(body["character"]["id"]).to eq(character.id)
      expect(body["videos"].size).to eq(1)
    end
  end

  describe "POST /api/v1/admin/projects/:id/archive" do
    it "archives the project and audits it" do
      project = create(:project, :ready)

      expect {
        post "/api/v1/admin/projects/#{project.id}/archive", headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)

      expect(project.reload).to be_archived
      expect(AuditLog.last.action).to eq("project.archive")
    end
  end

  describe "POST /api/v1/admin/projects/:id/reset_character" do
    it "resets the approved character with a reason and audits it" do
      project = create(:project, :ready)
      character = create(:character, :approved, project: project)
      project.update!(active_character_id: character.id)

      expect {
        post "/api/v1/admin/projects/#{project.id}/reset_character",
             params: { reason: "off-brand" }, headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(character.reload).to be_pending
      log = AuditLog.last
      expect(log.action).to eq("character.reset")
      expect(log.metadata["reason"]).to eq("off-brand")
    end

    it "returns 422 when the project has no character" do
      project = create(:project)
      post "/api/v1/admin/projects/#{project.id}/reset_character", headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/admin/projects/:id/retry_character" do
    it "restarts generation for a failed character and audits it" do
      project = create(:project, status: :failed)
      character = create(:character, :failed, project: project)

      expect {
        post "/api/v1/admin/projects/#{project.id}/retry_character", headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)
        .and have_enqueued_job(GenerateCharacterPromptJob)

      expect(response).to have_http_status(:ok)
      expect(character.reload).to be_generating
      expect(AuditLog.last.action).to eq("character.retry_generation")
    end
  end
end
