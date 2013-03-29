var redis = require('redis');
var db = redis.createClient();

exports.getAllModelsInCollection = function(entity, collection, callback) {
	var key_pattern = entity + '/' + collection + '*';
	db.keys(key_pattern, function(error, keys) {
		if (error) {
			callback(error, undefined);
		} else {
			var models = [];
			if (keys.length > 0) {
				db.mget(keys, function(error, replies) {
					var models = [];
					for (var i in replies) {
						var model = JSON.parse(replies[i]);
						models.push(model);
					}
					callback(error, models);
				});
			} else {
				callback(error, models);
			}
		}
	});
}

exports.getModel = function(entity, collection, key, callback) {
	var db_key = entity + '/' + collection + '/' + key;
	db.get(db_key, function(error, reply) {
		var model = JSON.parse(reply);
		callback(error, model);
	});
}

exports.setModel = function(entity, collection, key, model, callback) {
	var db_key = entity + '/' + collection + '/' + key;
	var payload = JSON.stringify(model);
	db.set(db_key, payload, function(error, response) {
		var success = !error;
		callback(success, error);
	});
}
