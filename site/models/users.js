var db = require('../database/db');

exports.saveUser = function(user, callback) {
	db.setModel('user', 'all', user.pk, user, function(success, error) {
		if (success) {
			callback(null, user);
		} else {
			callback(error, null);
		}
	});
}

exports.getUser = function(user_pk, callback) {
	db.getModel('user', 'all', user_pk, function(error, user) {
		callback(error, user);
	});
}
