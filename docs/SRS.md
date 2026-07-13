# Software Requirements Specification (SRS)
# AI Character Video Generation Platform

Version: 1.0

## 1. Purpose

This document describes the functional, technical and implementation requirements for building an AI-powered video generation platform.

This SRS complements `requirements.md` and is intended to guide an implementation agent (such as Claude Code) through the complete project.

The project will be implemented in two major phases.

---

# Phase 1 (Primary Deliverable)

## Goal

Deliver a production-ready web platform consisting of:

- Ruby on Rails API
- PostgreSQL
- Redis
- Sidekiq
- React User Portal
- React Admin Portal

The platform must be deployable to production.

Users must be able to:

- Register
- Create projects
- Generate exactly one animated character using Gemini
- Approve that character
- Create unlimited videos under the project
- Speak or type a video idea
- Generate prompts using OpenAI
- Generate videos through Google Labs
- Download generated videos

---

# Phase 2

Build Flutter (preferred) or React Native applications using the APIs from Phase 1.

The applications must be production-ready and suitable for Google Play Store and Apple App Store submission.

---

# System Architecture

Client Layer
- React User Portal
- React Admin Portal
- Flutter Mobile Apps (Phase 2)

Backend
- Ruby on Rails API
- Sidekiq Workers
- PostgreSQL
- Redis

External Services
- OpenAI API
- Google Gemini API
- Google Labs
- Email Provider
- Object Storage (S3 compatible)

---

# High-Level Domain Model

User
 └── Projects
      ├── One Character
      ├── Many Videos
      │      ├── Prompt
      │      ├── Video Jobs
      │      └── Assets
      └── Audit History

Rules

- One project owns exactly one character.
- One character belongs to exactly one project.
- One project contains many videos.
- Each video owns its own prompt.
- Every generated video always uses the project's approved character.

---

# Epic 1 — Foundation Platform

## Deliverables

Implement:

- Rails project
- React project
- Authentication
- Roles
- Database
- Background jobs
- Storage abstraction
- AI provider abstraction
- Email abstraction
- Logging
- Configuration

Definition of Done

- User can register
- User can login
- Admin exists
- API authentication works
- React communicates with API
- Sidekiq operational
- Production configuration documented

---

# Epic 2 — Project Management

## Deliverables

Implement complete project lifecycle.

Capabilities

- Create project
- Edit project
- Archive project
- Delete draft project
- View dashboard
- Search projects
- Pagination
- Status management

Rules

Project initialization is incomplete until the character has been approved.

Definition of Done

Project lifecycle works end-to-end.

---

# Epic 3 — Character Initialization

Implement the one-time project character generation flow.

Workflow

Create Project

↓

Generate Gemini prompt

↓

Generate character image

↓

Store image

↓

Send approval email

↓

Approve

↓

Lock character

Requirements

- Exactly one approved character
- Reject/regenerate before approval
- Immutable after approval (except admin)

Definition of Done

Approved character automatically becomes the reference image for all future videos.

---

# Epic 4 — Video Workspace

Each project contains unlimited videos.

Each video stores

- title
- idea
- transcript
- prompt
- outputs
- generation history

Video workflow

Create Video

↓

Speak or type idea

↓

Speech-to-text

↓

OpenAI prompt generation

↓

User edits prompt

↓

Generate

Definition of Done

Multiple videos can coexist under one project.

---

# Epic 5 — Prompt Generation

Provider

OpenAI

Responsibilities

- Prompt generation
- Prompt refinement
- Translation
- Dialogue enhancement

The system must support prompt version history.

Definition of Done

Each video has an approved prompt.

---

# Epic 6 — Video Generation

Provider

Google Labs

Workflow

Approved Character

+

Prompt

↓

Google Labs

↓

Generate

↓

Download

↓

Store

↓

Notify

Rules

Always attach project character.

Generate

- two 3:4
- two 9:16

15 seconds only.

Definition of Done

Four downloadable videos exist for every generation request.

---

# Epic 7 — User Portal

Major modules

Dashboard

Projects

Project Details

Videos

Prompt Editor

Generation Status

Downloads

Account

Notifications

Responsive on desktop and tablet.

---

# Epic 8 — Admin Portal

Modules

Dashboard

Users

Projects

Characters

Videos

Generation Jobs

Retry Queue

Emails

Providers

Usage Dashboard

Audit Logs

Settings

Definition of Done

Administrator can manage the entire platform without database access.

---

# Epic 9 — Background Processing

Implement Sidekiq jobs for

Prompt generation

Character generation

Speech transcription

Video generation

Download

Storage

Email

Retries

Cleanup

Jobs must be idempotent.

---

# Epic 10 — Cost Tracking

Track

OpenAI

Gemini

Google Labs

Store

- provider
- request id
- cost estimate
- tokens (OpenAI)
- generation duration
- project
- user

Admin dashboard must display

Daily spend

Monthly spend

Average cost/video

Average cost/project

---

# Epic 11 — Observability

Implement

Structured logging

Health endpoint

Job metrics

Provider metrics

Error reporting

Audit logs

---

# Epic 12 — Mobile Phase

Flutter application

Modules

Authentication

Dashboard

Projects

Character Approval

Videos

Recorder

Prompt Editor

Downloads

Profile

Notifications

Definition of Done

Application is ready for Play Store and App Store publication.

---

# Non Functional Requirements

Security

Performance

Scalability

Accessibility

Monitoring

Backups

Secrets Management

CDN-ready asset delivery

---

# Release Milestones

Milestone 1

Backend foundation

Milestone 2

Authentication

Milestone 3

Projects

Milestone 4

Gemini character generation

Milestone 5

Email approval

Milestone 6

Video workspace

Milestone 7

OpenAI prompt generation

Milestone 8

Google Labs integration

Milestone 9

Downloads

Milestone 10

Admin portal

Milestone 11

Cost dashboard

Milestone 12

Production deployment

Milestone 13

Flutter apps

Milestone 14

Store publication

---

# Acceptance Criteria

A project is considered successful when:

1. User creates a project.
2. Gemini generates exactly one character.
3. User approves the character.
4. User creates multiple videos.
5. User speaks or types an idea.
6. OpenAI generates a prompt.
7. User edits if desired.
8. Google Labs generates four outputs.
9. Videos are stored.
10. User receives completion email.
11. User downloads videos.

No step should require manual copying or pasting between AI providers.

The platform orchestrates the entire workflow automatically.
