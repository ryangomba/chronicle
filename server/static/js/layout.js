// 5.0 is good for huge screens
// 4.0 is good for large screens
// 3.0 is good for most screens
// 2.0 is good for tablet screens
// 1.0 is good for phone screens
var multipler;

function ratio_for_image(image) {
	return parseFloat(image.attr("data-aspect-ratio"));
}

function min_percent_for_ratio(ratio) {
	return ratio / multipler * 100.0;
}

function lay_out_images(images, top_padding) {
	if (images.length == 0) {
		return;
	}

	var ratios = [];
	var ratio_sum = 0;

	for (var i in images) {
		var image = images[i];
		var ratio = ratio_for_image(image);
		ratios.push(ratio);
		ratio_sum = ratio_sum + ratio;
	}

	var height = 100.0 / ratio_sum;
	var additive_width = 0;
	for (var i in images) {
		var image = images[i];
		var width = height * ratios[i];
        var ratio = ratio_for_image(image);
		if (i == images.length - 1) {
			width = 100.0 - additive_width;
		} else {
			additive_width = additive_width + width;
		}
		image.css("width", "" + width + "%");
		image.css("height", "" + width / ratio * 280 / 100 + "px");
		image.css("clear", "none");
        image.css("margin-top", "" + top_padding + "px");
        image.css("margin-bottom", "0px");
	}

    images[0].css("clear", "both");
}

function updateLayout() {
	var window_width = $(window).width();

	var new_multipler;
	if (window_width <= 480.0) {
		new_multipler = 1.0;
	} else if (window_width < 768.0) {
		new_multipler = 2.0;
	} else if (window_width <= 1400.0) {
		new_multipler = 3.0;
	} else if (window_width <= 2000.0) {
		new_multipler = 4.0;
	} else {
		new_multipler = 5.0;
	}

	// override
	new_multipler = 2.67;

    //if (new_multipler != multipler) {
		multipler = new_multipler;
		doLayout();
	//}
}

function doLayout() {
	$(".entry").each(function() {
		var bits = $(this).children();
		var images = $();
		bits.each(function() {
			if ($(this).hasClass("photo")) {
				var hidden = $(this).css("display") == "none";
				if (!hidden) {
					images = images.add($(this));
				}
			} else {
				doSingleLayout(images);
				images = $();
			}
		});
		doSingleLayout(images);
	});
}

function doSingleLayout(images) {
	if (images.length == 0) {
		return;
	}

	var current_width = 0;
	var current_images = [];
    var is_top = 10;

	images.each(function(i) {
		var ratio = ratio_for_image($(this));
		var min_percent = min_percent_for_ratio(ratio);

		var new_current_width = current_width + min_percent;
		if (new_current_width > 100.0) {
			lay_out_images(current_images, is_top);
            is_top = 0;

			current_width = min_percent;
			current_images = [$(this)];

		} else {
			current_width = new_current_width;
			current_images.push($(this));
		}
	});

	lay_out_images(current_images, is_top);

    images.last().css("margin-bottom", "10px")
}

function init() {
	updateLayout();

	$(window).resize(function() {
		updateLayout();
	});

    var offset = $(".entry").last().offset().left;
	var width = 320 + 15;
	width = "" + (offset + width) + "px";
	$(".page").css("width", width);

	$("body").scrollLeft(10000);

    var start_index = 0;
    $(".entry").sortable({
        start: function(e, ui) {
            start_index = ui.item.index() - 1;
        },
        stop: function (e, ui) {
            $(this).trigger("reordered", [start_index, ui.item.index() - 1]);
            updateLayout();
        },
    });
    $(".entry").disableSelection();
};

