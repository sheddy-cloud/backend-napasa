const mongoose = require('mongoose');

const tourSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Tour title is required'],
    trim: true,
    maxlength: [100, 'Title cannot exceed 100 characters']
  },
  description: {
    type: String,
    required: [true, 'Tour description is required'],
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  park: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Park',
    required: [true, 'Park reference is required']
  },
  agency: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Travel agency reference is required']
  },
  durationDays: {
    type: Number,
    required: [true, 'Duration is required'],
    min: [1, 'Duration must be at least 1 day'],
    max: [30, 'Duration cannot exceed 30 days']
  },
  priceUsd: {
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price must be positive']
  },
  maxParticipants: {
    type: Number,
    required: [true, 'Maximum participants is required'],
    min: [1, 'Must allow at least 1 participant'],
    max: [50, 'Cannot exceed 50 participants']
  },
  currentParticipants: {
    type: Number,
    default: 0,
    min: 0
  },
  difficultyLevel: {
    type: String,
    required: [true, 'Difficulty level is required'],
    enum: {
      values: ['Easy', 'Moderate', 'Challenging', 'Extreme'],
      message: 'Difficulty must be Easy, Moderate, Challenging, or Extreme'
    }
  },
  includes: [{
    type: String,
    trim: true
  }],
  excludes: [{
    type: String,
    trim: true
  }],
  itinerary: [{
    day: {
      type: Number,
      required: true
    },
    title: {
      type: String,
      required: true
    },
    description: {
      type: String,
      required: true
    },
    activities: [String],
    meals: [String],
    accommodation: String
  }],
  images: [{
    url: {
      type: String,
      required: true
    },
    caption: String,
    isPrimary: {
      type: Boolean,
      default: false
    }
  }],
  requirements: [{
    type: String,
    trim: true
  }],
  whatToBring: [{
    type: String,
    trim: true
  }],
  cancellationPolicy: {
    type: String,
    default: 'Free cancellation up to 24 hours before tour start'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isAvailable: {
    type: Boolean,
    default: true
  },
  startDates: [{
    date: {
      type: Date,
      required: true
    },
    availableSpots: {
      type: Number,
      required: true
    }
  }],
  rating: {
    average: {
      type: Number,
      default: 0,
      min: 0,
      max: 5
    },
    count: {
      type: Number,
      default: 0
    }
  },
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }]
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
tourSchema.index({ title: 1 });
tourSchema.index({ park: 1 });
tourSchema.index({ agency: 1 });
tourSchema.index({ isActive: 1, isAvailable: 1 });
tourSchema.index({ 'rating.average': -1 });
tourSchema.index({ priceUsd: 1 });
tourSchema.index({ durationDays: 1 });
tourSchema.index({ tags: 1 });

// Virtual for tour ID
tourSchema.virtual('id').get(function() {
  return this._id.toHexString();
});

// Virtual for primary image
tourSchema.virtual('primaryImage').get(function() {
  const primaryImg = this.images.find(img => img.isPrimary);
  return primaryImg ? primaryImg.url : (this.images.length > 0 ? this.images[0].url : null);
});

// Virtual for availability status
tourSchema.virtual('isFullyBooked').get(function() {
  return this.currentParticipants >= this.maxParticipants;
});

// Virtual for spots remaining
tourSchema.virtual('spotsRemaining').get(function() {
  return this.maxParticipants - this.currentParticipants;
});

// Method to check if tour is available on specific date
tourSchema.methods.isAvailableOnDate = function(date) {
  const startDate = this.startDates.find(sd => 
    sd.date.toDateString() === date.toDateString()
  );
  return startDate && startDate.availableSpots > 0;
};

// Method to book spots
tourSchema.methods.bookSpots = function(spots, date) {
  if (spots > this.spotsRemaining) {
    throw new Error('Not enough spots available');
  }
  
  this.currentParticipants += spots;
  
  // Update available spots for specific date
  const startDate = this.startDates.find(sd => 
    sd.date.toDateString() === date.toDateString()
  );
  
  if (startDate) {
    startDate.availableSpots -= spots;
  }
  
  return this.save();
};

// Method to cancel booking
tourSchema.methods.cancelBooking = function(spots, date) {
  this.currentParticipants = Math.max(0, this.currentParticipants - spots);
  
  // Update available spots for specific date
  const startDate = this.startDates.find(sd => 
    sd.date.toDateString() === date.toDateString()
  );
  
  if (startDate) {
    startDate.availableSpots += spots;
  }
  
  return this.save();
};

// Method to update rating
tourSchema.methods.updateRating = function(newRating) {
  const totalRating = (this.rating.average * this.rating.count) + newRating;
  this.rating.count += 1;
  this.rating.average = totalRating / this.rating.count;
  return this.save();
};

// Static method to find tours by park
tourSchema.statics.findByPark = function(parkId) {
  return this.find({ park: parkId, isActive: true, isAvailable: true })
    .populate('park', 'name location')
    .populate('agency', 'name companyName')
    .sort({ 'rating.average': -1 });
};

// Static method to find tours by agency
tourSchema.statics.findByAgency = function(agencyId) {
  return this.find({ agency: agencyId, isActive: true })
    .populate('park', 'name location')
    .sort({ createdAt: -1 });
};

// Static method to search tours
tourSchema.statics.searchTours = function(query) {
  const searchQuery = {
    isActive: true,
    isAvailable: true,
    $or: [
      { title: new RegExp(query, 'i') },
      { description: new RegExp(query, 'i') },
      { tags: new RegExp(query, 'i') }
    ]
  };
  
  return this.find(searchQuery)
    .populate('park', 'name location')
    .populate('agency', 'name companyName')
    .sort({ 'rating.average': -1 });
};

module.exports = mongoose.model('Tour', tourSchema);
