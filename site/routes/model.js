var express = require('express');
var router = express.Router();

var db = require('../database/db');

///

var modelIsValid = function(model) {
	// return model['foo'] != undefined;
	return true;
}

///

var modelPath = '/:entity/:collection/:key';

router.get(modelPath, function(request, response) {
	var entity = request.params['entity'];
	var collection = request.params['collection'];
	var key = request.params['key'];

	db.getModel(entity, collection, key, function(error, model) {
		if (error) {
			response.send(500, error);
		} else if (model) {
    		response.send(200, model);
		} else {
			response.send(404);
		}
	});
});

router.post(modelPath, function(request, response) {
	var entity = request.params['entity'];
	var collection = request.params['collection'];
	var key = request.params['key'];
	var model = request.body;

	if (modelIsValid(model)) {
		db.setModel(entity, collection, key, model, function(success, error) {
			if (success) {
	    		response.send(200, model);
			} else {
				response.send(500, error);
			}
		});
	} else {
		response.send(400);
	}
});

router.patch(modelPath, function(request, response) {
	var entity = request.params['entity'];
	var collection = request.params['collection'];
	var key = request.params['key'];
	var updates = request.body;

	db.getModel(entity, collection, key, function(error, model) {
		if (error) {
			response.send(500, error);
		} else if (model) {
			for (update_key in updates) {
				model[update_key] = updates[update_key];
			}
			db.setModel(entity, collection, key, model, function(success, error) {
				if (success) {
		    		response.send(200, model);
				} else {
					response.send(500, error);
				}
			});
		} else {
			response.send(404);
		}
	});
});

router.delete(modelPath, function(request, response) {
	var entity = request.params['entity'];
	var collection = request.params['collection'];
	var key = request.params['key'];

	db.getModel(entity, collection, key, function(error, model) {
		if (error) {
			response.send(500, error);
		} else if (model) {
			model['deleted'] = true;
			db.setModel(entity, collection, key, model, function(success, error) {
				if (success) {
		    		response.send(200, model);
				} else {
					response.send(500, error);
				}
			});
		} else {
			response.send(404);
		}
	});
});

///

var insertDeleteOrMoveElement = function(array, member, index) {
	if (member == undefined) {
		return;
	}
	var existing_index = array.indexOf(member);
	if (existing_index >= 0) {
		array.splice(existing_index, 1);
	}
	if (index >= 0) {
		var new_index = Math.min(index, array.length);
		array.splice(index, 0, member);
	}
}

var modelListPath = '/:entity/:collection/:key/:list_key';

router.patch(modelListPath, function(request, response) {
	var entity = request.params['entity'];
	var collection = request.params['collection'];
	var key = request.params['key'];
	var list_key = request.params['list_key'];

	var member_key = request.body['member_key'];
	var member_index = request.body['member_index'];

	db.getModel(entity, collection, key, function(error, model) {
		if (error) {
			response.send(500, error);
		} else if (model) {
			var list = model[list_key];
			if (list == undefined) {
				list = [];
				model[list_key] = list;
			}
			insertDeleteOrMoveElement(list, member_key, member_index);
			db.setModel(entity, collection, key, model, function(success, error) {
				if (success) {
		    		response.send(200, model);
				} else {
					response.send(500, error);
				}
			});
		} else {
			response.send(404);
		}
	});
});

///

module.exports = router;
