class JobLogDetail < ApplicationRecord
  belongs_to :job_log

  validates :message, presence: true, length: { maximum: 5000 }

  default_scope { order(created_at: :asc) }
end
