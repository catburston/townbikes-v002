class Reservation < ActiveRecord::Base
  attr_accessor :current_user

  belongs_to  :bicycle
  belongs_to  :renter ,foreign_key: "user_id", class_name: "User"
  has_one     :location, through: :owner
  has_one     :owner, through: :bicycle, foreign_key: "user_id", class_name: "User"

  validates :bicycle_id, presence: true
  validates :user_id, presence: true
  validates :from_date, presence: true
  validates :to_date, presence: true

  validate :from_date_is_in_future
  validate :from_date_before_to_date

  validates :from_date, :to_date, :overlap => {:scope => "bicycle_id", :message_title => "Reservation dates not possible", :message_content => "Your reservation dates could not be submitted. This bicycle is already booked on those dates.", :exclude_edges => ["from_date", "to_date"]}, :on => :create

  scope :for_user, -> (user) { where("user_id = ? OR bicycle_id IN (?)", user.id, user.bicycles.ids) }


  #custom ActiveRecord validations
  def owner
    bicycle.user
  end

  def self.has_pending(uid)
    pending_reservations = Reservation.where(:bicycle_id => User.find(uid).bicycles.ids, status: 'pending')
    pending_count = pending_reservations.count
    pending_count
  end

  def self.has_upcoming(uid)
    upcoming_reservations = Reservation.where(from_date: (Time.now.midnight)..(Time.now.midnight + 1.week), status: 'approved')
    upcoming_count = upcoming_reservations.count
    upcoming_count
  end

  private

    def from_date_is_in_future
      if from_date == nil
        return
      elsif Date.today > from_date
        errors.add(:from_date, "should be in the future")
      end
    end

    def from_date_before_to_date
      if from_date == nil
        return
      elsif from_date > to_date
        errors.add(:to_date, "should be after its beginning")
      end
    end

end
