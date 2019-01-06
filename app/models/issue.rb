class Issue < ApplicationRecord

  include AASM

  attr_accessor :account_id, :project_id

  has_many :issue_events

  before_create :set_issue_number
  after_create :set_reporter_encrypted_id
  after_create :set_project_encrypted_id

  aasm do
    state :submitted, initial: true
    state :acknowledged, before_enter: Proc.new { |args| log_event(args) }
    state :dismissed, before_enter: Proc.new { |args| log_event(args) }
    state :resolved, before_enter: Proc.new { |args| log_event(args) }
    state :reopened, before_enter: Proc.new { |args| log_event(args) }

    event :acknowledge do
      transitions from: :submitted, to: :acknowledged
    end

    event :dismiss do
      transitions from: [:acknowledged, :reopened], to: :dismissed
    end

    event :resolve do
      transitions from: [:acknowledged, :reopened], to: :resolved
    end

    event :reopen do
      transitions from: [:dismissed, :resolved], to: :reopened
    end

  end

  def reporter
    @reporter ||= Account.find(EncryptionService.decrypt(self.reporter_encrypted_id))
  end

  def project
    @project ||= Project.find(EncryptionService.decrypt(self.project_encrypted_id))
  end

  private

  def set_issue_number
    result = Issue.connection.execute("SELECT nextval('issues_issue_number_seq')")
    self.issue_number = result[0]['nextval']
  end

  def set_reporter_encrypted_id
    update_attribute(:reporter_encrypted_id, EncryptionService.encrypt(self.account_id))
    reporter.issues_encrypted_ids << EncryptionService.encrypt(self.id)
    reporter.save
  end

  def set_project_encrypted_id
    update_attribute(:project_encrypted_id, EncryptionService.encrypt(self.project_id))
    project.issues_encrypted_ids << EncryptionService.encrypt(self.id)
    project.save
  end

  def log_event(args)
    IssueEvent.create(
      issue_id: self.id,
      actor_id: args[:account_id],
      event: "State: #{aasm.to_state}"
    )
  end

end
