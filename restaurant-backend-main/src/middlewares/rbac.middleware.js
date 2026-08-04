const authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user || !req.user.role) {
            return res.status(403).json({ success: false, message: 'User role not found' });
        }
        
        if (!roles.includes(req.user.role.name)) {
            return res.status(403).json({ 
                success: false, 
                message: `User role ${req.user.role.name} is not authorized to access this route` 
            });
        }
        next();
    };
};

module.exports = { authorize };
