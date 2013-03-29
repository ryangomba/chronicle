$(function() {

    var CreateNoteView = Backbone.View.extend({
		tagName: 'div',
        attributes: {
            'class': 'modal',
        },

		initialize: function() {
      		_.bindAll(this, 'render');
		},

		render: function() {
            $(this.el).append(
                '<div class="modal-page">' +
                    'Test' +
                '</div>'
            );

            return this;
		},
    });

});

