$(function(){
	window.onload = (e) => {
        /* 'links' the js with the Nui message from main.lua */
        $("#container").hide();
        $("#error-notif").hide();
		window.addEventListener('message', (event) => {
			var item = event.data;
			if (item !== undefined && item.type === "ui") {
				if (item.display === true) {
                    $("#container").show();
				} else{
                    $("#container").hide();
                }
			}
		});
	};
});

$(document).on('click', '#submit-btn', function(e){
    e.preventDefault();
    var data;
    $("#object").val(function(i, text) {
        data = text;
        return "";
    });
    $.post('https://FiveMapEditor/MapEdit:GetInput', JSON.stringify({
        text: data
    }), function(success) {
        if (success) {
            $("#error-notif").hide();
            $("#container").hide();
        } else {
            $("#error-notif").show();
        }
    });
});

$(document).on('click', '#close-btn', function(e){
    e.preventDefault();
    $("#container").hide();
    $.post('https://FiveMapEditor/MapEdit:CloseUI');
});