const express = require('express');
const Lodge = require('../models/Lodge');
const { protect, authorize, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// @desc    Get all lodges
// @route   GET /api/lodges
// @access  Public
router.get('/', optionalAuth, async (req, res) => {
  try {
    const lodges = await Lodge.find({ isActive: true })
      .populate('park', 'name location')
      .sort({ 'rating.average': -1 });

    res.json({
      success: true,
      data: { lodges }
    });
  } catch (error) {
    console.error('Get lodges error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get lodge by ID
// @route   GET /api/lodges/:id
// @access  Public
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const lodge = await Lodge.findById(req.params.id)
      .populate('park', 'name location');

    if (!lodge || !lodge.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Lodge not found'
      });
    }

    res.json({
      success: true,
      data: { lodge }
    });
  } catch (error) {
    console.error('Get lodge error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
