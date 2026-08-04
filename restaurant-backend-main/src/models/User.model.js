const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Please add a name'],
        trim: true
    },
    email: {
        type: String,
        unique: true,
        sparse: true,
        trim: true,
        match: [
            /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
            'Please add a valid email'
        ]
    },
    phone: {
        type: String,
        required: function() {
            return this.authProvider !== 'google';
        },
        unique: true,
        sparse: true,
        trim: true
    },
    address: {
        type: String, default: '', trim: true
    },
    avatarUrl: {
        type: String,
        default: '',
        trim: true
    },
    googleId: {
        type: String,
        unique: true,
        sparse: true,
        trim: true
    },
    authProvider: {
        type: String,
        enum: ['password', 'google'],
        default: 'password'
    },
    savedCards: [
        {
            label: {
                type: String,
                trim: true,
                default: 'Saved Card'
            },
            brand: {
                type: String,
                trim: true,
                default: 'Card'
            },
            last4: {
                type: String,
                trim: true,
                default: ''
            },
            expiryMonth: {
                type: String,
                trim: true,
                default: ''
            },
            expiryYear: {
                type: String,
                trim: true,
                default: ''
            }
        }
    ],
    password: {
        type: String,
        required: function() {
            return this.authProvider !== 'google';
        },
        minlength: 6,
        select: false // Do not return password by default
    },
    role: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Role',
        required: true
    },
    restaurantId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Restaurant',
        default: null // null means Super Admin
    },
    branchId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
        default: null
    },
    status: {
        type: String,
        enum: ['Active', 'Inactive', 'Suspended'],
        default: 'Active'
    }
}, {
    timestamps: true
});

// Encrypt password using bcrypt
userSchema.pre('save', async function(next) {
    if (!this.password || !this.isModified('password')) {
        return next();
    }
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// Match user entered password to hashed password in database
userSchema.methods.matchPassword = async function(enteredPassword) {
    if (!this.password) return false;
    return await bcrypt.compare(enteredPassword, this.password);
};

// Sign JWT and return
userSchema.methods.getSignedJwtToken = function() {
    return jwt.sign({ id: this._id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRE
    });
};

module.exports = mongoose.model('User', userSchema);
