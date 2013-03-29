BitKind = {
    NOTE:  1,
    PHOTO: 2,
    VISIT:  3,
    DATA:  4,
}

$(function() {

	/* MODELS */

	var Bit = Backbone.Model.extend({
        uid: function() {
            return "" + this.get("type") + "_" + this.get("id");
        },

        url: function() {
            var original_url = Backbone.Model.prototype.url.call(this);
            var parsed_url = original_url + (original_url.charAt(original_url.length - 1) == '/' ? '' : '/' );
            return parsed_url;
        },
  	});

  	var Photo = Bit.extend({
    	urlRoot: function() {
            return "/api/v1/photos/"
        }

		//
  	});

  	var Note = Bit.extend({
		urlRoot: function() {
            return "/api/v1/notes/"
        }
  	});

    var Venue = Backbone.Model.extend({
        //
  	});

  	var Visit = Bit.extend({
		constructor: function (attributes, options) {
			var venue_hash = attributes["venue"];
			delete attributes["venue"];
			
			Backbone.Model.apply(this, arguments);
			this.set("venue", new Venue(venue_hash));
		}
  	});

  	var Dataset = Backbone.Model.extend({
		//
  	});

  	var Data = Bit.extend({
		constructor: function (attributes, options) {
			var dataset_hash = attributes["set"];
			delete attributes["set"];
			
			Backbone.Model.apply(this, arguments);
			this.set("set", new Dataset(dataset_hash));
		}
  	});

  	var BitList = Backbone.Collection.extend({
		model: function(attrs, options) {
			switch(attrs.type) {
				case BitKind.NOTE:
					return new Note(attrs, options);
		     	case BitKind.PHOTO:
		       		return new Photo(attrs, options);
				case BitKind.VISIT:
		       		return new Visit(attrs, options);
				case BitKind.DATA:
		       		return new Data(attrs, options);
				default:
					break;
		  	}
		}
    });

	var Entry = Backbone.Model.extend({
    	url: function() {
            return "/api/entries/" + this.id + "/"
        },

		parse: function(resp, xhr) {
            if (resp.bits) {
			    this.set("bits", new BitList(BitList.prototype.parse(resp.bits)));
			    delete resp.bits;
            }

        	return resp;
    	},

        generate_bit_list: function() {
            var bit_uids = [];
            this.get("bits").each(function(bit) {
                bit_uids.push(bit.uid());
            });
            var bit_list = bit_uids.join();
            return bit_list;
        },

        move_item: function(start_i, end_i) {
            var bits = this.get("bits")
            var bit = bits.at(start_i);
            bits.remove(bit);
            bits.add(bit, {at: end_i});
            this.save({
                "bit_list":  this.generate_bit_list(),
            });
        },
  	});

  	var EntryList = Backbone.Collection.extend({
    	model: Entry,
    	url: "/api/entries/",

    	parse: function(resp, xhr) {
        	return resp.entries;
    	}
  	});

  	/* VIEWS */

	var BitView = Backbone.View.extend({
    	tagName: 'div',

    	initialize: function() {
      		_.bindAll(this, 'render');
    	},
  	});

  	var NoteView = BitView.extend({
  		attributes: {
    		'class': 'bit note',
    	},

	    render: function() {
	    	$(this.el).append(
	    		'<p>' + this.model.get("text") + '</p>'
	    	);

	    	return this;
	    },
  	});

  	var PhotoView = BitView.extend({
		attributes: {
    		'class': 'photo',
    	},

        events: {
            'click b.hide': 'hide',
            'click b.remove': 'remove',
        },

        initialize: function() {
            _.bindAll(this, 'render', 'hide', 'remove');
        },

        hide: function(){
            this.changeStatus(1);
        },

        remove: function(){
            this.changeStatus(2);
        },

        changeStatus: function(status) {
            this.model.save({"status": status}, {
                error: function(model, response) {
                    console.log(response);
                },
            });
            $(this.el).remove();
            doLayout();
        },

	    render: function() {
	    	$(this.el).append(
	    		'<i></i>' +
	    		'<b class="hide"></b>' +
	    		'<b class="remove"></b>' +
	    		'<img src="' + this.model.get("url") + '" />'
	    	);

            var aspect_ratio = this.model.get("aspect_ratio");
            $(this.el).attr("data-aspect-ratio", aspect_ratio);

	    	return this;
	    },
  	});

  	var VisitView = BitView.extend({
  		attributes: {
    		'class': 'bit venue',
    	},

	    render: function() {
	    	$(this.el).append(
	    		'<h1><span class="time">' + this.model.get("time") + '</span> ' + this.model.get("venue").get("name") + '</h1>'
	    	);

	    	return this;
	    },
  	});

  	var DataView = BitView.extend({
  		attributes: {
    		'class': 'bit data',
    	},

	    render: function() {
	    	$(this.el).append(
	    		'<span class="value">' + this.model.get("value") + '</span> ' + this.model.get("set").get("name")
	    	);

	    	return this;
	    },
  	});

  	var EntryView = Backbone.View.extend({
    	tagName: 'div',
    	attributes: {
    		'class': 'entry',
    	},

        events: {
            "click h1": "reorder",
            "reordered": "reorder",
        },

    	initialize: function() {
      		_.bindAll(this, 'render', "reorder");

      		//this.bits = new BitList();
      		//this.bits.bind('add', this.appendBit);
    	},

        reorder: function(e, start_i, end_i) {
            this.model.move_item(start_i, end_i);
        },

    	appendBit: function(bit) {
    		var bitView;
    		switch (bit.get("type")) {
    			case BitKind.NOTE:
					bitView = new NoteView({model: bit});
					break;
		     	case BitKind.PHOTO:
		       		bitView = new PhotoView({model: bit});
					break;
				case BitKind.VISIT:
		       		bitView = new VisitView({model: bit});
					break;
				case BitKind.DATA:
		       		bitView = new DataView({model: bit});
					break;
				default:
					break;
    		}

    		$(this.el).append(bitView.render().el);
    	},

	    render: function() {
            $(this.el).children().remove();

	    	$(this.el).append(
                '<div class="title">' +
	    		    '<h1>' + this.model.get("title") + '</h1>' +
	    		    '<h2>' + this.model.get("subtitle") + '</h2>' +
                '</div>'
	    	);

	    	_(this.model.get("bits").models).each(function(bit) {
        		this.appendBit(bit);
      		}, this);

      		$(this.el).append(
	    		'<div class="clear"></div>'
	    	);

	    	return this;
	    },
  	});

  	var EntryListView = Backbone.View.extend({
		el: $('body'),

		initialize: function() {
      		_.bindAll(this, 'render');

            var _this = this;
      		this.entries = new EntryList();
      		this.entries.bind('add', this.appendEntry);
      		this.entries.fetch({
                success: function() {
                    _this.render();
                    init();
                },
            });
		},

    	appendEntry: function(entry) {
    		var entryView = new EntryView({
        		model: entry,
      		});
    		$('div.page', this.el).append(entryView.render().el);
    	},

		render: function() {
			$(this.el).append('<div class="page"></div>');

			_(this.entries.models).each(function(entry) {
        		this.appendEntry(entry);
      		}, this);

            return this;
		},
	});

    /* FORMS */

    var NoteForm = Backbone.Form.extend({
        schema: {
            timestamp: 'DateTime',
            text: 'Text',
        },
    });

    var CreateNoteView = Backbone.View.extend({
        tagName: 'div',
        attributes: {
            'class': 'modal',
        },

        events: {
            "click #submit": "submit",
            "click .modal-overlay": "dismiss",
        },

        initialize: function() {
            _.bindAll(this, 'render', 'submit', 'dismiss');

            this.form = new NoteForm({
                model: new Note(),
            });
        },

        submit: function() {
            var errors = this.form.commit();
            if (!errors) {
                this.form.model.save({}, {
                    error: function(model, response) {
                        console.log(response);
                    },
                });
            }
        },

        dismiss: function () {
            $(this.el).remove();
        },

        render: function() {
            $(this.el).append('<div class="modal-overlay"></div>');

            var page = $('<div class="modal-page"></div>');
            page.append(this.form.render().el);
            page.append("<input type='submit' id='submit' value='submit' name='submit' />");

            $(this.el).append(page);

            return this;
        },
    });

    var CreateNoteButton = Backbone.View.extend({
        el: $('body'),

        events: {
            "click button": "add",
        },

        initialize: function() {
            _.bindAll(this, 'render', 'add');

            this.render();
        },

        add: function() {
            var createNoteView = new CreateNoteView();
            $(this.el).append(createNoteView.render().el);
        },

        render: function() {
            $(this.el).append('<button>Add</button>');

            return this;
        },
    });

	/* APP */

	var entryListView = new EntryListView();
    var createNoteButton = new CreateNoteButton();

});
