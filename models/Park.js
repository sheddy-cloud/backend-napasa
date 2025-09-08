const mongoose = require('mongoose');

const parkSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Park name is required'],
    trim: true,
    maxlength: [100, 'Park name cannot exceed 100 characters']
  },
  description: {
    type: String,
    required: [true, 'Park description is required'],
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  location: {
    type: String,
    required: [true, 'Park location is required'],
    trim: true
  },
  coordinates: {
    latitude: {
      type: Number,
      required: [true, 'Latitude is required'],
      min: [-90, 'Latitude must be between -90 and 90'],
      max: [90, 'Latitude must be between -90 and 90']
    },
    longitude: {
      type: Number,
      required: [true, 'Longitude is required'],
      min: [-180, 'Longitude must be between -180 and 180'],
      max: [180, 'Longitude must be between -180 and 180']
    }
  },
  areaKm2: {
    type: Number,
    required: [true, 'Park area is required'],
    min: [0, 'Area must be positive']
  },
  establishedYear: {
    type: Number,
    required: [true, 'Established year is required'],
    min: [1800, 'Established year must be after 1800'],
    max: [new Date().getFullYear(), 'Established year cannot be in the future']
  },
  entryFeeUsd: {
    type: Number,
    required: [true, 'Entry fee is required'],
    min: [0, 'Entry fee must be positive']
  },
  wildlife: [{
    type: String,
    trim: true
  }],
  bestTimeToVisit: {
    type: String,
    required: [true, 'Best time to visit is required']
  },
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
  videos: [{
    url: {
      type: String,
      required: true
    },
    title: String,
    duration: Number // in seconds
  }],
  facilities: [{
    type: String,
    trim: true
  }],
  activities: [{
    type: String,
    trim: true
  }],
  climate: {
    type: String,
    trim: true
  },
  accessibility: {
    type: String,
    trim: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
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
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
parkSchema.index({ name: 1 });
parkSchema.index({ location: 1 });
parkSchema.index({ 'coordinates.latitude': 1, 'coordinates.longitude': 1 });
parkSchema.index({ isActive: 1 });
parkSchema.index({ 'rating.average': -1 });

// Virtual for park ID
parkSchema.virtual('id').get(function() {
  return this._id.toHexString();
});

// Virtual for primary image
parkSchema.virtual('primaryImage').get(function() {
  const primaryImg = this.images.find(img => img.isPrimary);
  return primaryImg ? primaryImg.url : (this.images.length > 0 ? this.images[0].url : null);
});

// Method to update rating
parkSchema.methods.updateRating = function(newRating) {
  const totalRating = (this.rating.average * this.rating.count) + newRating;
  this.rating.count += 1;
  this.rating.average = totalRating / this.rating.count;
  return this.save();
};

// Static method to find parks by location
parkSchema.statics.findByLocation = function(location) {
  return this.find({ 
    location: new RegExp(location, 'i'), 
    isActive: true 
  }).sort({ 'rating.average': -1 });
};

// Static method to find parks near coordinates
parkSchema.statics.findNearby = function(latitude, longitude, maxDistance = 100) {
  return this.find({
    'coordinates.latitude': {
      $gte: latitude - (maxDistance / 111), // Rough conversion: 1 degree ≈ 111 km
      $lte: latitude + (maxDistance / 111)
    },
    'coordinates.longitude': {
      $gte: longitude - (maxDistance / 111),
      $lte: longitude + (maxDistance / 111)
    },
    isActive: true
  });
};

module.exports = mongoose.model('Park', parkSchema);
