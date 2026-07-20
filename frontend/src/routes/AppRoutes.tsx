import { Route, Routes } from 'react-router-dom'
import { AppLayout } from '../components/layout/AppLayout'
import { AdminUsersPage } from '../pages/admin/AdminUsersPage'
import { ForgotPasswordPage } from '../pages/auth/ForgotPasswordPage'
import { LoginPage } from '../pages/auth/LoginPage'
import { ProfilePage } from '../pages/auth/ProfilePage'
import { RegisterPage } from '../pages/auth/RegisterPage'
import { ResetPasswordPage } from '../pages/auth/ResetPasswordPage'
import { VerifyEmailPage } from '../pages/auth/VerifyEmailPage'
import { HealthPage } from '../pages/HealthPage'
import { NotFoundPage } from '../pages/NotFoundPage'
import { CharacterApprovalPage } from '../pages/approvals/CharacterApprovalPage'
import { CharacterPage } from '../pages/characters/CharacterPage'
import { EditProjectPage } from '../pages/projects/EditProjectPage'
import { NewProjectPage } from '../pages/projects/NewProjectPage'
import { ProjectDetailPage } from '../pages/projects/ProjectDetailPage'
import { ProjectsListPage } from '../pages/projects/ProjectsListPage'
import { NewVideoPage } from '../pages/videos/NewVideoPage'
import { VideoDetailPage } from '../pages/videos/VideoDetailPage'
import { VideosListPage } from '../pages/videos/VideosListPage'
import { PromptWorkspacePage } from '../pages/prompts/PromptWorkspacePage'
import { GenerationWorkspacePage } from '../pages/generations/GenerationWorkspacePage'
import { VideoOutputsPage } from '../pages/outputs/VideoOutputsPage'
import { AdminRoute } from './AdminRoute'
import { ProtectedRoute } from './ProtectedRoute'

export function AppRoutes() {
  return (
    <Routes>
      <Route element={<AppLayout />}>
        <Route index element={<HealthPage />} />

        {/* Public auth routes */}
        <Route path="login" element={<LoginPage />} />
        <Route path="register" element={<RegisterPage />} />
        <Route path="forgot-password" element={<ForgotPasswordPage />} />
        <Route path="reset-password" element={<ResetPasswordPage />} />
        <Route path="verify-email" element={<VerifyEmailPage />} />

        {/* Public, token-protected character approval (reached from email) */}
        <Route path="approvals/character/:token" element={<CharacterApprovalPage />} />

        {/* Authenticated routes */}
        <Route element={<ProtectedRoute />}>
          <Route path="profile" element={<ProfilePage />} />
          <Route path="projects" element={<ProjectsListPage />} />
          <Route path="projects/new" element={<NewProjectPage />} />
          <Route path="projects/:id" element={<ProjectDetailPage />} />
          <Route path="projects/:id/edit" element={<EditProjectPage />} />
          <Route path="projects/:id/character" element={<CharacterPage />} />
          <Route path="projects/:id/videos" element={<VideosListPage />} />
          <Route path="projects/:id/videos/new" element={<NewVideoPage />} />
          <Route path="projects/:id/videos/:videoId" element={<VideoDetailPage />} />
          <Route path="projects/:id/videos/:videoId/prompt" element={<PromptWorkspacePage />} />
          <Route
            path="projects/:id/videos/:videoId/generation"
            element={<GenerationWorkspacePage />}
          />
          <Route path="projects/:id/videos/:videoId/outputs" element={<VideoOutputsPage />} />
        </Route>

        {/* Admin-only routes */}
        <Route element={<AdminRoute />}>
          <Route path="admin/users" element={<AdminUsersPage />} />
        </Route>

        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  )
}
