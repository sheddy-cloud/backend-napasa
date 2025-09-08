const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
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
  booking: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    required: [true, 'Booking reference is required']
  },
  rating: {
    overall: {
      type: Number,
      required: [true, 'Overall rating is required'],
      min: [1, 'Rating must be at least 1'],
      max: [5, 'Rating cannot exceed 5']
    },
    guide: {
      type: Number,
      min: [1, 'Guide rating must be at least 1'],
      max: [5, 'Guide rating cannot exceed 5']
    },
    accommodation: {
      type: Number,
      min: [1, 'Accommodation rating must be at least 1'],
      max: [5, 'Accommodation rating cannot exceed 5']
    },
    food: {
      type: Number,
      min: [1, 'Food rating must be at least 1'],
      max: [5, 'Food rating cannot exceed 5']
    },
    value: {
      type: Number,
      min: [1, 'Value rating must be at least 1'],
      max: [5, 'Value rating cannot exceed 5']
    }
  },
  title: {
    type: String,
    required: [true, 'Review title is required'],
    trim: true,
    maxlength: [100, 'Title cannot exceed 100 characters']
  },
  comment: {
    type: String,
    required: [true, 'Review comment is required'],
    trim: true,
    maxlength: [1000, 'Comment cannot exceed 1000 characters']
  },
  pros: [{
    type: String,
    trim: true,
    maxlength: [200, 'Pro cannot exceed 200 characters']
  }],
  cons: [{
    type: String,
    trim: true,
    maxlength: [200, 'Con cannot exceed 200 characters']
  }],
  images: [{
    url: {
      type: String,
      required: true
    },
    caption: String
  }],
  isVerified: {
    type: Boolean,
    default: false
  },
  isPublic: {
    type: Boolean,
    default: true
  },
  helpful: {
    count: {
      type: Number,
      default: 0
    },
    users: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }]
  },
  response: {
    text: {
      type: String,
      maxlength: [500, 'Response cannot exceed 500 characters']
    },
    respondedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    respondedAt: {
      type: Date
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
reviewSchema.index({ user: 1 });
reviewSchema.index({ tour: 1 });
reviewSchema.index({ booking: 1 });
reviewSchema.index({ 'rating.overall': -1 });
reviewSchema.index({ isPublic: 1 });
reviewSchema.index({ createdAt: -1 });

// Virtual for review ID
reviewSchema.virtual('id').get(function() {
  return this._id.toHexString();
});

// Virtual for average rating
reviewSchema.virtual('averageRating').get(function() {
  const ratings = [
    this.rating.overall,
    this.rating.guide,
    this.rating.accommodation,
    this.rating.food,
    this.rating.value
  ].filter(rating => rating !== undefined);
  
  return ratings.length > 0 
    ? ratings.reduce((sum, rating) => sum + rating, 0) / ratings.length 
    : this.rating.overall;
});

// Method to mark as helpful
reviewSchema.methods.markHelpful = function(userId) {
  if (!this.helpful.users.includes(userId)) {
    this.helpful.users.push(userId);
    this.helpful.count += 1;
    return this.save();
  }
  return Promise.resolve(this);
};

// Method to unmark as helpful
reviewSchema.methods.unmarkHelpful = function(userId) {
  const index = this.helpful.users.indexOf(userId);
  if (index > -1) {
    this.helpful.users.splice(index, 1);
    this.helpful.count = Math.max(0, this.helpful.count - 1);
    return this.save();
  }
  return Promise.resolve(this);
};

// Method to add response
reviewSchema.methods.addResponse = function(text, respondedBy) {
  this.response = {
    text,
    respondedBy,
    respondedAt: new Date()
  };
  return this.save();
};

// Static method to find reviews by tour
reviewSchema.statics.findByTour = function(tourId) {
  return this.find({ tour: tourId, isPublic: true })
    .populate('user', 'name avatar')
    .populate('response.respondedBy', 'name')
    .sort({ createdAt: -1 });
};

// Static method to find reviews by user
reviewSchema.statics.findByUser = function(userId) {
  return this.find({ user: userId })
    .populate('tour', 'title')
    .populate('booking', 'bookingReference')
    .sort({ createdAt: -1 });
};

// Static method to get tour rating statistics
reviewSchema.statics.getTourRatingStats = function(tourId) {
  return this.aggregate([
    { $match: { tour: mongoose.Types.ObjectId(tourId), isPublic: true } },
    {
      $group: {
        _id: null,
        averageRating: { $avg: '$rating.overall' },
        totalReviews: { $sum: 1 },
        ratingDistribution: {
          $push: '$rating.overall'
        }
      }
    },
    {
      $project: {
        averageRating: { $round: ['$averageRating', 1] },
        totalReviews: 1,
        ratingDistribution: {
          $reduce: {
            input: [1, 2, 3, 4, 5],
            initialValue: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
            in: {
              $mergeObjects: [
                '$$value',
                {
                  $arrayToObject: [
                    [{
                      k: { $toString: '$$this' },
                      v: {
                        $size: {
                          $filter: {
                            input: '$ratingDistribution',
                            cond: { $eq: ['$$item', '$$this'] }
                          }
                        }
                      }
                    }]
                  ]
                }
              ]
            }
          }
        }
      }
    }
  ]);
};

// Static method to get recent reviews
reviewSchema.statics.getRecentReviews = function(limit = 10) {
  return this.find({ isPublic: true })
    .populate('user', 'name avatar')
    .populate('tour', 'title primaryImage')
    .sort({ createdAt: -1 })
    .limit(limit);
};

module.exports = mongoose.model('Review', reviewSchema);
