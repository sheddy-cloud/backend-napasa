const mongoose = require('mongoose');
const User = require('./models/User');
const Park = require('./models/Park');
const Tour = require('./models/Tour');
const Lodge = require('./models/Lodge');
require('dotenv').config();

// Sample data
const sampleParks = [
  {
    name: 'Serengeti National Park',
    description: 'Famous for the Great Migration, where millions of wildebeest, zebras, and gazelles move across the plains in search of fresh grazing.',
    location: 'Northern Tanzania',
    coordinates: { latitude: -2.3333, longitude: 34.8333 },
    areaKm2: 14750.0,
    establishedYear: 1951,
    entryFeeUsd: 70.0,
    wildlife: ['Lion', 'Leopard', 'Elephant', 'Buffalo', 'Rhino', 'Wildebeest', 'Zebra', 'Cheetah'],
    bestTimeToVisit: 'June to October (dry season)',
    facilities: ['Visitor Center', 'Restrooms', 'Parking', 'Guided Tours'],
    activities: ['Game Drives', 'Hot Air Balloon', 'Walking Safaris', 'Photography'],
    climate: 'Tropical savanna',
    accessibility: 'Wheelchair accessible facilities available'
  },
  {
    name: 'Mikumi National Park',
    description: 'Known for its diverse ecosystem and abundant wildlife, including elephants, lions, and over 400 bird species.',
    location: 'Central Tanzania',
    coordinates: { latitude: -7.3833, longitude: 37.0833 },
    areaKm2: 3230.0,
    establishedYear: 1964,
    entryFeeUsd: 45.0,
    wildlife: ['Elephant', 'Lion', 'Giraffe', 'Zebra', 'Buffalo', 'Hippo', 'Crocodile'],
    bestTimeToVisit: 'May to October',
    facilities: ['Visitor Center', 'Restrooms', 'Parking'],
    activities: ['Game Drives', 'Bird Watching', 'Photography'],
    climate: 'Tropical',
    accessibility: 'Basic facilities available'
  }
];

const sampleUsers = [
  {
    email: 'admin@napasa.com',
    password: 'admin123',
    name: 'Admin User',
    phone: '+255 123 456 789',
    role: 'Admin',
    isVerified: true
  },
  {
    email: 'john.tourist@example.com',
    password: 'password123',
    name: 'John Tourist',
    phone: '+255 123 456 789',
    role: 'Tourist',
    additionalData: {
      preferences: {
        wildlifeInterest: ['Big Five'],
        budgetRange: 'mid-range',
        accommodationType: 'lodge',
        travelStyle: 'comfortable'
      },
      experienceLevel: 'Beginner'
    }
  },
  {
    email: 'agency@example.com',
    password: 'password123',
    name: 'Sample Travel Agency',
    phone: '+255 987 654 321',
    role: 'Travel Agency',
    additionalData: {
      companyName: 'Sample Travel Agency',
      location: 'Arusha, Tanzania',
      certifications: ['TATO Certified'],
      companyInfo: {
        established: '2020',
        specialties: ['Safari Tours'],
        website: 'https://sampleagency.co.tz',
        description: 'Leading safari operator with over 20 years of experience'
      }
    }
  }
];

async function setupDatabase() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/napasa');
    console.log('✅ Connected to MongoDB');

    // Clear existing data
    console.log('🧹 Clearing existing data...');
    await User.deleteMany({});
    await Park.deleteMany({});
    await Tour.deleteMany({});
    await Lodge.deleteMany({});
    console.log('✅ Existing data cleared');

    // Create sample users
    console.log('👥 Creating sample users...');
    const createdUsers = await User.insertMany(sampleUsers);
    console.log(`✅ Created ${createdUsers.length} users`);

    // Create sample parks
    console.log('🏞️ Creating sample parks...');
    const createdParks = await Park.insertMany(sampleParks);
    console.log(`✅ Created ${createdParks.length} parks`);

    // Create sample tours
    console.log('🎯 Creating sample tours...');
    const agencyUser = createdUsers.find(user => user.role === 'Travel Agency');
    const serengetiPark = createdParks.find(park => park.name === 'Serengeti National Park');

    if (agencyUser && serengetiPark) {
      const sampleTour = new Tour({
        title: 'Great Migration Safari',
        description: 'Witness the spectacular Great Migration in Serengeti National Park.',
        park: serengetiPark._id,
        agency: agencyUser._id,
        durationDays: 5,
        priceUsd: 1200.0,
        maxParticipants: 12,
        difficultyLevel: 'Easy',
        includes: ['Accommodation', 'All Meals', 'Game Drives', 'Park Fees', 'Professional Guide'],
        excludes: ['International Flights', 'Travel Insurance', 'Personal Items', 'Tips'],
        itinerary: [
          {
            day: 1,
            title: 'Arrival in Arusha',
            description: 'Arrive in Arusha and transfer to hotel',
            activities: ['Airport Transfer', 'Hotel Check-in'],
            meals: ['Dinner'],
            accommodation: 'Arusha Hotel'
          },
          {
            day: 2,
            title: 'Drive to Serengeti',
            description: 'Scenic drive to Serengeti National Park',
            activities: ['Game Drive', 'Park Entry'],
            meals: ['Breakfast', 'Lunch', 'Dinner'],
            accommodation: 'Serengeti Lodge'
          }
        ],
        requirements: ['Valid Passport', 'Travel Insurance', 'Yellow Fever Certificate'],
        whatToBring: ['Camera', 'Binoculars', 'Sunscreen', 'Hat'],
        startDates: [
          {
            date: new Date('2024-03-01'),
            availableSpots: 12
          },
          {
            date: new Date('2024-03-15'),
            availableSpots: 8
          }
        ],
        tags: ['migration', 'safari', 'wildlife', 'photography']
      });

      await sampleTour.save();
      console.log('✅ Created sample tour');
    }

    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n📋 Sample Accounts:');
    console.log('Admin: admin@napasa.com / admin123');
    console.log('Tourist: john.tourist@example.com / password123');
    console.log('Agency: agency@example.com / password123');
    console.log('\n🚀 You can now start the server with: npm run dev');

  } catch (error) {
    console.error('❌ Setup failed:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  setupDatabase();
}

module.exports = setupDatabase;
