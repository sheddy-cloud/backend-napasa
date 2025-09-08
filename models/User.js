const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters'],
    select: false // Don't include password in queries by default
  },
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    maxlength: [100, 'Name cannot exceed 100 characters']
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
    match: [/^\+?[\d\s-()]+$/, 'Please enter a valid phone number']
  },
  role: {
    type: String,
    required: [true, 'Role is required'],
    enum: {
      values: ['Tourist', 'Travel Agency', 'Lodge Owner', 'Restaurant Owner', 'Travel Gear Seller', 'Photographer', 'Tour Guide'],
      message: 'Role must be one of: Tourist, Travel Agency, Lodge Owner, Restaurant Owner, Travel Gear Seller, Photographer, Tour Guide'
    }
  },
  avatar: {
    type: String,
    default: null
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  lastActive: {
    type: Date,
    default: Date.now
  },
  // Role-specific data
  additionalData: {
    // Tourist specific
    preferences: {
      wildlifeInterest: [String],
      budgetRange: String,
      accommodationType: String,
      travelStyle: String
    },
    experienceLevel: {
      type: String,
      enum: ['Beginner', 'Intermediate', 'Advanced'],
      default: 'Beginner'
    },
    
    // Travel Agency specific
    companyName: String,
    location: String,
    certifications: [String],
    companyInfo: {
      established: String,
      specialties: [String],
      website: String,
      description: String
    },
    
    // Lodge Owner specific
    lodgeName: String,
    lodgeType: String,
    capacity: Number,
    lodgeInfo: {
      amenities: [String],
      description: String,
      location: String
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better performance (email index is already created by unique: true)
userSchema.index({ role: 1 });
userSchema.index({ isActive: 1 });

// Virtual for user ID
userSchema.virtual('id').get(function() {
  return this._id.toHexString();
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Update lastActive before saving
userSchema.pre('save', function(next) {
  if (this.isModified() && !this.isNew) {
    this.lastActive = new Date();
  }
  next();
});

// Instance method to check password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Instance method to generate JWT token
userSchema.methods.generateAuthToken = function() {
  return jwt.sign(
    { 
      id: this._id,
      email: this.email,
      role: this.role 
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

// Instance method to get public profile
userSchema.methods.getPublicProfile = function() {
  const userObject = this.toObject();
  delete userObject.password;
  return userObject;
};

// Static method to find user by email
userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

// Static method to get users by role
userSchema.statics.findByRole = function(role) {
  return this.find({ role, isActive: true }).select('-password');
};

module.exports = mongoose.model('User', userSchema);
