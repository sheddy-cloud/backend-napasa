const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User reference is required']
  },
  tour: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tour',
    required: [true, 'Tour reference is required']
  },
  participants: {
    adults: {
      type: Number,
      required: [true, 'Number of adults is required'],
      min: [1, 'Must have at least 1 adult'],
      max: [20, 'Cannot exceed 20 adults per booking']
    },
    children: {
      type: Number,
      default: 0,
      min: [0, 'Children count cannot be negative'],
      max: [20, 'Cannot exceed 20 children per booking']
    },
    infants: {
      type: Number,
      default: 0,
      min: [0, 'Infants count cannot be negative'],
      max: [10, 'Cannot exceed 10 infants per booking']
    }
  },
  totalParticipants: {
    type: Number,
    required: true
  },
  startDate: {
    type: Date,
    required: [true, 'Start date is required']
  },
  endDate: {
    type: Date,
    required: [true, 'End date is required']
  },
  totalPrice: {
    type: Number,
    required: [true, 'Total price is required'],
    min: [0, 'Price must be positive']
  },
  currency: {
    type: String,
    default: 'USD',
    enum: ['USD', 'TZS', 'EUR', 'GBP']
  },
  status: {
    type: String,
    enum: {
      values: ['pending', 'confirmed', 'cancelled', 'completed', 'refunded'],
      message: 'Status must be pending, confirmed, cancelled, completed, or refunded'
    },
    default: 'pending'
  },
  paymentStatus: {
    type: String,
    enum: {
      values: ['pending', 'paid', 'failed', 'refunded'],
      message: 'Payment status must be pending, paid, failed, or refunded'
    },
    default: 'pending'
  },
  paymentMethod: {
    type: String,
    enum: ['credit_card', 'bank_transfer', 'mobile_money', 'cash'],
    default: 'credit_card'
  },
  paymentReference: {
    type: String,
    trim: true
  },
  specialRequests: {
    type: String,
    maxlength: [500, 'Special requests cannot exceed 500 characters']
  },
  emergencyContact: {
    name: {
      type: String,
      required: [true, 'Emergency contact name is required']
    },
    phone: {
      type: String,
      required: [true, 'Emergency contact phone is required']
    },
    relationship: {
      type: String,
      required: [true, 'Emergency contact relationship is required']
    }
  },
  cancellationReason: {
    type: String,
    maxlength: [500, 'Cancellation reason cannot exceed 500 characters']
  },
  cancelledAt: {
    type: Date
  },
  refundAmount: {
    type: Number,
    min: [0, 'Refund amount cannot be negative']
  },
  refundedAt: {
    type: Date
  },
  notes: {
    type: String,
    maxlength: [1000, 'Notes cannot exceed 1000 characters']
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
bookingSchema.index({ user: 1 });
bookingSchema.index({ tour: 1 });
bookingSchema.index({ status: 1 });
bookingSchema.index({ paymentStatus: 1 });
bookingSchema.index({ startDate: 1 });
bookingSchema.index({ createdAt: -1 });

// Virtual for booking ID
bookingSchema.virtual('id').get(function() {
  return this._id.toHexString();
});

// Virtual for booking reference
bookingSchema.virtual('bookingReference').get(function() {
  return `NAP${this._id.toString().slice(-8).toUpperCase()}`;
});

// Virtual for duration
bookingSchema.virtual('duration').get(function() {
  const diffTime = Math.abs(this.endDate - this.startDate);
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
});

// Pre-save middleware to calculate total participants
bookingSchema.pre('save', function(next) {
  this.totalParticipants = this.participants.adults + this.participants.children + this.participants.infants;
  next();
});

// Method to cancel booking
bookingSchema.methods.cancel = function(reason) {
  this.status = 'cancelled';
  this.cancellationReason = reason;
  this.cancelledAt = new Date();
  return this.save();
};

// Method to confirm booking
bookingSchema.methods.confirm = function() {
  this.status = 'confirmed';
  return this.save();
};

// Method to complete booking
bookingSchema.methods.complete = function() {
  this.status = 'completed';
  return this.save();
};

// Method to process refund
bookingSchema.methods.processRefund = function(amount) {
  this.status = 'refunded';
  this.paymentStatus = 'refunded';
  this.refundAmount = amount;
  this.refundedAt = new Date();
  return this.save();
};

// Static method to find bookings by user
bookingSchema.statics.findByUser = function(userId) {
  return this.find({ user: userId })
    .populate('tour', 'title durationDays priceUsd')
    .populate('user', 'name email')
    .sort({ createdAt: -1 });
};

// Static method to find bookings by tour
bookingSchema.statics.findByTour = function(tourId) {
  return this.find({ tour: tourId })
    .populate('user', 'name email phone')
    .sort({ startDate: 1 });
};

// Static method to find bookings by status
bookingSchema.statics.findByStatus = function(status) {
  return this.find({ status })
    .populate('tour', 'title')
    .populate('user', 'name email')
    .sort({ createdAt: -1 });
};

// Static method to get booking statistics
bookingSchema.statics.getStatistics = function() {
  return this.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalRevenue: { $sum: '$totalPrice' }
      }
    }
  ]);
};

module.exports = mongoose.model('Booking', bookingSchema);
