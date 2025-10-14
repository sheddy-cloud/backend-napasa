const { Sequelize } = require('sequelize');
require('dotenv').config();

// Database configuration
const sequelize = new Sequelize(
  process.env.DB_NAME || 'napasa_main_backend',
  process.env.DB_USER || 'napasa_main_user',
  process.env.DB_PASSWORD || 'napasa_main_password',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    dialect: 'postgres',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true,
      underscored: true,
      freezeTableName: true
    }
  }
);

// Test database connection
const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ PostgreSQL database connection established successfully.');
    return true;
  } catch (error) {
    console.error('❌ Unable to connect to PostgreSQL database:', error.message);
    return false;
  }
};

// Sync database (create tables if they don't exist)
const syncDatabase = async (force = false) => {
  try {
    await sequelize.sync({ force });
    console.log('✅ Database synchronized successfully.');
    return true;
  } catch (error) {
    console.error('❌ Database synchronization failed:', error.message);
    return false;
  }
};

module.exports = {
  sequelize,
  testConnection,
  syncDatabase
};
