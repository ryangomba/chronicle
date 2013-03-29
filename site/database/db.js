var AWS = require('aws-sdk'); 
AWS.config.update({
	"accessKeyId": process.env.AWS_ACCESS_KEY_ID,,
	"secretAccessKey": process.env.AWS_SECRET_ACCESS_KEY,
	"region": process.env.AWS_REGION,
});
var db = new AWS.DynamoDB();

var modelFromItem = function(item) {
	var model = {};
	for (var key in item) {
		for (var type_key in item[key]) {
			var value = item[key][type_key];
			try {
				model[key] = JSON.parse(value);
			} catch(error) {
				model[key] = value;
			}
		}
	}
	return model;
}

var itemFromModel = function(model) {
	var item = {};
	for (var key in model) {
		var value = model[key];
		if (typeof value == 'string') {
			if (value.length > 0) { // TODO then how do we clear a string?
				item[key] = {'S': value};
			}
		} else {
			if (value.length == undefined || value.length > 0) {
				value = JSON.stringify(value);
				item[key] = {'S': value};
			}
		}
	}
	return item;
}

exports.getAllModelsInCollection = function(entity, collection, callback) {
	var params = {};

	// TableName
	params['TableName'] = entity;

	// Collection
	var has_collection = collection != 'all';
	if (has_collection) {
		params['KeyConditions'] = {
			'collection': {
				'ComparisonOperator': 'EQ',
				'AttributeValueList': [{
					'S': collection,
				}],
			},
		};
	}

	var completion = function(error, data) {
  		if (error) {
			console.log(error, error.stack);
			callback(error, undefined);
  		} else {
  			var items = data['Items'];
			var models = [];
			for (var i in items) {
				var item = items[i];
				var model = modelFromItem(item);
				models.push(model);
			}
  			callback(error, models);
  		}
  	}

	if (has_collection) {
		db.query(params, completion);
	} else {
		db.scan(params, completion);
	}
}

exports.getModel = function(entity, collection, key, callback) {
	var params = {};

	// TableName
	params['TableName'] = entity;

	// Read
	params['ConsistentRead'] = true;

	// Key
	params['Key'] = {};
	if (collection != 'all') {
		params['Key']['collection'] = {'S': collection};
	}
	params['Key']['pk'] = {'S': key};

	db.getItem(params, function(error, data) {
  		if (error) {
			console.log(error, error.stack);
			callback(error, undefined);
  		} else {
  			var item = data['Item'];
  			var model = modelFromItem(item);
  			callback(error, model);
  		}
  	});
}

exports.setModel = function(entity, collection, key, model, callback) {
	var params = {}

	// TableName
	params['TableName'] = entity;

	// Item
	var item = itemFromModel(model);
	if (collection != 'all') {
		item['collection'] = {'S': collection};
	}
	item['pk'] = {'S': key};
	params['Item'] = item;

	db.putItem(params, function(error, data) {
		if (error) {
			console.log(error, error.stack);
			callback(false, error);
  		} else {
  			callback(true, undefined);
  		}
	});
}

exports.deleteModel = function(entity, collection, key, callback) {
	var params = {};

	// TableName
	params['TableName'] = entity;

	// Key
	params['Key'] = {};
	if (collection != 'all') {
		params['Key']['collection'] = {'S': collection};
	}
	params['Key']['pk'] = {'S': key};

	db.deleteItem(params, function(error, data) {
  		if (error) {
			console.log(error, error.stack);
			callback(error, undefined);
  		} else {
  			var item = data['Item'];
  			var model = modelFromItem(item);
  			callback(error, model);
  		}
  	});
}
