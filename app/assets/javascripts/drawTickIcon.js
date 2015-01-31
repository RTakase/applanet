
$.fn.extend({
    drawTickIcon: function() {

        //似ているを示すアイコンから順番に追加してね！
        var ticks = [
            "fa-smile-o",
            "fa-smile-o",
            "fa-meh-o",
            "fa-frown-o",
            "fa-frown-o"
        ];

        var xIcons = [];
        var yIcons = [];

         $(".xaxis").empty();
        $(".yaxis").empty();
        
        for (i = 0; i < ticks.length; i++) {
            var itag = $("<i>");
            itag.addClass("fa fa-2x text-success");
            itag.addClass(ticks[i]);
            $(".xaxis").append(itag);
            xIcons[i] = itag;

            var alpha = 1. - (i / ticks.length);
            var rgb = $(xIcons[i]).css("color");
            var rgba = rgb.replace("rgb", "rgba");
            rgba = rgba.replace(")", ","+alpha+")");
            //xIcons[i]内のcolor要素("rgb(r,g,b)")に透過の指定を追加            
            $(xIcons[i]).css("color", rgba);

            itag = itag.clone();
            itag.addClass("pull-right");
            $(".yaxis").prepend(itag);
            yIcons[i] = $(itag);
        }

        var iconWidth = 0;
        var iconHeight = 0;
        for (i = 0; i < ticks.length; i++) {
            iconWidth += $(xIcons[i]).width();
            iconHeight += $(yIcons[i]).height();
        }

        //アイコンをちょうどよく並べるための幅
        var xInterval =
            ($(".xaxis").width() - iconWidth) / (2*(ticks.length-1));
        var yInterval = 
            ($("#chart").height() - iconHeight) / (2*(ticks.length-1));
        
        var offset = 1;

        for (i = 0; i < ticks.length; i++) {
            var xPadding = {};
            var yPadding = {};
            if (i == 0) {
                xPadding["padding-right"] = xInterval - offset;
                yPadding["padding-top"] = yInterval - offset;
            }
            else if (i == ticks.length-1) {
                xPadding["padding-left"] = xInterval - offset;
                yPadding["padding-bottom"] = yInterval - offset;
            }
            else {
                xPadding["padding-right"] = xInterval - offset;
                xPadding["padding-left"] = xInterval - offset;
                yPadding["padding-bottom"] = yInterval - offset;
                yPadding["padding-top"] = yInterval - offset;
            }
            $(xIcons[i]).css(xPadding);
            $(yIcons[i]).css(yPadding);
        }
        return this;
    }
});
