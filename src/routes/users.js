const express = require('express');
const User = require('../models/User');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

// @desc    Get all users (Admin only)
// @route   GET /api/users
// @access  Private/Admin
router.get('/', protect, authorize('Admin'), async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const { count, rows: users } = await User.findAndCountAll({
      where: { isActive: true },
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']],
      limit,
      offset
    });

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          current: page,
          pages: Math.ceil(count / limit),
          total: count
        }
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get users by role
// @route   GET /api/users/role/:role
// @access  Private
router.get('/role/:role', protect, async (req, res) => {
  try {
    const { role } = req.params;
    const users = await User.findByRole(role);

    res.json({
      success: true,
      data: { users }
    });
  } catch (error) {
    console.error('Get users by role error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get user by ID
// @route   GET /api/users/:id
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id, {
      attributes: { exclude: ['password'] }
    });
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: { user }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Deactivate user
// @route   PUT /api/users/:id/deactivate
// @access  Private/Admin
router.put('/:id/deactivate', protect, authorize('Admin'), async (req, res) => {
  try {
    const user = await User.update(
      { isActive: false },
      {
        where: { id: req.params.id },
        returning: true
      }
    );

    if (user[0] === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'User deactivated successfully',
      data: { user: user[1][0] }
    });
  } catch (error) {
    console.error('Deactivate user error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Get user statistics
// @route   GET /api/users/stats/overview
// @access  Private/Admin
router.get('/stats/overview', protect, authorize('Admin'), async (req, res) => {
  try {
    const { sequelize } = require('../config/database');
    
    const roleStats = await User.findAll({
      attributes: [
        'role',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count'],
        [sequelize.fn('SUM', sequelize.literal('CASE WHEN "isActive" = true THEN 1 ELSE 0 END')), 'activeCount']
      ],
      group: ['role'],
      raw: true
    });

    const totalUsers = await User.count();
    const activeUsers = await User.count({ where: { isActive: true } });

    res.json({
      success: true,
      data: {
        totalUsers,
        activeUsers,
        roleStats
      }
    });
  } catch (error) {
    console.error('Get user stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
