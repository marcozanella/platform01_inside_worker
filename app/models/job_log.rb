class JobLog < ApplicationRecord
  has_many :job_log_details, dependent: :destroy

  enum :status, { pending: 0, processing: 1, error: 2, success: 3 }

  validates :name, presence: true, uniqueness: true,
            format: { with: /\A\d{14}(_\d+)?\z/, message: "must be YYYYMMDDhhmmss format" }
  validates :status, presence: true

  # Create log with collision handling
  def self.create_with_timestamp!(time = Time.current)
    base_name = time.strftime("%Y%m%d%H%M%S")
    suffix = 0

    loop do
      name = suffix.zero? ? base_name : "#{base_name}_#{suffix}"
      begin
        return create!(name: name, status: :pending)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
        if e.is_a?(ActiveRecord::RecordInvalid) && !e.message.include?("has already been taken")
          raise e
        end
        suffix += 1
        raise "Too many collisions" if suffix > 100
      end
    end
  end

  # Helper to add log detail
  def add_detail(message)
    job_log_details.create!(message: message)
  end
end
