const mongoose = require('mongoose');

const lodgeSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Lodge name is required'],
    trim: true,
    maxlength: [100, 'Lodge name cannot exceed 100 characters!']
  },
  location: {
    type: String,
    required: [true, 'Lodge location is required'],
    trim: true
  },
  park: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Park',
    required: [true, 'Park reference is required']
  },
  lodgeType: {
    type: String,
    required: [true, 'Lodge type is required'],
    enum: {
      values: ['Luxury', 'Mid-Range', 'Budget', 'Tented Camp', 'Eco-Lodge'],
      message: 'Lodge type must be Luxury, Mid-Range, Budget, Tented Camp, or Eco-Lodge'
    }
  },
  capacity: {
    type: Number,
    required: [true, 'Capacity is required'],
    min: [1, 'Capacity must be at least 1']
  },
  pricePerNightUsd: {
    type: Number,
    required: [true, 'Price per night is required'],
    min: [0, 'Price must be positive']
  },
  amenities: [{
    type: String,
    trim: true
  }],
  description: {
    type: String,
    required: [true, 'Description is required'],
    maxlength: [2000, 'Description cannot exceed 2000 characters']
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
  contactEmail: {
    type: String,
    required: [true, 'Contact email is required'],
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  contactPhone: {
    type: String,
    required: [true, 'Contact phone is required'],
    match: [/^\+?[\d\s-()]+$/, 'Please enter a valid phone number']
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
lodgeSchema.index({ name: 1 });
lodgeSchema.index({ park: 1 });
lodgeSchema.index({ lodgeType: 1 });
lodgeSchema.index({ isActive: 1 });
lodgeSchema.index({ 'rating.average': -1 });

// Virtual for lodge ID
lodgeSchema.virtual('id').get(function() {
  return this._id.toHexString();
});

// Virtual for primary image
lodgeSchema.virtual('primaryImage').get(function() {
  const primaryImg = this.images.find(img => img.isPrimary);
  return primaryImg ? primaryImg.url : (this.images.length > 0 ? this.images[0].url : null);
});

module.exports = mongoose.model('Lodge', lodgeSchema);
